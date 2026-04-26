import sys

def check_brackets(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    count = 0
    for i, char in enumerate(content):
        if char == '{':
            count += 1
        elif char == '}':
            count -= 1

        if count < 0:
            print(f"Error: unmatched closing bracket at character {i}")
            return

    if count == 0:
        print("Brackets are balanced!")
    else:
        print(f"Error: {count} unclosed opening brackets.")

check_brackets('SwingYapisi.mqh')
