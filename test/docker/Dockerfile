# Test image: Ubuntu + bats-core; Bats sources live in this directory.
# Build from repo root: docker build -f test/docker/Dockerfile -t wsl-builds-test .
# Ignore rules: Dockerfile.dockerignore (BuildKit pairs with -f path).
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
# Canonical mirrors can be slow from some networks; use Uni of Kent mirrorservice before any apt use.
RUN sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu/|http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/|g' \
    -e 's|https://archive.ubuntu.com/ubuntu/|http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/|g' \
    -e 's|http://security.ubuntu.com/ubuntu/|http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/|g' \
    -e 's|https://security.ubuntu.com/ubuntu/|http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/|g' \
    /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update \
    && apt-get install -y --no-install-recommends bats bash ca-certificates coreutils curl jq python3 sudo wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
COPY . /repo

CMD ["bash", "./test/docker/run-bats.sh"]
