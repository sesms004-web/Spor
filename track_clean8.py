import re
with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Delete TriggerMTFAlert completely
pattern2 = r'//\+------------------------------------------------------------------\+\n//\| MTF Alert System \(Smart Algorithmic Decision Engine\)             \|\n//\+------------------------------------------------------------------\+\nbool TriggerMTFAlert\(.*?\}\n'
text = re.sub(pattern2, '', text, flags=re.DOTALL)

with open('smacv1.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
