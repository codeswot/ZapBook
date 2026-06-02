import json
import base64
import gzip
import re

with open("/Users/codeswot/workspace/frontend/mobile/flutter/zapbook/zap_design_templ.html", "r", encoding="utf-8") as f:
    content = f.read()

manifest_match = re.search(r'<script type="__bundler/manifest">(.*?)</script>', content, re.DOTALL)
if not manifest_match:
    print("Manifest not found")
    exit(1)

manifest_data = json.loads(manifest_match.group(1).strip())

uuid = "f33decd1-b90f-4458-9da2-199122f2281a"
asset = manifest_data[uuid]
data = base64.b64decode(asset["data"])
if asset.get("compressed"):
    data = gzip.decompress(data)

text = data.decode("utf-8", errors="ignore")
with open("/Users/codeswot/workspace/frontend/mobile/flutter/zapbook/scratch/onboarding_source.js", "w", encoding="utf-8") as out:
    out.write(text)

print("Saved onboarding source JS code to scratch/onboarding_source.js")
