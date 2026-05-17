import re

with open("orig.mq5", "r") as f:
    orig = f.read()

with open("misyoner001.mq5", "r") as f:
    code = f.read()

def get_bxtrim(c):
    match = re.search(r"void BxAdvanceTrim\(datetime t\)\s*\{(.*?)\}", c, re.DOTALL)
    return match.group(1) if match else "none"

print("orig BxAdvanceTrim:", get_bxtrim(orig))
print("code BxAdvanceTrim:", get_bxtrim(code))
