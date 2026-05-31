set shell := ["bash", "-cu"]

coverage_floor := "65"

default:
    @just --list

setup:
    flutter pub get
    just gen

gen:
    dart run build_runner build

watch:
    dart run build_runner watch

format:
    dart format lib test

analyze:
    flutter analyze

test *args:
    flutter test {{args}}

coverage:
    flutter test --coverage
    just _check-coverage

coverage-html: coverage
    genhtml coverage/lcov.info -o coverage/html
    @echo "Report: coverage/html/index.html"

_check-coverage:
    #!/usr/bin/env bash
    set -euo pipefail
    file=coverage/lcov.info
    hit=$(grep -c '^DA:[0-9]*,[1-9]' "$file" || true)
    found=$(grep -c '^DA:' "$file" || true)
    if [ "$found" -eq 0 ]; then echo "No coverage data"; exit 1; fi
    pct=$(( hit * 100 / found ))
    echo "Coverage: ${pct}% (${hit}/${found} lines)"
    if [ "$pct" -lt {{coverage_floor}} ]; then
      echo "Below floor of {{coverage_floor}}%"
      exit 1
    fi

precommit: format analyze coverage
    @echo "precommit passed"

clean:
    flutter clean
    flutter pub get
