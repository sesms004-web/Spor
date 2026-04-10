import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # The actual string still has newlines. We can use a different approach.

    lines = content.split('\n')
    for i, line in enumerate(lines):
        if line == '           string json = "{':
            lines[i] = '           string json = "{\\n";'
        if line == '               string json = "{':
            lines[i] = '               string json = "{\\n";'
        if line.startswith('           json += "') and line.endswith(','):
            lines[i] = line + '\\n";'
        if line.startswith('               json += "') and line.endswith(','):
            lines[i] = line + '\\n";'
        if line.startswith('           json += "  \\"is_test\\"') and line.endswith('true'):
            lines[i] = line + '\\n";'
        if line.startswith('               json += "  \\"is_test\\"') and line.endswith('") + "'):
            lines[i] = line + '\\n";'

    content = '\n'.join(lines)

    # We will just write a small script that replaces the specific malformed block

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_code('mukemmeliyet.mq5')
