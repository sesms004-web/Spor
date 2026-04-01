import re

with open('denemevol1.mq5', 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "CHoCH & T1-D1-T2 TRACKING LOGIC" in line:
        print("Found CHoCH logic at line", i)
    if "if (state.choch_dir == -1 && state.t2_h > state.t1_h && state.d1_l != 0)" in line:
        print("Found Bearish CHoCH condition at line", i)
