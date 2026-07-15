import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Find unmatched brace location
text = content
stack = []
unmatched = -1
for i, char in enumerate(text):
    if char == '{':
        stack.append(i)
    elif char == '}':
        if stack:
            stack.pop()
        else:
            unmatched = i
            break

if unmatched != -1:
    print(f"Unmatched }} at index {unmatched}")
    # Let's print the context
    start = max(0, unmatched - 200)
    end = min(len(text), unmatched + 200)
    print("Context around unmatched brace:\n", text[start:end])
else:
    print("No unmatched } found.")
