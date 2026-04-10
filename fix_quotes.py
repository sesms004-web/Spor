import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # The issue is there are stray newline characters with quotes `\n";\n` that got added incorrectly due to the previous regex script.

    cleaned_lines = []
    for line in lines:
        if line.strip() == '";':
            continue # Remove stray quotes on their own line
        cleaned_lines.append(line)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(cleaned_lines)

update_code('mukemmeliyet.mq5')
