FROM alpine:3.10 as compiler
# https://github.com/meilisearch/MeiliSearch/archive/v0.19.0.tar.gz
ARG meili_version=v0.19.0
RUN set -ex; \
    \
    apk update --quiet; \
    apk add --no-cache \
        wget \
        curl \
        build-base \
    ;
RUN     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

WORKDIR /meilisearch

RUN    wget -O meilisearch.tar.gz \
    https://github.com/meilisearch/MeiliSearch/archive/${meili_version}.tar.gz \
    ;\
    tar -xzvf meilisearch.tar.gz --strip 1 \
    ;

ENV     RUSTFLAGS="-C target-feature=-crt-static"

RUN     $HOME/.cargo/bin/cargo build --release

# Run
FROM    alpine:3.10

RUN     apk add -q --no-cache libgcc tini bash

COPY    --from=compiler /meilisearch/target/release/meilisearch .

RUN     mkdir -p /data

VOLUME  /data

ENV     MEILI_NO_ANALYTICS=1
ENV     MEILI_NO_SENTRY=1
ENV     MEILI_ENV=development
ENV     MEILI_MASTER_KEY=masterKey
ENV     MEILI_HTTP_ADDR=0.0.0.0:7700
ENV     MEILI_DB_PATH=/data/data.ms

EXPOSE 7700/tcp

ENTRYPOINT ["tini", "--"]
CMD     ./meilisearch
