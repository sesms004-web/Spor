with open('denemevol1.mq5', 'r') as f:
    text = f.read()

import re
matches = re.findall(r'bool inside =.*?;', text)
for m in matches:
    print(m)
