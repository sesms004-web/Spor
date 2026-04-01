import re

with open('denemevol1.mq5', 'r') as f:
    text = f.read()

# Check how max_pct and pct are capped
search = re.search(r'if\(pct < 0\).*?return true;', text, re.DOTALL)
if search:
    print(search.group(0))
