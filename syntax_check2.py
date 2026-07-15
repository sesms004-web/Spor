import re
with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Let's ensure no `else` or `else if` is orphaned.
lines = content.split('\n')
for i, line in enumerate(lines):
    # simple heuristic: if a line starts with `else` or `else if` and the previous uncommented line didn't end with `}` or `if(...)` or a statement, it might be orphaned.
    if re.match(r'^\s*else\s+if', line) or re.match(r'^\s*else\s*\{', line) or re.match(r'^\s*else\s*$', line):
        prev_idx = i - 1
        while prev_idx >= 0 and (lines[prev_idx].strip() == '' or lines[prev_idx].strip().startswith('//')):
            prev_idx -= 1
        if prev_idx >= 0:
            prev_line = lines[prev_idx].strip()
            # if prev_line is empty or doesn't look like the end of an if block
            if not (prev_line.endswith('}') or prev_line.endswith(';') or 'if' in prev_line or 'else' in prev_line):
                pass # print(f"Suspicious else at {i+1}: {line}\nPrev: {prev_line}")

print("Check done.")
