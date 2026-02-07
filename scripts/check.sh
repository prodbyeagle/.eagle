#!/usr/bin/env sh
set -eu

echo '== fmt (check) =='
cargo fmt -- --check

echo '== clippy =='
cargo clippy -- -D warnings

echo '== test =='
cargo test

echo '== doc =='
cargo doc --no-deps

