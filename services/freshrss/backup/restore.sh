#!/bin/sh
# Restore FreshRSS volumes from an R2 snapshot.
#
#   docker compose stop freshrss
#   docker compose run --rm backup restore              # newest snapshot
#   docker compose run --rm backup restore --object freshrss-20260901T120000Z.tar.gz
#   docker compose start freshrss
#
# Stop FreshRSS first: this replaces the contents of both volumes.
set -eu

. /usr/local/lib/freshrss-backup/common.sh

FORCE=0
OBJECT=""
while [ $# -gt 0 ]; do
	case "$1" in
	--force | -f) FORCE=1 ;;
	--object | -o)
		shift
		OBJECT=${1:?--object needs a snapshot name}
		;;
	--help | -h)
		# The header comment block, minus the shebang, is the usage text.
		awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"
		exit 0
		;;
	*) die "unknown argument: $1" ;;
	esac
	shift
done

require_rclone || exit 1

if [ -z "$OBJECT" ]; then
	OBJECT=$(latest_snapshot)
	[ -n "$OBJECT" ] || die "no snapshot matching $ARCHIVE_GLOB under $REMOTE_DIR"
	log INFO "newest snapshot: $OBJECT"
fi

# Refuse to clobber a populated volume unless explicitly told to.
if [ "$FORCE" -eq 0 ] && [ -n "$(find "$DATA_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
	log ERROR "$DATA_DIR is not empty. Restoring would replace the live data."
	die "re-run with --force once FreshRSS is stopped and you are sure."
fi

WORK=$(mktemp -d /tmp/freshrss-restore.XXXXXX)
ARCHIVE="$WORK/snapshot.tar.gz"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT INT TERM

log INFO "downloading $REMOTE_DIR/$OBJECT"
rclone copyto "$REMOTE_DIR/$OBJECT" "$ARCHIVE" --stats-one-line --stats=0

mkdir -p "$WORK/unpacked"
tar -C "$WORK/unpacked" -xzpf "$ARCHIVE"
[ -d "$WORK/unpacked/data" ] || die "archive has no data/ directory - wrong object?"

if [ -f "$WORK/unpacked/MANIFEST" ]; then
	log INFO "manifest:"
	sed 's/^/  /' "$WORK/unpacked/MANIFEST" >&2
fi

# Validate every database before touching the live volumes.
find "$WORK/unpacked/data" -type f -name '*.sqlite' >"$WORK/.dblist"
while IFS= read -r db; do
	[ -n "$db" ] || continue
	check=$(sqlite3 "$db" 'PRAGMA integrity_check;' | head -n 1)
	[ "$check" = "ok" ] || die "corrupt database in archive: ${db#"$WORK"/unpacked/} ($check)"
	log INFO "verified ${db#"$WORK"/unpacked/}"
done <"$WORK/.dblist"

replace_dir() {
	src=$1
	dst=$2
	[ -d "$src" ] || return 0
	mkdir -p "$dst"
	log INFO "replacing $dst"
	find "$dst" -mindepth 1 -delete
	tar -C "$src" -cf - . | tar -C "$dst" -xpf -
}

replace_dir "$WORK/unpacked/data" "$DATA_DIR"
replace_dir "$WORK/unpacked/extensions" "$EXT_DIR"

log INFO "restore complete from $OBJECT - start FreshRSS again"
