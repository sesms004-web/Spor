import re
with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Make sure there is no trailing `InpTestMode` in OnCalculate
text = re.sub(r'\|\|\s*InpTestMode', '', text)
text = re.sub(r'&&\s*!InpTestMode', '', text)

# Is there any other test mode reference?
if 'InpTestMode' in text:
    print('Still found InpTestMode')

with open('smacv1.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
