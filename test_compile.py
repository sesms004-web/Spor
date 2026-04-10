import sys
# Just check if there are no literal newlines in strings
with open('mukemmeliyet.mq5', 'r') as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if line.strip() == 'string json = "{':
        print(f"Error on line {i}")
        sys.exit(1)
print("String looks fine.")
