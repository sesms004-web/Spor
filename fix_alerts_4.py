with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Make sure `EvaluateTradeSignal` gets its Alerts. I saw I removed all `if(InpAlertPopup) Alert(msg);` earlier globally which I shouldn't have.
# Let's restore it in EvaluateTradeSignal
if "if(InpAlertPopup) Alert(msg);" not in text:
    text = text.replace('   if(InpAlertPush) SendNotification(msg);', '   if(InpAlertPopup) Alert(msg);\n   if(InpAlertPush) SendNotification(msg);')
    text = text.replace('   if(InpAlertPopup) Alert(msg);\n   if(InpAlertPopup) Alert(msg);\n   if(InpAlertPush) SendNotification(msg);', '   if(InpAlertPopup) Alert(msg);\n   if(InpAlertPush) SendNotification(msg);')

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
