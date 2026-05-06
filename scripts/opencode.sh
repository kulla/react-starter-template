#!/bin/sh

ROOT_DIR=$(dirname $(dirname $(readlink -f $0)))

nono run --workdir "$ROOT_DIR" \
  --profile my-opencode \
  --read "$ROOT_DIR" \
  --write "$ROOT_DIR/src" \
  --write "$ROOT_DIR/playwright" \
  --write-file "$ROOT_DIR/README.md" \
  --write-file "$ROOT_DIR/AGENTS.md" \
  -- opencode
