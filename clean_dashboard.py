import re

with open('SwingYapisi.mqh', 'r') as f:
    text = f.read()

# I see UpdateLiveDashboard in SwingYapisi.mqh because it must have been captured by my regex that copied everything after ProcessBar up to the end of the file.
# Wait, I copied ProcessBar by looking at its end, but maybe it captured until the end of the whole file if the regex `ProcessBar(.*)\n  \}\n` grabbed too much.

# ProcessBar ends exactly where it returns. Let's find where ProcessBar actually ends.
# I will just remove UpdateLiveDashboard completely.

idx = text.find('void UpdateLiveDashboard()')
if idx != -1:
    text = text[:idx]

with open('SwingYapisi.mqh', 'w') as f:
    f.write(text)
