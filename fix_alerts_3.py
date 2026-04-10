with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# My regex might have missed again if there are \n instead of \\n.
# Let's write a python script to blindly search line by line and remove the `Alert` and `SendNotification` inside the `if (!is_history && (!InpShowChoch || is_line_drawn)) {` blocks.
import re

# Remove `Trend Döndü! (CHoCH)` block entirely.
text = re.sub(r'              string msg = "🔴 \[" \+ Symbol\(\) \+ "\] " \+ EnumToString\(Period\(\)\) \+ " Trend Döndü! \(CHoCH\)\\n";.*?if\(InpAlertPush\) SendNotification\(msg\);\n                  \}', '', text, flags=re.DOTALL)
text = re.sub(r'              string msg = "🟢 \[" \+ Symbol\(\) \+ "\] " \+ EnumToString\(Period\(\)\) \+ " Trend Döndü! \(CHoCH\)\\n";.*?if\(InpAlertPush\) SendNotification\(msg\);\n                  \}', '', text, flags=re.DOTALL)

# Because there was a previous PR where I had literally `Trend Döndü! (CHoCH)\n`. Let's match `\n` too.
text = re.sub(r'              string msg = "🔴 \[" \+ Symbol\(\) \+ "\] " \+ EnumToString\(Period\(\)\) \+ " Trend Döndü! \(CHoCH\)\n";.*?if\(InpAlertPush\) SendNotification\(msg\);\n                  \}', '', text, flags=re.DOTALL)
text = re.sub(r'              string msg = "🟢 \[" \+ Symbol\(\) \+ "\] " \+ EnumToString\(Period\(\)\) \+ " Trend Döndü! \(CHoCH\)\n";.*?if\(InpAlertPush\) SendNotification\(msg\);\n                  \}', '', text, flags=re.DOTALL)

text = re.sub(r'                   string trend_msg = "🚨 \[" \+ Symbol\(\) \+ "\] M1 Trend Döndü! Yeni Yön: " \+ new_dir;\n                   if\(InpAlertPopup\) Alert\(trend_msg\);\n                   if\(InpAlertPush\)  SendNotification\(trend_msg\);', '', text, flags=re.DOTALL)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
