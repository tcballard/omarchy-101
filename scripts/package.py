#!/usr/bin/env python3
"""Package a clean committed source candidate; never tag or publish."""
import datetime
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
def git(*args):
    return subprocess.check_output(['git', '-C', str(root), *args])

if len(sys.argv) != 2:
    raise SystemExit('Usage: python3 scripts/package.py /new/output/directory')
if git('status', '--porcelain').strip():
    raise SystemExit('Commit or remove working-tree changes before packaging.')
out = Path(sys.argv[1]).resolve()
if out == root or root in out.parents:
    raise SystemExit('Output directory must be outside the source checkout.')
if out.exists():
    raise SystemExit('Output directory must not already exist.')
sha = git('rev-parse', 'HEAD').decode().strip()
tree = git('rev-parse', 'HEAD^{tree}').decode().strip()
version = json.loads(git('show', 'HEAD:manifest.json'))['version']
source = {'repository':'https://github.com/tcballard/omarchy-101', 'commit':sha, 'tree':tree}
identity = {'schemaVersion':1, 'version':version, 'source':source}
created = datetime.datetime.fromtimestamp(int(git('show','-s','--format=%ct','HEAD')),datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
out.mkdir(parents=True)
archive = f'omarchy-101-{version}-{sha[:12]}.tar.gz'
(out/archive).write_bytes(gzip.compress(git('archive', '--format=tar', '--prefix=omarchy-101/', sha),mtime=0))
def write(name, data):
    (out/name).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
def entry(name):
    data=(out/name).read_bytes()
    return {'name':name, 'bytes':len(data), 'sha256':hashlib.sha256(data).hexdigest()}
write('SOURCE-MANIFEST.json',identity)
write('SBOM.spdx.json', {
    'spdxVersion':'SPDX-2.3', 'dataLicense':'CC0-1.0', 'SPDXID':'SPDXRef-DOCUMENT',
    'name':f'omarchy-101-{version}-source',
    'documentNamespace':f'https://tcballard.dev/spdx/omarchy-101/{sha}',
    'creationInfo':{'created':created,'creators':['Tool: omarchy-101-package']},
    'packages':[{'SPDXID':'SPDXRef-101','name':'omarchy-101','versionInfo':version,
      'downloadLocation':source['repository']+'@'+sha,'filesAnalyzed':False,
      'licenseDeclared':'MIT','licenseConcluded':'NOASSERTION',
      'copyrightText':'NOASSERTION',
      'comment':'Source-only package; host Qt/Quickshell, Hyprland, Bash and GNU coreutils are external, not bundled. Development tools are not runtime dependencies.'}],
    'relationships':[{'spdxElementId':'SPDXRef-DOCUMENT','relationshipType':'DESCRIBES','relatedSpdxElement':'SPDXRef-101'}]
})
write('RELEASE-MANIFEST.json',dict(identity,artifacts=[entry(archive)],releaseDocuments=[entry('SOURCE-MANIFEST.json'),entry('SBOM.spdx.json')]))
files=sorted(p.name for p in out.iterdir())
(out/'SHA256SUMS').write_text(''.join(entry(name)['sha256']+'  '+name+'\n' for name in files))
print(json.dumps({'source':source,'version':version,'archive':archive,'bytes':(out/archive).stat().st_size,'output':str(out)}))
