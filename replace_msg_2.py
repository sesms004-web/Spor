import re
with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the text formatting block
old_msg = r"""   msg \+= "🔍 M1 KIRILIM KALİTESİ:\\n" \+ m1_text \+ "\\n";
   msg \+= "📊 ZAMAN DİLİMİ ANALİZİ \(Ana Yön H1: " \+ \(t_h1==1\?"⬆️":"⬇️"\) \+ "\):\\n";
   msg \+= "\* " \+ h1_text;
   msg \+= "\* " \+ m30_text;
   msg \+= "\* " \+ m15_text;
   msg \+= "\* " \+ m5_text \+ "\\n";
   msg \+= "🎯 İŞLEM MENZİLİ \(M1 ve M3 Uyumu\):\n" \+ range_text \+ "\n\\n";
   msg \+= "📈 TOPLAM İŞLEM SKORU:\\n";
   msg \+= "Hesaplanan: " \+ IntegerToString\(total_points\) \+ " Skor \(Gerekli Baraj: " \+ IntegerToString\(InpMinTradeScoreLimit\) \+ " Skor\)\\n";
   msg \+= "KARAR: " \+ verdict;"""

new_msg = """   msg += "🔍 M1 (Ana Tetikleyici):\\n";
   msg += m1_text + "\\n";
   msg += "⏳ H1 (Makro Trend):\\n";
   msg += h1_text + "\\n";
   msg += "⏳ M30 (Makro Trend):\\n";
   msg += m30_text + "\\n";
   msg += "⏳ M15 (Makro Yapı):\\n";
   msg += m15_text + "\\n";
   msg += "⏳ M5 (Mikro Filtre):\\n";
   msg += m5_text + "\\n";
   msg += "🧭 BEKLENTİ:\\n";
   msg += range_text + "\\n\\n";
   msg += "📈 TOPLAM SKOR: " + IntegerToString(total_points) + " / 100 (Baraj: " + IntegerToString(InpMinTradeScoreLimit) + ")\\n";
   msg += "KARAR: " + verdict;"""

text = re.sub(old_msg, new_msg, text)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
