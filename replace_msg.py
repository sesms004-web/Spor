with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

start = text.find('   msg += "🔍 M1 KIRILIM KALİTESİ:\\n" + m1_text + "\\n";')
end = text.find('   msg += "KARAR: " + verdict;')

if start != -1 and end != -1:
    new_msg = """   msg += "--- ⏳ M1 (Ana Tetikleyici) ---\\n";
   msg += m1_text + "\\n";
   msg += "--- ⏳ H1 (Makro Trend) ---\\n";
   msg += "H1: " + h1_text + "\\n";
   msg += "--- ⏳ M30 (Makro Trend) ---\\n";
   msg += "M30: " + m30_text + "\\n";
   msg += "--- ⏳ M15 (Makro Yapı) ---\\n";
   msg += "M15: " + m15_text + "\\n";
   msg += "--- ⏳ M5 (Mikro Filtre) ---\\n";
   msg += "M5: " + m5_text + "\\n";
   msg += "--- 🧭 BEKLENTİ ---\\n";
   msg += range_text + "\\n\\n";
   msg += "KARAR: " + verdict;
"""
    # actually I will replace lines manually.
