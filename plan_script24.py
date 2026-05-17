import re
with open("orig.mq5", "r") as f:
    orig = f.read()

with open("misyoner001.mq5", "r") as f:
    code = f.read()

def get_bxupdate(c):
    match = re.search(r"void BxUpdateStats.*?\{(.*?)\}", c, re.DOTALL)
    return match.group(1) if match else "none"

print("Orig BxUpdateStats inside loop:")
match1 = re.search(r"for\(int k=0;k<g_bx_cnt;k\+\+\).*?\{(.*?)\}", get_bxupdate(orig), re.DOTALL)
if match1: print(match1.group(1).strip()[:200])

print("\nCode BxUpdateStats inside loop:")
match2 = re.search(r"for\(int k=0;k<g_bx_cnt;k\+\+\).*?\{(.*?)\}", get_bxupdate(code), re.DOTALL)
if match2: print(match2.group(1).strip()[:200])
