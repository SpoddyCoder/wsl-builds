# Test image: Ubuntu + bats-core; Bats sources live in this directory.
# Build from repo root: docker build -f test/docker/Dockerfile -t wsl-builds-test .
# Ignore rules: Dockerfile.dockerignore (BuildKit pairs with -f path).
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends bats bash ca-certificates coreutils python3 wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
COPY . /repo

CMD ["bash", "./test/docker/run-bats.sh"]
