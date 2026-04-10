import sys
with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's count all '{' and '}' to see if there is a mismatch
open_braces = text.count('{')
close_braces = text.count('}')

print(f"Open: {open_braces}, Close: {close_braces}")
if open_braces != close_braces:
    print("MISMATCH!")
