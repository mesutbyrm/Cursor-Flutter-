#!/usr/bin/env python3
"""Flutter'ın çağırdığı /api yollarını canlifal backend route dosyalarıyla karşılaştırır.

Kullanım:
  python3 scripts/backend-route-parity.py <canlifal-repo>/nextjs_space [--used-only]

Backend tarafı `app/api/**/route.ts`; `/api/v1/*` → `/api/*` (middleware rewrite).
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Bilinen yanlış alarmlar: yol dönüştürücü / önbellek önek kuralı (istek değil) ve
# slug'ı `_apiSlugFor` ile gerçek /api/fortunes/<tür> uçlarına eşlenen yardımcı.
IGNORED_SOURCES = {
    'core/network/api_path_v1.dart',
    'core/network/api_cache_policy.dart',
}
IGNORED_CONSTANTS = {'fortuneReading'}
LIB = os.path.join(ROOT, 'mobile', 'lib')
ENDPOINTS = os.path.join(LIB, 'core', 'network', 'api_endpoints.dart')


def backend_routes(nextjs_dir):
    api = os.path.join(nextjs_dir, 'app', 'api')
    routes = []
    for dp, _, fs in os.walk(api):
        if 'route.ts' in fs:
            rel = os.path.relpath(dp, os.path.join(nextjs_dir, 'app'))
            routes.append('/' + rel.replace(os.sep, '/'))
    return sorted(r for r in routes if 'unmatched' not in r)


def route_regex(route):
    parts = []
    for seg in route.strip('/').split('/'):
        if seg.startswith('[...') or seg.startswith('[[...'):
            parts.append('.*')
            break
        parts.append('[^/]+' if seg.startswith('[') else re.escape(seg))
    return re.compile('^/' + '/'.join(parts) + '$')


def flutter_paths():
    lit = re.compile(r"""(['"])(/api/[^'"\s]*)\1""")
    found = {}
    for dp, _, fs in os.walk(LIB):
        for f in fs:
            if not f.endswith('.dart'):
                continue
            p = os.path.join(dp, f)
            with open(p, encoding='utf-8', errors='ignore') as fh:
                for i, line in enumerate(fh, 1):
                    for m in lit.finditer(line):
                        path = m.group(2).split('?')[0]
                        path = re.sub(r'\$\{[^}]*\}', 'X', path)
                        path = re.sub(r'\$[A-Za-z_][A-Za-z0-9_.]*', 'X', path).rstrip('/')
                        path = re.sub(r'^/api/v1(?=/|$)', '/api', path)
                        found.setdefault(path, []).append((os.path.relpath(p, LIB), i))
    return found


def constant_name(lines, ln):
    for i in range(ln - 1, max(ln - 4, -1), -1):
        m = re.search(r'static (?:const |final )?(?:String\s+)?([A-Za-z0-9_]+)\s*(?:=|\()', lines[i])
        if m:
            return m.group(1)
    return None


def is_referenced(name):
    out = subprocess.run(
        ['grep', '-rlw', f'ApiEndpoints.{name}', LIB, '--include=*.dart'],
        capture_output=True, text=True,
    ).stdout
    return bool(out.strip())


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    used_only = '--used-only' in sys.argv
    routes = backend_routes(sys.argv[1])
    regexes = [route_regex(r) for r in routes]
    with open(ENDPOINTS, encoding='utf-8') as fh:
        ep_lines = fh.read().split('\n')

    missing = []
    for path, locs in sorted(flutter_paths().items()):
        if any(rx.match(path) for rx in regexes):
            continue
        if any(r.startswith(path + '/') for r in routes):
            continue
        for rel, ln in locs:
            if rel in IGNORED_SOURCES:
                continue
            if rel.endswith('api_endpoints.dart'):
                name = constant_name(ep_lines, ln)
                if name in IGNORED_CONSTANTS:
                    continue
                used = bool(name) and is_referenced(name)
                label = f'ApiEndpoints.{name}'
            else:
                used, label = True, f'{rel}:{ln}'
            if used or not used_only:
                missing.append((path, label, 'KULLANILIYOR' if used else 'kullanılmıyor'))

    print(f'Backend route: {len(routes)} · Flutter\'da backend karşılığı olmayan: {len(missing)}')
    for path, label, state in missing:
        print(f'  [{state}] {path}  ←  {label}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
