import re

with open('vol100.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix literal newlines in strings
# Let's just find the offending lines and fix them manually

content = content.replace('Trend Döndü! (CHoCH)\\\n";', 'Trend Döndü! (CHoCH)\\n";')
content = content.replace('Yön: ⬇️ AŞAĞI\\\n";', 'Yön: ⬇️ AŞAĞI\\n";')
content = content.replace('Yön: ⬆️ YUKARI\\\n";', 'Yön: ⬆️ YUKARI\\n";')
content = content.replace('Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.\\\n";', 'Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.\\n";')
content = content.replace('Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.\\\n";', 'Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.\\n";')
content = content.replace('Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.\\\n";', 'Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.\\n";')
content = content.replace('Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.\\\n";', 'Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.\\n";')
content = content.replace('(Kırılım: %" + DoubleToString(break_pct, 2) + ")\\\n";', '(Kırılım: %" + DoubleToString(break_pct, 2) + ")\\n";')

# Let's just run a generic replace for the actual strings I injected:
old_bear = """              string msg = "🔴 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬇️ AŞAĞI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.\\n";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.\\n";
              }

              msg += "Çekilme: %" + DoubleToString(ext_pct, 2) + " (Kırılım: %" + DoubleToString(break_pct, 2) + ")\\n";"""

new_bear = """              string msg = "🔴 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬇️ AŞAĞI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.\\n";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.\\n";
              }

              msg += "Çekilme: %" + DoubleToString(ext_pct, 2) + " (Kırılım: %" + DoubleToString(break_pct, 2) + ")\\n";"""

# Python's re might have escaped the \n into literal newlines during replacement.
# Let's fix it universally by searching for strings that end with a real newline before the quote.
content = re.sub(r'\\n"\n\s*;', r'\\n";', content)

# A more robust fix: The code review complained about:
# string msg = "🔴 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)
# ";
# This happens when \n inside python string is parsed as actual newline.
# Let's use pure string replacement to fix any broken lines.

content = re.sub(r'Trend Döndü! \(CHoCH\)\n\s*";', r'Trend Döndü! (CHoCH)\\n";', content)
content = re.sub(r'Yön: ⬇️ AŞAĞI\n\s*";', r'Yön: ⬇️ AŞAĞI\\n";', content)
content = re.sub(r'Yön: ⬆️ YUKARI\n\s*";', r'Yön: ⬆️ YUKARI\\n";', content)
content = re.sub(r'likiditesi alındı\.\n\s*";', r'likiditesi alındı.\\n";', content)
content = re.sub(r'likiditesi alınamadı\.\n\s*";', r'likiditesi alınamadı.\\n";', content)
content = re.sub(r'DoubleToString\(break_pct, 2\) \+ "\)\n\s*";', r'DoubleToString(break_pct, 2) + ")\\n";', content)

with open('vol100.mq5', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed literal newlines inside strings.")
