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

run-dev:
    APP_ID_SUFFIX=.dev flutter run

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

# Coverage floor measures testable logic only. Generated code, platform/device
# glue, entrypoints, and design-system primitives are exempt (see rules.md).
_check-coverage:
    #!/usr/bin/env python3
    import re, sys
    EXEMPT = [
        r'\.g\.dart$', r'\.config\.dart$', r'/semantic_colors\.dart$',
        r'/main\.dart$', r'/bootstrap\.dart$', r'/app/app\.dart$',
        r'/core/services/', r'/core/router/', r'/core/observers/',
        r'/core/data/datasources/', r'/data/ai/gemma_zb_service\.dart$',
        r'/lib/widgets/', r'/features/onboarding/', r'/lib/theme/',
        r'/presentation/widgets/', r'/presentation/pages/',
    ]
    exempt = lambda p: any(re.search(x, p) for x in EXEMPT)
    found = hit = 0
    path = None
    for ln in open('coverage/lcov.info'):
        if ln.startswith('SF:'):
            path = ln[3:].strip()
        elif ln.startswith('DA:') and path and not exempt(path):
            found += 1
            if not ln.strip().endswith(',0'):
                hit += 1
    if found == 0:
        print('No coverage data'); sys.exit(1)
    pct = hit * 100 // found
    print(f'Coverage: {pct}% ({hit}/{found} lines, glue excluded)')
    if pct < {{coverage_floor}}:
        print('Below floor of {{coverage_floor}}%'); sys.exit(1)

precommit: format analyze coverage
    @echo "precommit passed"

build-apk:
    flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols --split-per-abi --release

clean:
    flutter clean
    flutter pub get
