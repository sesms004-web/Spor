import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Let's read `ProcessBar` major structure section.
match = re.search(r"// ══ MAJÖR YAPI ═══════════════════════════════════════════════(.*?)(// ───|string GetBoxStatusStr)", code, re.DOTALL)
if match:
    pass
