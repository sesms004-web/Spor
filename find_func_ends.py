with open('smaecv1.mq5', 'r', encoding='utf-8') as f:
    lines = f.readlines()

in_func = False
brace_count = 0
for i, line in enumerate(lines):
    if not in_func and "{" in line and "}" not in line and not line.strip().startswith("//"):
        if "void " in line or "int " in line or "double " in line or "bool " in line or "string " in line or "struct " in line or "class " in line or "OnCalculate" in line:
            in_func = True
            brace_count = 0

    if in_func:
        brace_count += line.count('{')
        brace_count -= line.count('}')
        if brace_count == 0:
            in_func = False
            print(f"Function ended at line {i+1}")
