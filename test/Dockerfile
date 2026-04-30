# Test image: copies repo into the image and installs bats-core for test/container-isolated suites.
# Build from repo root: docker build -f test/Dockerfile -t wsl-builds-test .
# Ignore rules: Dockerfile.dockerignore (BuildKit pairs with -f path).
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends bats bash ca-certificates coreutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
COPY . /repo

CMD ["bash", "./test/container-isolated/run-bats-in-container.sh"]
