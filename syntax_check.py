import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Let's do a basic balance check of curly braces
def check_balance(text):
    stack = []
    for i, char in enumerate(text):
        if char == '{':
            stack.append(i)
        elif char == '}':
            if stack:
                stack.pop()
            else:
                return f"Unmatched }} at {i}"
    if stack:
        return f"Unmatched {{ at {stack[-1]}"
    return "Balanced"

print("Braces:", check_balance(content))

# Look for orphaned else or else if
for i, line in enumerate(content.split('\n')):
    if 'else if' in line or 'else' in line:
        pass # we can't easily parse it but we fixed the ones found by the reviewer.
