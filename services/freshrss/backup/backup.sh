#!/bin/sh
# Snapshot the FreshRSS data + extensions volumes into one tar.gz and upload it
# to Cloudflare R2. Safe to run while FreshRSS is serving traffic: SQLite
# databases are copied through sqlite3's online backup API rather than tar'd
# underneath the running process.
#
#   backup.sh                      snapshot and upload to R2
#   backup.sh --output /out/x.tgz  snapshot to a local file only (no R2 needed)
set -eu

. /usr/local/lib/freshrss-backup/common.sh

OUTPUT=""
while [ $# -gt 0 ]; do
	case "$1" in
	--output | -o)
		shift
		OUTPUT=${1:?--output needs a path}
		;;
	*) die "unknown argument: $1" ;;
	esac
	shift
done

[ -n "$OUTPUT" ] || require_rclone || exit 1

[ -d "$DATA_DIR" ] || die "data volume not mounted at $DATA_DIR"

STAMP=$(date -u '+%Y%m%dT%H%M%SZ')
ARCHIVE_NAME="freshrss-${STAMP}.tar.gz"
STAGING=$(mktemp -d /tmp/freshrss-backup.XXXXXX)
ARCHIVE="${STAGING}.tar.gz"

cleanup() {
	rm -rf "$STAGING" "$ARCHIVE"
}
trap cleanup EXIT INT TERM

log INFO "staging snapshot $ARCHIVE_NAME"
mkdir -p "$STAGING/data" "$STAGING/extensions"

# 1. Everything except SQLite files, ownership and modes preserved.
tar -C "$DATA_DIR" -cf - \
	--exclude='*.sqlite' \
	--exclude='*.sqlite-wal' \
	--exclude='*.sqlite-shm' \
	--exclude='*.sqlite-journal' \
	. | tar -C "$STAGING/data" -xpf -

if [ -d "$EXT_DIR" ]; then
	tar -C "$EXT_DIR" -cf - . | tar -C "$STAGING/extensions" -xpf -
fi

# 2. Consistent copy of each SQLite database.
find "$DATA_DIR" -type f -name '*.sqlite' >"$STAGING/.dblist"
db_count=0
while IFS= read -r db; do
	[ -n "$db" ] || continue
	rel=${db#"$DATA_DIR"/}
	dest="$STAGING/data/$rel"
	mkdir -p "$(dirname "$dest")"
	log INFO "sqlite online backup: $rel"
	sqlite3 "$db" ".timeout 30000" ".backup '$dest'"

	check=$(sqlite3 "$dest" 'PRAGMA integrity_check;' | head -n 1)
	[ "$check" = "ok" ] || die "integrity check failed for $rel: $check"

	# sqlite3 runs as root here; put the file back on FreshRSS's uid/gid.
	chown --reference="$db" "$dest"
	chmod --reference="$db" "$dest"
	db_count=$((db_count + 1))
done <"$STAGING/.dblist"
rm -f "$STAGING/.dblist"
log INFO "captured $db_count sqlite database(s)"

# 3. Manifest, so a restored archive can be identified without unpacking it all.
cat >"$STAGING/MANIFEST" <<EOF
created_utc=$STAMP
host=$(hostname)
sqlite_databases=$db_count
data_bytes=$(du -sb "$STAGING/data" | cut -f1)
extensions_bytes=$(du -sb "$STAGING/extensions" | cut -f1)
tool=services/freshrss/backup/backup.sh
EOF

# 4. Archive and upload.
tar -C "$STAGING" -czpf "$ARCHIVE" MANIFEST data extensions
size=$(du -h "$ARCHIVE" | cut -f1)

if [ -n "$OUTPUT" ]; then
	# Local-only mode: used by bootstrap-r2.sh for the very first upload, which
	# goes through wrangler and therefore needs no S3 credentials yet.
	case "$OUTPUT" in
	*/) OUTPUT="${OUTPUT}${ARCHIVE_NAME}" ;;
	esac
	mkdir -p "$(dirname "$OUTPUT")"
	cp "$ARCHIVE" "$OUTPUT"
	log INFO "wrote $OUTPUT ($size)"
	printf '%s\n' "$OUTPUT"
	exit 0
fi

log INFO "uploading $ARCHIVE_NAME ($size) to $REMOTE_DIR"
rclone copyto "$ARCHIVE" "$REMOTE_DIR/$ARCHIVE_NAME" --stats-one-line --stats=0
log INFO "upload complete: $REMOTE_DIR/$ARCHIVE_NAME"

# 5. Retention. Runs only after a successful upload, so a failing backup never
#    erodes the history it was supposed to extend.
retention=${BACKUP_RETENTION_DAYS:-30}
if [ "$retention" -gt 0 ] 2>/dev/null; then
	log INFO "pruning snapshots older than ${retention}d"
	rclone delete "$REMOTE_DIR" \
		--include "$ARCHIVE_GLOB" --max-depth 1 \
		--min-age "${retention}d" --stats-one-line --stats=0
fi

log INFO "done"
