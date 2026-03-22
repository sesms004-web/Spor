import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Bearish Trigger Block
search_bear_trig = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {
      if (val_c < state.d1_l) {
          // Bearish CHoCH confirmed!
          if (InpShowChoch) {"""

replace_bear_trig = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {
      if (val_c < state.d1_l) {
          // Bearish CHoCH confirmed!
          bool is_strong = (state.t2_h > state.t1_h); // T2 sweeps T1's high

          if (!is_history) {
              string msg = "🔴 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: AŞAĞI\\n";
              if (is_strong) {
                  msg += "Kırılım Tipi: 🔥 GÜÇLÜ (Tepe Likiditesi Alındı)\\n";
                  msg += "Detay: Fiyat, son tepe noktasının üstüne çıkarak likiditeyi topladı ve desteği aşağı kırdı.";
              } else {
                  msg += "Kırılım Tipi: ⚠️ ZAYIF (Tepe Likiditesi ALINAMADI)\\n";
                  msg += "Detay: Fiyat, son tepe noktasına ulaşamadan erken döndü ve desteği aşağı kırdı. Satış baskısı kısıtlı olabilir.";
              }
              if(InpAlertPopup) Alert(msg);
              if(InpAlertPush) SendNotification(msg);
          }

          if (InpShowChoch) {"""

content = content.replace(search_bear_trig, replace_bear_trig)

# Also need to fix where `bool is_strong` is declared inside InpShowChoch block to avoid redeclaration.
search_bear_strong = """              bool is_strong = (state.t2_h > state.t1_h); // T2 sweeps T1's high
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;"""

replace_bear_strong = """              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;"""

content = content.replace(search_bear_strong, replace_bear_strong)


# Bullish Trigger Block
search_bull_trig = """   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h) {
          // Bullish CHoCH confirmed!
          if (InpShowChoch) {"""

replace_bull_trig = """   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h) {
          // Bullish CHoCH confirmed!
          bool is_strong = (state.t2_l < state.t1_l); // T2 sweeps T1's low

          if (!is_history) {
              string msg = "🟢 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: YUKARI\\n";
              if (is_strong) {
                  msg += "Kırılım Tipi: 🔥 GÜÇLÜ (Dip Likiditesi Alındı)\\n";
                  msg += "Detay: Fiyat, son dip noktasının altına sarkarak likiditeyi topladı ve direnci yukarı kırdı.";
              } else {
                  msg += "Kırılım Tipi: ⚠️ ZAYIF (Dip Likiditesi ALINAMADI)\\n";
                  msg += "Detay: Fiyat, son dip noktasına ulaşamadan erken döndü ve direnci yukarı kırdı. Momentum yetersiz olabilir.";
              }
              if(InpAlertPopup) Alert(msg);
              if(InpAlertPush) SendNotification(msg);
          }

          if (InpShowChoch) {"""

content = content.replace(search_bull_trig, replace_bull_trig)

search_bull_strong = """              bool is_strong = (state.t2_l < state.t1_l); // T2 sweeps T1's low
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;"""

replace_bull_strong = """              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;"""

content = content.replace(search_bull_strong, replace_bull_strong)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Alerts logic patched")
