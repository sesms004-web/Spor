with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's find the exact text
start = text.find('   msg += "🔍 M1 KIRILIM KALİTESİ:\\n" + m1_text + "\\n";')
end = text.find('   msg += "KARAR: " + verdict;') + len('   msg += "KARAR: " + verdict;')

if start != -1 and end != -1:
    new_msg = """   msg += "--- 🔍 M1 (Ana Tetikleyici) ---\\n";
   msg += m1_text + "\\n";
   msg += "--- ⏳ H1 (Makro Trend) ---\\n";
   msg += h1_text + "\\n";
   msg += "--- ⏳ M30 (Makro Trend) ---\\n";
   msg += m30_text + "\\n";
   msg += "--- ⏳ M15 (Makro Yapı) ---\\n";
   msg += m15_text + "\\n";
   msg += "--- ⏳ M5 (Mikro Filtre) ---\\n";
   msg += m5_text + "\\n";
   msg += "--- 🧭 BEKLENTİ ---\\n";
   msg += range_text + "\\n\\n";
   msg += "📈 SKOR: " + IntegerToString(total_points) + " (Baraj: " + IntegerToString(InpMinTradeScoreLimit) + ")\\n";
   msg += "KARAR: " + verdict;"""
    text = text[:start] + new_msg + text[end:]

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
