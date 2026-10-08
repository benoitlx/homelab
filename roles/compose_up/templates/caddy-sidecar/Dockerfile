FROM caddy:builder@sha256:b25f47453fa02f7e66c0828b4b1343658808b9000950b6825c4a1cb0c988f5f8 AS builder

RUN xcaddy build --with github.com/caddy-dns/ovh

FROM caddy:latest@sha256:f2a1290d0463aad60660d4ec134943f183ee2a5f6c3eb7bf32dd984f2f020772

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
