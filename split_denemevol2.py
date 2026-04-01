import math

with open('denemevol2.mq5', 'r') as f:
    lines = f.readlines()

total = len(lines)
mid = math.floor(total / 2)

break_idx = mid
for i in range(mid, total):
    if lines[i].strip() == "}":
        break_idx = i + 1
        break

p1 = "".join(lines[:break_idx])
p2 = "".join(lines[break_idx:])

with open('dv2_p1.txt', 'w') as f:
    f.write(p1)
with open('dv2_p2.txt', 'w') as f:
    f.write(p2)
