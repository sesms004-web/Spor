import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # The actual string still has newlines literally inside the python string we're reading.
    # Let's use regex to replace literal newlines before `";`

    # We are matching `\n";`
    content = re.sub(r'\n";', r'\\n";', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_code('mukemmeliyet.mq5')
