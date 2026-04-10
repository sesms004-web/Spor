with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []
for line in lines:
    if line.endswith('",\n') and 'json +=' in line:
        line = line.replace('",\n', '",\\n";\n')
    elif line.endswith('{\n') and 'string json =' in line:
        line = line.replace('{\n', '{\\n";\n')
    elif line.endswith('true,\n') and 'json +=' in line:
        line = line.replace('true,\n', 'true,\\n";\n')
    elif line.endswith('false,\n') and 'json +=' in line:
        line = line.replace('false,\n', 'false,\\n";\n')
    elif line.endswith('true\n') and 'json +=' in line:
        line = line.replace('true\n', 'true\\n";\n')
    elif line.endswith('false\n') and 'json +=' in line:
        line = line.replace('false\n', 'false\\n";\n')
    out.append(line)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.writelines(out)
