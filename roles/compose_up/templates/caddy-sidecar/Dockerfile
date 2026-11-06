FROM caddy:builder@sha256:3db11aead97f1fdff9c563d0dd8e7fba2e4c7031bef40f3e44fd1982f3e8366b AS builder

RUN xcaddy build --with github.com/caddy-dns/ovh

FROM caddy:latest@sha256:ce773ec7a742ce15ee6bf2bb5f65882b9e2a4487b10733e6f1484f86e6b5d8bc

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
