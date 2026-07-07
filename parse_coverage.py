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

files = {}
path = None

for ln in open('coverage/lcov.info'):
    if ln.startswith('SF:'):
        path = ln[3:].strip()
        if not exempt(path):
            files[path] = {'found': 0, 'hit': 0}
    elif ln.startswith('DA:') and path and not exempt(path):
        files[path]['found'] += 1
        if not ln.strip().endswith(',0'):
            files[path]['hit'] += 1

results = []
for p, stats in files.items():
    if stats['found'] > 0:
        results.append({
            'path': p,
            'uncovered': stats['found'] - stats['hit'],
            'total': stats['found'],
            'pct': stats['hit'] / stats['found'] * 100
        })

results.sort(key=lambda x: x['uncovered'], reverse=True)

print("Top files by UNCOVERED lines (non-exempt):")
for r in results[:15]:
    print(f"{r['uncovered']:>4} missing / {r['total']:>4} total ({r['pct']:>5.1f}%) : {r['path']}")
