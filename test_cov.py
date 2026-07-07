import re, sys

EXEMPT = [
    r'\.g\.dart$', r'\.config\.dart$', r'/semantic_colors\.dart$',
    r'/main\.dart$', r'/bootstrap\.dart$', r'/app/app\.dart$',
    r'/core/services/', r'/core/router/', r'/core/observers/',
    r'/core/data/datasources/', r'/data/ai/gemma_zb_service\.dart$',
    r'/lib/widgets/', r'/features/onboarding/', r'/lib/theme/',
    r'/presentation/widgets/', r'/presentation/pages/',
]
patterns = [re.compile(p) for p in EXEMPT]

with open('coverage/lcov.info') as f:
    lines = f.read().split('\n')

file = None
uncovered = 0
for line in lines:
    if line.startswith('SF:'):
        file = line[3:]
        uncovered = 0
    elif line.startswith('DA:'):
        parts = line[3:].split(',')
        if len(parts) >= 2 and parts[1] == '0':
            uncovered += 1
    elif line == 'end_of_record':
        if file and uncovered > 0:
            if not any(p.search(file) for p in patterns):
                print(f"{uncovered} {file}")

