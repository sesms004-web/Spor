import re
with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Delete the duplicate block starting at the second occurrence of YENİ DESTEKLEYİCİ CHOCH
idx1 = text.find('// --- YENİ DESTEKLEYİCİ CHOCH FAKEOUT (TUZAK) MATRİS SİSTEMİ ---')
idx2 = text.find('// --- YENİ DESTEKLEYİCİ CHOCH FAKEOUT (TUZAK) MATRİS SİSTEMİ ---', idx1 + 10)

if idx2 != -1:
    # We need to find the end of this second block.
    # It ends right before `string order_details = "";`
    # Let's see:
    end_idx = text.find('string order_details = "";', idx2)
    if end_idx != -1:
        text = text[:idx2] + text[end_idx:]

with open('smacv1.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
