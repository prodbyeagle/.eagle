$ErrorActionPreference = 'Stop'

Write-Host '== fmt (check) =='
cargo fmt -- --check

Write-Host '== clippy =='
cargo clippy -- -D warnings

Write-Host '== test =='
cargo test

Write-Host '== doc =='
cargo doc --no-deps

