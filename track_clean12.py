import re
with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Just remove the remnants of TriggerMTFAlert completely
# Wait, I didn't actually remove TriggerMTFAlert properly!
# Let me look where `TriggerMTFAlert` is defined.
idx = text.find('bool TriggerMTFAlert')
if idx != -1:
    print('TriggerMTFAlert is still in the file!')
