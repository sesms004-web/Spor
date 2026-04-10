import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# I'm going to just replace the whole file because this regexing is failing.
# Actually I'll find exactly `string json = "{\n";`
# The problem is `\n` in python strings can be literal or escaped.

text = text.replace('string json = "{\n";', 'string json = "{\\n";')
text = text.replace('",\n";', '",\\n";')
text = text.replace('true,\n";', 'true,\\n";')
text = text.replace('false,\n";', 'false,\\n";')
text = text.replace('true\n";', 'true\\n";')
text = text.replace('false\n";', 'false\\n";')

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
