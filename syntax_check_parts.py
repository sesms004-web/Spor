with open('denemevol1_part1.txt', 'r') as f1:
    p1 = f1.read()
with open('denemevol1_part2.txt', 'r') as f2:
    p2 = f2.read()

full_code = p1 + p2

open_b = full_code.count('{')
close_b = full_code.count('}')

print(f"Brackets: {open_b} / {close_b}")

if open_b == close_b:
    print("Syntax ok.")
