import re

with open('denemevol1.mq5', 'r') as f:
    text = f.read()

# Let's check how the GetMTFPullback handles live price exceeding the anchor.
search = re.search(r'if\(trend == 1\).*?else if\(trend == -1\)', text, re.DOTALL)
if search:
    print(search.group(0))
