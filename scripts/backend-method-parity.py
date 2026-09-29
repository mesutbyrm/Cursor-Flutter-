import os, re, json, sys
from collections import defaultdict

# Kullanım: python3 scripts/backend-method-parity.py <canlifal>/nextjs_space [--unr]
# Flutter çağrılarının HTTP metodunu backend route.ts export'larıyla karşılaştırır.
BE = next((a for a in sys.argv[1:] if not a.startswith('--')), '/tmp/canlifal/nextjs_space')
LIB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'mobile', 'lib')
EP = os.path.join(LIB, 'core/network/api_endpoints.dart')

# ---- backend routes + methods
routes = {}
for dp, _, fs in os.walk(os.path.join(BE, 'app/api')):
    if 'route.ts' not in fs:
        continue
    rel = '/' + os.path.relpath(dp, os.path.join(BE, 'app')).replace(os.sep, '/')
    src = open(os.path.join(dp, 'route.ts'), encoding='utf-8', errors='ignore').read()
    ms = set(re.findall(r'export\s+(?:async\s+)?function\s+(GET|POST|PUT|PATCH|DELETE)\b', src))
    ms |= set(re.findall(r'export\s+const\s+(GET|POST|PUT|PATCH|DELETE)\s*=', src))
    for grp in re.findall(r'export\s+(?:const\s+)?\{([^}]*)\}', src):
        ms |= set(re.findall(r'\b(GET|POST|PUT|PATCH|DELETE)\b', grp))
    routes[rel] = ms

def rx(r):
    parts = []
    for seg in r.strip('/').split('/'):
        if seg.startswith('[...') or seg.startswith('[[...'):
            parts.append('.*'); break
        parts.append('[^/]+' if seg.startswith('[') else re.escape(seg))
    return re.compile('^/' + '/'.join(parts) + '$')
# static routes first so /x/list beats /x/[id]
ordered = sorted([r for r in routes if 'unmatched' not in r], key=lambda r: (r.count('['), -len(r)))
compiled = [(r, rx(r)) for r in ordered]

def match(path):
    path = re.sub(r'^/api/v1(?=/|$)', '/api', path).rstrip('/')
    for r, c in compiled:
        if c.match(path):
            return r
    # Flutter şablonları ($slug → X): örnek slug ile eşleştir.
    if re.search(r'/X(?=/|$)', path):
        sample = re.sub(r'/X(?=/|$)', '/tarot-fali', path)
        for r, c in compiled:
            if c.match(sample):
                return r
    return None

# ---- ApiEndpoints constants (name -> raw template)
src = open(EP, encoding='utf-8').read()
consts = {}
for m in re.finditer(r"static\s+(?:const\s+|final\s+)?(?:String\s+)?(\w+)\s*(?:\(([^)]*)\))?\s*(?:=>|=)\s*((?:'[^']*'\s*)+|\w+\([^;]*\)|[^;]+);", src):
    name, params, expr = m.group(1), m.group(2), m.group(3).strip()
    consts[name] = expr

def eval_expr(expr, depth=0):
    """Dart string ifadesini yaklaşık yol şablonuna çevir; bilinmeyen parça -> X."""
    expr = expr.strip()
    if depth > 6:
        return None
    m = re.fullmatch(r'ApiEndpoints\.(\w+)(\([^)]*\))?', expr)
    if m:
        v = consts.get(m.group(1))
        return eval_expr(v, depth + 1) if v else None
    m = re.fullmatch(r'(\w+)(\([^)]*\))?', expr)
    if m and m.group(1) in consts and not expr.startswith("'"):
        return eval_expr(consts[m.group(1)], depth + 1)
    lits = re.findall(r"'([^']*)'", expr)
    if not lits:
        return None
    s = ''.join(lits)
    def sub(mm):
        inner = mm.group(1)
        v = eval_expr(inner, depth + 1) if re.fullmatch(r'(ApiEndpoints\.)?\w+(\([^)]*\))?', inner) else None
        return v if v and v.startswith('/') else 'X'
    s = re.sub(r'\$\{([^}]*)\}', sub, s)
    s = re.sub(r'\$\w+', 'X', s)
    return s.split('?')[0]

CALL = re.compile(r'\.\s*(safeGet|safePost|safePut|safePatch|safeDelete|get|post|put|patch|delete)\s*(?:<[^>(]*>)?\s*\(\s*')
METHOD = {'safeGet': 'GET', 'get': 'GET', 'safePost': 'POST', 'post': 'POST', 'safePut': 'PUT', 'put': 'PUT',
          'safePatch': 'PATCH', 'patch': 'PATCH', 'safeDelete': 'DELETE', 'delete': 'DELETE'}

def first_arg(text, i):
    depth = 0; j = i; q = None
    while j < len(text):
        c = text[j]
        if q:
            if c == q and text[j-1] != '\\': q = None
        elif c in "'\"": q = c
        elif c in '([{': depth += 1
        elif c in ')]}':
            if depth == 0: return text[i:j]
            depth -= 1
        elif c == ',' and depth == 0:
            return text[i:j]
        j += 1
    return text[i:j]

def split_top(s):
    out=[]; depth=0; q=None; cur=''
    for i,c in enumerate(s):
        if q:
            cur+=c
            if c==q and s[i-1]!='\\': q=None
            continue
        if c in "'\"": q=c
        if c in '([{': depth+=1
        if c in ')]}': depth-=1
        if c==',' and depth==0: out.append(cur.strip()); cur=''; continue
        cur+=c
    if cur.strip(): out.append(cur.strip())
    return out

def resolve_var(text, pos, arg):
    name_m = re.fullmatch(r'([A-Za-z_]\w*)(\(.*\))?', arg.strip(), re.S)
    if not name_m: return None
    name = name_m.group(1)
    before = text[max(0,pos-6000):pos]
    cands = []
    # for (final path in [ ... ])
    for fm in re.finditer(r'for\s*\(\s*(?:final|var|String)\s+(?:String\s+)?'+name+r'\s+in\s+(?:<[^>]*>)?\[', before):
        j = fm.end(); depth=1; k=j
        while k < len(before) and depth:
            if before[k]=='[': depth+=1
            elif before[k]==']': depth-=1
            k+=1
        cands = split_top(before[j:k-1])
    if not cands:
        am = list(re.finditer(r'(?:final|var|String\??|const)\s+'+name+r'\s*=\s*([^;]+);', before))
        if am:
            e = am[-1].group(1).strip()
            # ternary -> both branches
            parts = re.split(r'\s\?\s|\s:\s', e)
            cands = parts[1:] if len(parts) == 3 else [e]
    if not cands and name_m.group(2) is not None:
        fm = re.search(r'String\??\s+'+name+r'\s*\([^)]*\)\s*=>\s*([^;]+);', text)
        if fm:
            e = fm.group(1).strip()
            parts = re.split(r'\s\?\s|\s:\s', e)
            cands = parts[1:] if len(parts) == 3 else [e]
    cands = [c for c in cands if 'ApiEndpoints' in c or c.startswith("'")]
    return cands or None

bad = []; unresolved = 0; ok = 0; UNR=[]
for dp, _, fs in os.walk(LIB):
    for f in fs:
        if not f.endswith('.dart'): continue
        p = os.path.join(dp, f); rel = os.path.relpath(p, LIB)
        text = open(p, encoding='utf-8', errors='ignore').read()
        for m in CALL.finditer(text):
            arg = first_arg(text, m.end()).strip()
            cands = None
            if not ('ApiEndpoints' in arg or arg.startswith("'") or arg.startswith('"')):
                cands = resolve_var(text, m.start(), arg)
            if cands:
                line = text.count('\n', 0, m.start()) + 1
                meth = METHOD[m.group(1)]
                for c in cands:
                    path = eval_expr(c.replace('"', "'"))
                    if not path or not path.startswith('/api'):
                        continue
                    r = match(path)
                    if r is None:
                        bad.append(('NO_ROUTE*', meth, path, None, f'{rel}:{line}'))
                    elif routes[r] and meth not in routes[r]:
                        bad.append(('BAD_METHOD*', meth, path, ','.join(sorted(routes[r])), f'{rel}:{line}'))
                    else:
                        ok += 1
                continue
            if not ('ApiEndpoints' in arg or arg.startswith("'") or arg.startswith('"')):
                unresolved += 1; UNR.append((rel, text.count('\n',0,m.start())+1, METHOD[m.group(1)], arg[:80])); continue
            path = eval_expr(arg.replace('"', "'"))
            if not path or not path.startswith('/api'):
                unresolved += 1; continue
            line = text.count('\n', 0, m.start()) + 1
            meth = METHOD[m.group(1)]
            r = match(path)
            if r is None:
                bad.append(('NO_ROUTE', meth, path, None, f'{rel}:{line}'))
            elif routes[r] and meth not in routes[r]:
                bad.append(('BAD_METHOD', meth, path, ','.join(sorted(routes[r])), f'{rel}:{line}'))
            else:
                ok += 1
print(f'ok={ok} unresolved={unresolved} bad={len(bad)}')
for b in sorted(bad, key=lambda x: (x[0], x[2])):
    print(' | '.join(str(x) for x in b))

if '--unr' in sys.argv:
    for u in UNR: print('%s:%d %s %s' % u)

if '--helpers' in sys.argv:
    helpers = {'ingest':'GET','_fetch360':'GET','_fetchSection':'GET','_tryGetMap':'GET','_fetchJsonList':'GET','_getList':'GET','_getMap':'GET'}
    for dp, _, fs in os.walk(LIB):
        for f in fs:
            if not f.endswith('.dart'): continue
            p=os.path.join(dp,f); rel=os.path.relpath(p,LIB); text=open(p,encoding='utf-8').read()
            for h,meth in helpers.items():
                for m in re.finditer(r'\b'+h+r'\s*\(\s*', text):
                    arg=first_arg(text,m.end()).strip()
                    if not ('ApiEndpoints' in arg or arg.startswith("'")): continue
                    path=eval_expr(arg)
                    line=text.count('\n',0,m.start())+1
                    if not path: print('??', rel, line, arg); continue
                    r=match(path)
                    st='OK' if r and (not routes[r] or meth in routes[r]) else ('NO_ROUTE' if r is None else 'BAD '+','.join(routes[r]))
                    if st!='OK': print(st, meth, path, rel, line)
