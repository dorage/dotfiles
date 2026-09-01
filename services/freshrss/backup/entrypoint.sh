#!/bin/sh
# Dispatch for the backup sidecar.
#
#   loop      (default) take a snapshot every BACKUP_INTERVAL_SECONDS
#   backup    one-off snapshot + upload
#   snapshot  one-off snapshot written to a local path (--output), no R2 needed
#   restore   pull a snapshot from R2 back into the volumes
#   list      list snapshots stored in R2
#   verify    download the newest snapshot and integrity-check it
#   sh        interactive shell
set -eu

LIB=/usr/local/lib/freshrss-backup
. "$LIB/common.sh"

cmd=${1:-loop}
[ $# -gt 0 ] && shift

case "$cmd" in
backup)
	exec "$LIB/backup.sh" "$@"
	;;
snapshot)
	case " $* " in
	*" --output "* | *" -o "*) ;;
	*) set -- --output /out/ "$@" ;;
	esac
	exec "$LIB/backup.sh" "$@"
	;;
restore)
	exec "$LIB/restore.sh" "$@"
	;;
list)
	require_rclone || exit 1
	rclone lsl "$REMOTE_DIR" --include "$ARCHIVE_GLOB" --max-depth 1
	;;
verify)
	require_rclone || exit 1
	object=$(latest_snapshot)
	[ -n "$object" ] || die "no snapshot under $REMOTE_DIR"
	work=$(mktemp -d /tmp/freshrss-verify.XXXXXX)
	trap 'rm -rf "$work"' EXIT INT TERM
	log INFO "verifying $object"
	rclone copyto "$REMOTE_DIR/$object" "$work/s.tar.gz" --stats-one-line --stats=0
	tar -C "$work" -xzpf "$work/s.tar.gz"
	[ -f "$work/MANIFEST" ] && sed 's/^/  /' "$work/MANIFEST" >&2
	# List first: a `die` inside a `find | while` subshell could not fail this
	# command, and a silently-passing verify is worse than no verify.
	find "$work/data" -type f -name '*.sqlite' >"$work/.dblist"
	while IFS= read -r db; do
		[ -n "$db" ] || continue
		check=$(sqlite3 "$db" 'PRAGMA integrity_check;' | head -n 1)
		[ "$check" = "ok" ] || die "corrupt: ${db#"$work"/} ($check)"
		log INFO "ok: ${db#"$work"/}"
	done <"$work/.dblist"
	log INFO "$object verified"
	;;
sh | shell)
	exec /bin/sh "$@"
	;;
loop)
	interval=${BACKUP_INTERVAL_SECONDS:-3600}
	log INFO "scheduler started; interval=${interval}s (each cycle logs its destination)"

	if [ "${BACKUP_ON_START:-true}" = "true" ]; then
		"$LIB/backup.sh" || log WARN "initial backup failed; will retry on schedule"
	fi

	while :; do
		# Align wake-ups to interval boundaries (top of the hour by default).
		now=$(date +%s)
		nap=$((interval - now % interval))
		log INFO "next snapshot in ${nap}s"
		sleep "$nap"

		if ! "$LIB/backup.sh"; then
			log WARN "backup failed; retrying at the next interval"
		fi
	done
	;;
*)
	die "unknown command: $cmd (try: loop backup restore list verify sh)"
	;;
esac
