# Tests

Uses [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

## Install bats

```bash
# macOS
brew install bats-core

# Linux
npm install -g bats
# or
git clone https://github.com/bats-core/bats-core.git && cd bats-core && ./install.sh /usr/local
```

## Run all tests

```bash
bats test/
```

## Run a single test file

```bash
bats test/test_bootstrap.bats
bats test/test_install.bats
```

## Run with verbose output

```bash
bats --verbose-run test/
```

## Test files

| File | What it covers |
|---|---|
| `test_bootstrap.bats` | All bootstrap.sh modes: dry-run, install, verify, gitignore, scaffold integrity |
| `test_install.bats` | install.sh: fresh install, update, idempotency, stale alias, missing bootstrap |
