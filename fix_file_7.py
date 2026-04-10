def fix_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    for i in range(len(lines)):
        if lines[i].strip() == 'string json = "{':
            lines[i] = lines[i].replace('string json = "{', 'string json = "{\\n";\n')
        elif 'json +=' in lines[i] and not lines[i].strip().endswith('";'):
            # The line is something like: json += "  \"symbol\": \"" + Symbol() + "\",
            # We want to replace the trailing comma/newline with \\n";\n
            if lines[i].rstrip().endswith(','):
                lines[i] = lines[i].rstrip() + '\\n";\n'
            else:
                lines[i] = lines[i].rstrip() + '\\n";\n'

    with open(filepath, 'w') as f:
        f.writelines(lines)

fix_file('mukemmeliyet.mq5')
