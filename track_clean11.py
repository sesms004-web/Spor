with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

open_braces = 0
for i, line in enumerate(text.split('\n')):
    for char in line:
        if char == '{':
            open_braces += 1
        elif char == '}':
            open_braces -= 1
    if open_braces < 0:
        print(f"Negative braces at line {i+1}: {line}")
        open_braces = 0
print(f"End braces: {open_braces}")
