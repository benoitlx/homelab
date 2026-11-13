FROM caddy:builder@sha256:6350162b3889ca32600b3c699c61572fa0eb3ad6b2a51874f19b158a7df77511 AS builder

RUN xcaddy build --with github.com/caddy-dns/ovh

FROM caddy:latest@sha256:4e2425f6009577e7c651010f16679c28f7d12df3e7b1914f941a7a3370746b3c

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
