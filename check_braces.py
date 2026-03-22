import sys

def check_braces(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    lines = content.split('\n')
    stack = []

    in_comment_block = False

    for i, line in enumerate(lines):
        line = line.strip()
        # simplified check, not perfect for multiline strings/comments
        # just looking at { and }
        j = 0
        while j < len(line):
            if not in_comment_block and line[j:j+2] == '/*':
                in_comment_block = True
                j += 2
                continue
            if in_comment_block and line[j:j+2] == '*/':
                in_comment_block = False
                j += 2
                continue
            if not in_comment_block and line[j:j+2] == '//':
                break

            if not in_comment_block:
                if line[j] == '{':
                    stack.append((i + 1, j))
                elif line[j] == '}':
                    if stack:
                        stack.pop()
                    else:
                        print(f"Unmatched closing brace at line {i+1}")
            j += 1

    if stack:
        print("Unmatched opening braces:")
        for line_num, col in stack:
            print(f"Line {line_num}")
    else:
        print("Braces perfectly matched!")

check_braces('Nasilsin_Indicator.mq5')
