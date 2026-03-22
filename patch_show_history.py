import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Remove the !is_history constraint
search1 = "if (InpShowChoch && !is_history) {"
replace1 = "if (InpShowChoch) {"

content = content.replace(search1, replace1)

# Ensure lines are drawn on the chart.
with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("History constraint removed")
