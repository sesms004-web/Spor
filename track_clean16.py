import re
with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# I see a return true; and closing brace at line 1254.
# This looks like the end of `TriggerMTFAlert`!
# Let me look closely around 1254.

idx = text.find('return true;\n  }')
if idx != -1:
    print('Found return true at end of TriggerMTFAlert')
    # Where does this block start?
    start_idx = text.rfind('if(InpAlertPopup)', 0, idx)
    print(text[start_idx-200:idx+50])
