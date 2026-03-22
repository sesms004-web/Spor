import re

def validate_mq5_braces(filename):
    with open(filename, 'r') as f:
        text = f.read()

    # Remove strings
    text = re.sub(r'".*?"', '""', text)
    # Remove single line comments
    text = re.sub(r'//.*', '', text)
    # Remove multi-line comments
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)

    lines = text.split('\n')
    stack = []

    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            if char == '{':
                stack.append(i + 1)
            elif char == '}':
                if not stack:
                    print(f"Error: Unmatched '}}' at line {i + 1}")
                    return False
                stack.pop()

    if stack:
        print(f"Error: Unmatched '{{' at lines {stack}")
        return False

    print("Braces are balanced.")
    return True

validate_mq5_braces('Nasilsin_Indicator.mq5')
