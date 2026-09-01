#!/bin/sh
# Shared helpers for the FreshRSS backup sidecar. Sourced, not executed.

DATA_DIR=${DATA_DIR:-/volumes/data}
EXT_DIR=${EXT_DIR:-/volumes/extensions}
R2_BUCKET=${R2_BUCKET:-freshrss-backup}
R2_PREFIX=${R2_PREFIX:-freshrss}
ARCHIVE_GLOB='freshrss-*.tar.gz'

# No rclone.conf on disk - everything comes from the environment. Pointing at
# /dev/null also silences rclone's "config file not found" notice.
RCLONE_CONFIG=${RCLONE_CONFIG:-/dev/null}
export RCLONE_CONFIG

log() {
	printf '%s %-5s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$1" "$2" >&2
}

die() {
	log ERROR "$1"
	exit 1
}

# rclone is configured entirely from the environment so nothing is ever written
# to disk. The remote is addressed as `r2:`.
#
# Setting REMOTE_DIR yourself bypasses R2 entirely and points the same commands
# at any rclone target, including a plain directory - handy for restoring from a
# USB drive or a snapshot you copied by hand:
#   docker compose run --rm -v /mnt/usb:/out -e REMOTE_DIR=/out backup restore
configure_rclone() {
	if [ -n "${REMOTE_DIR:-}" ]; then
		export REMOTE_DIR
		return 0
	fi

	[ -n "${R2_ACCOUNT_ID:-}" ] || return 1
	[ -n "${R2_ACCESS_KEY_ID:-}" ] || return 1
	[ -n "${R2_SECRET_ACCESS_KEY:-}" ] || return 1

	RCLONE_CONFIG_R2_TYPE=s3
	RCLONE_CONFIG_R2_PROVIDER=Cloudflare
	RCLONE_CONFIG_R2_REGION=auto
	RCLONE_CONFIG_R2_ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
	RCLONE_CONFIG_R2_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID
	RCLONE_CONFIG_R2_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY
	RCLONE_CONFIG_R2_ACL=private
	# A bucket-scoped token cannot HeadBucket/CreateBucket; skip those probes.
	RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true
	export RCLONE_CONFIG_R2_TYPE RCLONE_CONFIG_R2_PROVIDER \
		RCLONE_CONFIG_R2_REGION RCLONE_CONFIG_R2_ENDPOINT \
		RCLONE_CONFIG_R2_ACCESS_KEY_ID RCLONE_CONFIG_R2_SECRET_ACCESS_KEY \
		RCLONE_CONFIG_R2_ACL RCLONE_CONFIG_R2_NO_CHECK_BUCKET

	REMOTE_DIR="r2:${R2_BUCKET}/${R2_PREFIX}"
	export REMOTE_DIR
}

require_rclone() {
	if ! configure_rclone; then
		log ERROR "R2 credentials are missing. Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID"
		log ERROR "and R2_SECRET_ACCESS_KEY in services/freshrss/.env (see .env.example)."
		return 1
	fi
}

# Newest snapshot key in R2, or empty when the prefix holds none.
latest_snapshot() {
	rclone lsf "$REMOTE_DIR" \
		--files-only --max-depth 1 --include "$ARCHIVE_GLOB" 2>/dev/null |
		sort | tail -n 1
}
