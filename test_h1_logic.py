import re

with open('denemevol1.mq5', 'r') as f:
    text = f.read()

# Let's extract the H1 logic block
search = re.search(r'// --- H1 MACRO LOGIC ---.*?total_points \+= h1_points;', text, re.DOTALL)
if search:
    print(search.group(0))
