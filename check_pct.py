import re

with open('smcvol01.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Let's inspect the exact calculation of max_pct and pct inside GetMTFPullback again to see if there's an artificial ceiling or floor.
match = re.search(r'if\(st\.maj_h != EMPTY_VALUE && st\.maj_l != EMPTY_VALUE && st\.maj_h != st\.maj_l\).*?return \(trend != 0\);', content, re.DOTALL)
if match:
    print(match.group(0))
else:
    print("Not found")
