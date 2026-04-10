import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Using regex line by line
lines = text.split('\n')
for i in range(len(lines)):
    if 'string json = "{' in lines[i]:
        lines[i] = lines[i].replace('string json = "{', 'string json = "{\\n";')
    elif 'json += "  \\"symbol' in lines[i]:
        lines[i] = lines[i].replace('",', '",\\n";')
    elif 'json += "  \\"direction' in lines[i]:
        lines[i] = lines[i].replace('",', '",\\n";')
    elif 'json += "  \\"entry' in lines[i]:
        lines[i] = lines[i].replace(',"', ',\\n";')
    elif 'json += "  \\"sl' in lines[i]:
        lines[i] = lines[i].replace(',"', ',\\n";')
    elif 'json += "  \\"tp' in lines[i]:
        lines[i] = lines[i].replace(',"', ',\\n";')
    elif 'json += "  \\"base_extreme' in lines[i]:
        lines[i] = lines[i].replace(',"', ',\\n";')
    elif 'json += "  \\"is_strong' in lines[i]:
        lines[i] = lines[i].replace(',"', ',\\n";')
    elif 'json += "  \\"is_test' in lines[i] and 'true' in lines[i] and '?' not in lines[i]:
        lines[i] = lines[i].replace('true"', 'true\\n";')
    elif 'json += "  \\"is_test' in lines[i] and 'InpTestMode' in lines[i]:
        lines[i] = lines[i].replace('"', '\\n";')

# Let's just directly re-write the two functions completely.
# Function 1: MANUEL TEST
