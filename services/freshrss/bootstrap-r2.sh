#!/usr/bin/env bash
# One-time Cloudflare R2 setup, run on the host from services/freshrss/.
#
#   wrangler login          # or export CLOUDFLARE_API_TOKEN=...
#   ./bootstrap-r2.sh
#
# It creates the bucket and pushes the first snapshot through wrangler, so no
# S3 API token is needed yet. The hourly sidecar does need one (rclone speaks
# the S3 API, wrangler does not) - see the end of this script's output.
set -euo pipefail

cd "$(dirname "$0")"

WRANGLER=${WRANGLER:-npx --yes wrangler@latest}

if [[ -f .env ]]; then
	set -a
	# shellcheck disable=SC1091
	. ./.env
	set +a
fi
BUCKET=${R2_BUCKET:-freshrss-backup}
PREFIX=${R2_PREFIX:-freshrss}
LOCATION=${R2_LOCATION_HINT:-apac}

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

say "Checking Cloudflare authentication"
# `wrangler whoami` exits 0 either way, so match on its message. Note that
# "preview account" appears in the *unauthenticated* output - grepping for
# "account" is not a usable signal.
whoami_out=$($WRANGLER whoami 2>&1 || true)
if grep -qiE 'not authenticated|CLOUDFLARE_API_TOKEN' <<<"$whoami_out"; then
	printf '%s\n' "$whoami_out" >&2
	cat >&2 <<-'EOF'

		Not authenticated. Do one of:
		  npx wrangler login                    # interactive browser OAuth (needs a TTY)
		  export CLOUDFLARE_API_TOKEN=<token>   # headless; needs "Workers R2 Storage: Edit"
		then re-run this script.
	EOF
	exit 1
fi
printf '%s\n' "$whoami_out"

say "Creating R2 bucket: $BUCKET (location hint: $LOCATION)"
if out=$($WRANGLER r2 bucket create "$BUCKET" --location "$LOCATION" 2>&1); then
	printf '%s\n' "$out"
elif grep -qiE 'already (exists|owned)|10004' <<<"$out"; then
	echo "bucket already exists - continuing"
else
	printf '%s\n' "$out" >&2
	exit 1
fi

say "Building the backup image and taking the first snapshot"
mkdir -p ./tmp
docker compose build backup
docker compose run --rm -v "$PWD/tmp:/out" backup snapshot >/dev/null

ARCHIVE=$(ls -1t ./tmp/freshrss-*.tar.gz 2>/dev/null | head -n 1)
[[ -n $ARCHIVE ]] || {
	echo "snapshot produced no archive in ./tmp" >&2
	exit 1
}
KEY="$PREFIX/$(basename "$ARCHIVE")"

say "Uploading $ARCHIVE -> r2://$BUCKET/$KEY"
$WRANGLER r2 object put "$BUCKET/$KEY" --file "$ARCHIVE" \
	--content-type application/gzip --remote

say "Reading the object back"
$WRANGLER r2 object get "$BUCKET/$KEY" --remote --file ./tmp/roundtrip.bin >/dev/null
if cmp -s "$ARCHIVE" ./tmp/roundtrip.bin; then
	echo "round-trip ok: r2://$BUCKET/$KEY"
else
	echo "round-trip MISMATCH for r2://$BUCKET/$KEY" >&2
	exit 1
fi

rm -f ./tmp/roundtrip.bin "$ARCHIVE"
rmdir ./tmp 2>/dev/null || true

cat <<EOF

$(say "Done - one manual step left")
The hourly sidecar uses rclone over R2's S3 API, which wrangler cannot mint
credentials for. Create them once:

  Cloudflare dashboard -> R2 -> API -> "Manage API tokens"
    - Permission: Object Read & Write
    - Scope: only the bucket "$BUCKET"

Put the three values into services/freshrss/.env (gitignored):

  R2_ACCOUNT_ID=...          # R2 Overview page, or \`wrangler whoami\`
  R2_ACCESS_KEY_ID=...
  R2_SECRET_ACCESS_KEY=...

Then start the scheduler and confirm it can talk to R2:

  docker compose up -d
  docker compose run --rm backup list
  docker compose logs -f backup
EOF
