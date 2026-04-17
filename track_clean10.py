import re
with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r'\s*if\(InpTestMode\) msg2 = "🧪 \[TEST MODU - " \+ Symbol\(\) \+ "\] BÖLÜM 2/2\\n\\n";\n', '\n', text)
text = re.sub(r'InpTriggerLevel1', '', text)
text = re.sub(r'InpTriggerLevel2', '', text)

with open('smacv1.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
