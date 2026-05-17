import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

match = re.search(r"void BxAdvanceTrim\(datetime t\)\s*\{(.*?)\}", code, re.DOTALL)
if match:
    print(match.group(0))
