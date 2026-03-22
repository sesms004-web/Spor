with open("Nasilsin_Indicator.mq5", "r") as f:
    lines = f.readlines()

# Line 1588 is the extra closing brace. Let's delete it.
lines = lines[:-1]

with open("Nasilsin_Indicator.mq5", "w") as f:
    f.writelines(lines)
