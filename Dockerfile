# Test image only: installs bats-core for docs/testing-requirements.md container-isolated suites.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends bats bash ca-certificates coreutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
