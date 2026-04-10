with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Add the alert back to the exact block
start = text.find('   msg += "--- 🧭 BEKLENTİ ---\\n";')
end = text.find('   // --- YENİ AKILLI JSON AUTO-TRADE YAZICI ---')

if start != -1 and end != -1:
    old_block = text[start:end]
    new_block = """   msg += "--- 🧭 BEKLENTİ ---\\n";
   msg += range_text + "\\n";

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush) SendNotification(msg);

"""
    text = text[:start] + new_block + text[end:]

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
