import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

match2 = re.search(r"void BxUpdateStats(.*?)\}\s*\n\}", code, re.DOTALL)
if match2:
    print(match2.group(0))
