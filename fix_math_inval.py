import re

with open('smcv1.mq5', 'r') as f:
    content = f.read()

math_only_idx = content.find("void ProcessBarMathOnly")
process_bar_idx = content.find("void ProcessBar(", math_only_idx)
math_only_body = content[math_only_idx:process_bar_idx]

# Remove the text rendering and drawing lines that may have snuck in if they did...
# In math only we just need to ensure the logic matches.
# Looking at the previous diff, we did this correctly.
