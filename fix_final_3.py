with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Manual brute force character search
# We need to find `string json = "{\n";\n";`
text = text.replace('string json = "{\n";\n";', 'string json = "{\\n";')
text = text.replace('",\n";', '",\\n";')
text = text.replace('true,\n";\n";', 'true,\\n";')
text = text.replace('false,\n";\n";', 'false,\\n";')
text = text.replace('true\n";\n";', 'true\\n";')
text = text.replace('false\n";\n";', 'false\\n";')

# the ones in the middle
text = text.replace('",\n";', '",\\n";')

# also standard ones that I broke in fix_final.py
text = text.replace('",\n";', '",\\n";') # Wait, previously I replaced '",\n' with '",\\n";\n'. Which means it became '",\\n";\n'

text = text.replace('",\\n";\n', '",\\n";\n') # No wait, it was:
# if line.endswith('",\n'): lines[i] = line.replace('",\n', '",\\n";\n')
# which makes `json += "  \\"symbol\\": \\"" + Symbol() + "\\",\n";`
# become `json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";\n";`

text = text.replace('",\\n";\n";', '",\\n";\n')
text = text.replace('true,\\n";\n";', 'true,\\n";\n')
text = text.replace('false,\\n";\n";', 'false,\\n";\n')
text = text.replace('true\\n";\n";', 'true\\n";\n')
text = text.replace('false\\n";\n";', 'false\\n";\n')

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
