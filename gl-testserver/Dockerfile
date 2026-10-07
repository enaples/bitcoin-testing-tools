# syntax=docker/dockerfile:1
# Greenlight test server (scheduler + Greenlight nodes) for the signet stack.
#
# The greenlight sources are fetched from GREENLIGHT_REPO at GREENLIGHT_REF.
# amd64 only: the Core Lightning builds gl-testing downloads are x86-64
# Linux binaries.

ARG GREENLIGHT_REPO=https://github.com/enaples/greenlight.git
ARG GREENLIGHT_REF=working-with-signet
ARG PROTOC_VERSION=3.19.3
ARG CFSSL_VERSION=1.6.5
ARG BITCOIN_VERSION=28.2

FROM ghcr.io/astral-sh/uv:latest AS uv

############################
# Builder: gl-plugin, gl-signerproxy and the gltestserver Python env
############################
FROM rust:slim-bookworm AS builder
ARG GREENLIGHT_REPO
ARG GREENLIGHT_REF
ARG PROTOC_VERSION
ARG CFSSL_VERSION
ARG BITCOIN_VERSION

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git unzip && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sSfL -o /tmp/protoc.zip \
      https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip -q /tmp/protoc.zip -d /usr/local && rm /tmp/protoc.zip && \
    curl -sSfL -o /usr/local/bin/cfssl \
      https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/cfssl_${CFSSL_VERSION}_linux_amd64 && \
    curl -sSfL -o /usr/local/bin/cfssljson \
      https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/cfssljson_${CFSSL_VERSION}_linux_amd64 && \
    chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson

# lightningd's bcli backend shells out to bitcoin-cli, even for a remote bitcoind.
RUN curl -sSfL https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz \
      | tar -xz -C /tmp && \
    mv /tmp/bitcoin-${BITCOIN_VERSION}/bin/bitcoin-cli /usr/local/bin/ && \
    rm -rf /tmp/bitcoin-${BITCOIN_VERSION}

COPY --from=uv /uv /usr/local/bin/uv

# Re-checked on every build, so new commits on the branch are picked up.
ADD ${GREENLIGHT_REPO}#${GREENLIGHT_REF} /repo
WORKDIR /repo

# gltesting looks for the binaries in $CARGO_TARGET_DIR/$RUST_PROFILE.
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/repo/target \
    cargo build --release -p gl-plugin -p gl-signerproxy && \
    mkdir -p /opt/gl/release && \
    cp target/release/gl-plugin target/release/gl-signerproxy /opt/gl/release/

# Python and the venv live under /opt so the final stage can copy them as is.
ENV UV_PYTHON_INSTALL_DIR=/opt/uv-python \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/repo/target \
    uv sync --python 3.10 --package gltestserver --no-dev --no-editable

############################
# Runtime
############################
FROM ubuntu:24.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates gnupg libpq5 libsodium23 openssl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/cfssl /usr/local/bin/cfssljson /usr/local/bin/bitcoin-cli /usr/local/bin/
COPY --from=builder /opt/gl /opt/gl
COPY --from=builder /opt/uv-python /opt/uv-python
COPY --from=builder /opt/venv /opt/venv

ENV PATH=/opt/venv/bin:$PATH \
    CARGO_TARGET_DIR=/opt/gl \
    RUST_PROFILE=release \
    CLNVM_CACHE_DIR=/opt/clnvm

# The scheduler keeps its nodes in memory, so every start is a fresh server:
# drop the previous certificates instead of handing out stale ones.
# Settings come from the environment (see the compose service):
#   GL_TESTSERVER_BITCOIND_RPC, GL_TESTING_ADVERTISE_HOST,
#   GL_TESTING_BIND_HOST, GL_TESTING_SCHEDULER_PORT
ENTRYPOINT ["sh", "-c", "rm -rf /data/gl-testserver /data/client.env && exec gltestserver run --directory /data \"$@\"", "--"]

HEALTHCHECK --interval=10s --timeout=5s --start-period=30m \
  CMD test -f /data/client.env
