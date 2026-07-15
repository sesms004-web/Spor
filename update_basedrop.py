import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Update InpBigCandleMult to 3.0 and add InpMaxWickPct
inp_old = """input double InpBigCandleMult = 2.0; // Şiddetli Mum Çarpanı
input int    InpBaseMaxCandles = 5;  // Maksimum Ufak Mum (Base) Sayısı
input int    InpBaseAvgLookback = 10; // Ortalama Gövde Bakma Süresi"""

inp_new = """input double InpBigCandleMult = 3.0; // Şiddetli Mum Çarpanı
input double InpMaxWickPct    = 20.0; // Kırılım Yönündeki Fitil Oranı (%)
input int    InpBaseMaxCandles = 5;  // Maksimum Ufak Mum (Base) Sayısı
input int    InpBaseAvgLookback = 10; // Ortalama Gövde Bakma Süresi"""

content = content.replace(inp_old, inp_new)


# Update CheckBaseDropBox logic
# Find: if(cur_body > avg_body * InpBigCandleMult) {
# Replace with wick check included
check_old = """   // Check if current candle is a "Big Violent Candle"
   if(cur_body > avg_body * InpBigCandleMult) {
      bool is_bullish = close[i] > open[i];"""

check_new = """   // Check if current candle is a "Big Violent Candle"
   if(cur_body > avg_body * InpBigCandleMult) {
      bool is_bullish = close[i] > open[i];

      // Fitilsiz direkt gitme kontrolü (Wickless condition)
      double wick_len = is_bullish ? (high[i] - close[i]) : (close[i] - low[i]);
      if (wick_len > cur_body * (InpMaxWickPct / 100.0)) return; // Yönündeki fitil çok uzunsa iptal
"""

content = content.replace(check_old, check_new)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
