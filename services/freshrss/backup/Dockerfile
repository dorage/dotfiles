# Small sidecar that snapshots the FreshRSS volumes and ships them to R2.
# alpine + rclone (S3 API) + sqlite (consistent online DB snapshot).
FROM alpine:3.22

RUN apk add --no-cache \
        rclone \
        sqlite \
        tar \
        coreutils \
        tzdata \
        ca-certificates

COPY common.sh backup.sh restore.sh entrypoint.sh /usr/local/lib/freshrss-backup/
RUN chmod +x /usr/local/lib/freshrss-backup/*.sh

ENTRYPOINT ["/usr/local/lib/freshrss-backup/entrypoint.sh"]
CMD ["loop"]
