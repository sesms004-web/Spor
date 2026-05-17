import re

with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Let's search for "BxUpdateStats" inside "ProcessBar".
match = re.search(r"void ProcessBar.*?BxUpdateStats.*?// ══ MİNÖR", code, re.DOTALL)
if match:
    print(match.group(0))
