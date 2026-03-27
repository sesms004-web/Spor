import math

with open('denemevol1.mq5', 'r') as f:
    lines = f.readlines()

total_lines = len(lines)
midpoint = math.floor(total_lines / 2)

break_index = midpoint
for i in range(midpoint, total_lines):
    if lines[i].strip() == "}":
        break_index = i + 1
        break

part1 = "".join(lines[:break_index])
part2 = "".join(lines[break_index:])

with open('denemevol1_part1.txt', 'w') as f:
    f.write(part1)

with open('denemevol1_part2.txt', 'w') as f:
    f.write(part2)
