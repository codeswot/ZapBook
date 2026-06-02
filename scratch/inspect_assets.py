import json
import base64
import gzip
import re

with open("/Users/codeswot/workspace/frontend/mobile/flutter/zapbook/zap_design_templ.html", "r", encoding="utf-8") as f:
    content = f.read()

# Find the manifest JSON
manifest_match = re.search(r'<script type="__bundler/manifest">(.*?)</script>', content, re.DOTALL)
if not manifest_match:
    print("Manifest not found")
    exit(1)

manifest_data = json.loads(manifest_match.group(1).strip())
print(f"Loaded {len(manifest_data)} assets from manifest.")

# We want to search for OBWelcome
for uuid, asset in manifest_data.items():
    try:
        data = base64.b64decode(asset["data"])
        if asset.get("compressed"):
            data = gzip.decompress(data)
        
        # Decode as utf-8
        text = data.decode("utf-8", errors="ignore")
        if "OBWelcome" in text or "OBIdentity" in text or "OBWallet" in text:
            print(f"Found match in asset {uuid} ({asset.get('mime')})")
            # print first 500 chars
            print(text[:2000])
            print("="*80)
    except Exception as e:
        pass
