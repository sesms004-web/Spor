with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'string json = "{' in line:
        lines[i] = line.replace('string json = "{', 'string json = "{\\n";')
    elif 'json +=' in line:
        if line.endswith('",\n'):
            lines[i] = line.replace('",\n', '",\\n";\n')
        elif line.endswith('true,\n'):
            lines[i] = line.replace('true,\n', 'true,\\n";\n')
        elif line.endswith('false,\n'):
            lines[i] = line.replace('false,\n', 'false,\\n";\n')
        elif line.endswith('true\n'):
            lines[i] = line.replace('true\n', 'true\\n";\n')
        elif line.endswith('false\n'):
            lines[i] = line.replace('false\n', 'false\\n";\n')

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.writelines(lines)
