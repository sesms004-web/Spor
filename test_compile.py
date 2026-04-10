import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    code = f.read()

# Let's check for any stray quotes syntax errors
print("Testing")
