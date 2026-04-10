import sys
with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Find any stray quotation errors or undeclared variables reported
if '"{\n"' in content or '",\n"' in content or 'true,\n"' in content or 'false,\n"' in content:
    print("STRAY NEWLINE FOUND")

if 'dir_str' not in content:
    print("DIR_STR NOT FOUND")

print("CHECKS DONE")
