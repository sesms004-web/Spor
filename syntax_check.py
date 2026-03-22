import re

def check_brackets(filepath):
    with open(filepath, 'r') as f:
        text = f.read()

    open_b = text.count('{')
    close_b = text.count('}')
    print(f"Brackets count: open={open_b}, close={close_b}")

    if open_b == close_b:
        print("Brackets are balanced.")
    else:
        print("Brackets are NOT balanced!")

check_brackets('denemevol1.mq5')
