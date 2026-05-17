import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Let's check `_DrawWeakRect` and `DrawRect`.
match = re.search(r"void _DrawWeakRect.*?\}", code, re.DOTALL)
if match:
    print(match.group(0))
