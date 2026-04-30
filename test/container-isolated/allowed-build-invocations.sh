#!/usr/bin/env bash
# Allowed early-exit-only ./build.sh argv patterns — keep synchronized with the early-exit @tests in
# test/container-isolated/build_test_fixture_harness.bats.
# Each case must exit before "${BUILD_DIR}/install.sh" is sourced (see ../../docs/testing-requirements.md).
#
# Implemented cases:
#   ./build.sh
#   ./build.sh __EARLY_EXIT_UNKNOWN_BUILD_DIR__
#   ./build.sh test-fixture
#
# Invalid $2 on a NUM_ADDITIONAL_ARGS=0 build lives in harness as "invalid component for test-fixture fails".
#
# Do not extend this file / those tests with argv that invokes install dispatch
# (valid components plus additional cases belong in harness tests elsewhere in this dir).
#
# shellcheck shell=bash
:
