with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Strip redundant Alerts as previously asked
text = text.replace('if(InpAlertPopup) Alert(msg);', '')
text = text.replace('if(InpAlertPush) SendNotification(msg);', '')
# Only inside `EvaluateTradeSignal` we want the alert. We can manually restore it there.

# Wait, instead of generic replace, I can just use my regex block
import re

text = re.sub(r'(string msg = "🔴 \[" \+ Symbol\(\) \+ "\] " \+ EnumToString\(Period\(\)\) \+ " Trend Döndü! \(CHoCH\)\\n";.*?)if \(InpEnableAlertCHoCHBase && draw_ui\) \{\n                  if\(InpAlertPopup\) Alert\(msg\);\n                  if\(InpAlertPush\) SendNotification\(msg\);\n                  \}', r'\1// Removed simple CHoCH alert to avoid duplicate notifications', text, flags=re.DOTALL)

text = re.sub(r'(string msg = "🟢 \[" \+ Symbol\(\) \+ "\] " \+ EnumToString\(Period\(\)\) \+ " Trend Döndü! \(CHoCH\)\\n";.*?)if \(InpEnableAlertCHoCHBase && draw_ui\) \{\n                  if\(InpAlertPopup\) Alert\(msg\);\n                  if\(InpAlertPush\) SendNotification\(msg\);\n                  \}', r'\1// Removed simple CHoCH alert to avoid duplicate notifications', text, flags=re.DOTALL)

text = re.sub(r'(string trend_msg = "🚨 \[" \+ Symbol\(\) \+ "\] M1 Trend Döndü! Yeni Yön: " \+ new_dir;\n                   )if\(InpAlertPopup\) Alert\(trend_msg\);\n                   if\(InpAlertPush\)  SendNotification\(trend_msg\);', r'\1// Removed simple Trend alert to avoid duplicate notifications', text, flags=re.DOTALL)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
