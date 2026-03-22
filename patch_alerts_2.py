import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Bearish Update
search_bear_msg = """              string msg = "🔴 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: AŞAĞI\\n";
              if (is_strong) {
                  msg += "Kırılım Tipi: 🔥 GÜÇLÜ (Tepe Likiditesi Alındı)\\n";
                  msg += "Detay: Fiyat, son tepe noktasının üstüne çıkarak likiditeyi topladı ve desteği aşağı kırdı.";
              } else {
                  msg += "Kırılım Tipi: ⚠️ ZAYIF (Tepe Likiditesi ALINAMADI)\\n";
                  msg += "Detay: Fiyat, son tepe noktasına ulaşamadan erken döndü ve desteği aşağı kırdı. Satış baskısı kısıtlı olabilir.";
              }"""

replace_bear_msg = """              string msg = "🔴 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬇️ AŞAĞI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.";
              }"""

content = content.replace(search_bear_msg, replace_bear_msg)

# Bullish Update
search_bull_msg = """              string msg = "🟢 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: YUKARI\\n";
              if (is_strong) {
                  msg += "Kırılım Tipi: 🔥 GÜÇLÜ (Dip Likiditesi Alındı)\\n";
                  msg += "Detay: Fiyat, son dip noktasının altına sarkarak likiditeyi topladı ve direnci yukarı kırdı.";
              } else {
                  msg += "Kırılım Tipi: ⚠️ ZAYIF (Dip Likiditesi ALINAMADI)\\n";
                  msg += "Detay: Fiyat, son dip noktasına ulaşamadan erken döndü ve direnci yukarı kırdı. Momentum yetersiz olabilir.";
              }"""

replace_bull_msg = """              string msg = "🟢 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬆️ YUKARI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.";
              }"""

content = content.replace(search_bull_msg, replace_bull_msg)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Alert messages simplified")
