import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix literal string newlines everywhere
# Find any `",\n";` and replace with `",\\n";`
content = content.replace('",\n";', '",\\n";')
content = content.replace('{\n";', '{\\n";')
content = content.replace('rue,\n";', 'rue,\\n";')
content = content.replace('alse,\n";', 'alse,\\n";')
content = content.replace('rue\n";', 'rue\\n";')
content = content.replace('alse\n";', 'alse\\n";')

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
