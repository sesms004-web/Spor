import re
with open("orig.mq5", "r") as f:
    orig = f.read()

match1 = re.search(r"void BxUpdateStats.*?\}", orig, re.DOTALL)
if match1:
    print(match1.group(0))
