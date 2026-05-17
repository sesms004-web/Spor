import re

with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Wait... BxUpdateStats hasn't changed its touch state logic.
# Wait! Did I change something in BxAdd?
# The original code did `_DrawWeakRect(...)` but what about `DoDrawBox`?
match = re.search(r"void DoDrawBox(.*?)\}.*?\}", code, re.DOTALL)
if match:
    print(match.group(0))
