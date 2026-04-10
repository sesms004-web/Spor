import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's forcefully eliminate all redundant alerts using string replacement.
# 1. Bearish CHoCH alert
p1 = """              string msg = "🔴 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬇️ AŞAĞI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.\\n";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.\\n";
              }

              msg += "Çekilme: %" + DoubleToString(ext_pct, 2) + " (Kırılım: %" + DoubleToString(break_pct, 2) + ")\\n";

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {
                  if (InpEnableAlertCHoCHBase && draw_ui) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }"""
r1 = """              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {"""
text = text.replace(p1, r1)

# 2. Bullish CHoCH alert
p2 = """              string msg = "🟢 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬆️ YUKARI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.\\n";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.\\n";
              }

              msg += "Çekilme: %" + DoubleToString(ext_pct, 2) + " (Kırılım: %" + DoubleToString(break_pct, 2) + ")\\n";

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {
                  if (InpEnableAlertCHoCHBase && draw_ui) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }"""
r2 = """              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {"""
text = text.replace(p2, r2)

# 3. Main Trend alert
p3 = """               if (InpEnableAlertTrendChange) {
                   string new_dir = (g_state_hist.maj_tr == 1) ? "YUKARI" : "AŞAĞI";
                   string trend_msg = "🚨 [" + Symbol() + "] M1 Trend Döndü! Yeni Yön: " + new_dir;
                   if(InpAlertPopup) Alert(trend_msg);
                   if(InpAlertPush)  SendNotification(trend_msg);
               }"""
r3 = ""
text = text.replace(p3, r3)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
