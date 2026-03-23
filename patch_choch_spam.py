import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Bearish notification fix
search_bear = """              string msg = "🔴 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬇️ AŞAĞI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.";
              }
              if(InpAlertPopup) Alert(msg);
              if(InpAlertPush) SendNotification(msg);"""

replace_bear = """              string msg = "🔴 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬇️ AŞAĞI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.";
              }

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {
                  if(InpAlertPopup) Alert(msg);
                  if(InpAlertPush) SendNotification(msg);
                  last_alert_d1_i_bear = state.d1_i;
              }"""

content = content.replace(search_bear, replace_bear)

# Bullish notification fix
search_bull = """              string msg = "🟢 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬆️ YUKARI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.";
              }
              if(InpAlertPopup) Alert(msg);
              if(InpAlertPush) SendNotification(msg);"""

replace_bull = """              string msg = "🟢 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬆️ YUKARI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.";
              }

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {
                  if(InpAlertPopup) Alert(msg);
                  if(InpAlertPush) SendNotification(msg);
                  last_alert_d1_i_bull = state.d1_i;
              }"""

content = content.replace(search_bull, replace_bull)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Spam fix applied")
