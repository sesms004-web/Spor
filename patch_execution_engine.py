import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Define the new massive EvaluateTradeSignal function just before TriggerMTFAlert
search_target = """//+------------------------------------------------------------------+
//| MTF Alert System (Smart Algorithmic Decision Engine)             |
//+------------------------------------------------------------------+"""

engine_code = """//+------------------------------------------------------------------+
//| 50-Point Execution Analysis Engine                               |
//+------------------------------------------------------------------+
void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong)
  {
   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double dmy_h, dmy_l; datetime dmy_th, dmy_tl, th_m15, tl_m15, th_m30, tl_m30;

   // We need MTF data to evaluate the matrix
   GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, dmy_h, dmy_l, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, dmy_h, dmy_l, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M5, t_m5, p_m5, mp_m5, t, dmy_h, dmy_l, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, dmy_h, dmy_l, th_m15, tl_m15);
   GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, dmy_h, dmy_l, th_m30, tl_m30);
   GetMTFPullback(PERIOD_H1, t_h1, p_h1, mp_h1, t, dmy_h, dmy_l, dmy_th, dmy_tl);

   int total_points = 0;
   string h1_text = "";
   string m30_text = "";
   string m15_text = "";
   string m5_text = "";
   string m1_text = "";

   // --- M1 BASE SETUP ---
   int m1_points = is_strong ? 5 : 0;
   total_points += m1_points;
   if(is_strong) m1_text = "Durum: 🔥 GÜÇLÜ (Likidite Alındı) -> [+5 Puan]\\n";
   else          m1_text = "Durum: ⚠️ ZAYIF (Likidite Alınamadı) -> [+0 Puan]\\n";

   // --- H1 MACRO LOGIC ---
   int h1_points = 0;
   bool h1_momentum = ((mp_h1 - p_h1) >= 20.0);
   bool is_h1_aligned = (t_h1 == trigger_dir);

   if (h1_momentum) {
       if (is_h1_aligned) { h1_points = 40; h1_text = "H1 (Makro): Sert Momentum Dönüşü (Trend Onayı) -> [+40 Puan]\\n"; }
       else               { h1_points = 0;  h1_text = "H1 (Makro): Ters Yönde Sert Momentum (Tehlike!) -> [0 Puan]\\n"; }
   } else {
       if (p_h1 >= 50.0) { // Premium
           if (is_h1_aligned) { h1_points = 40; h1_text = "H1 (Makro): İdeal Pahalı/Ucuz Bölgesinde (Altın Vuruş) -> [+40 Puan]\\n"; }
           else               { h1_points = 20; h1_text = "H1 (Makro): İdeal Bölgede ama Ters Yön (Son İtiş) -> [+20 Puan]\\n"; }
       } else { // Discount
           if (is_h1_aligned) { h1_points = 0;  h1_text = "H1 (Makro): Trend Yönünde ama Fiyat Erken/Zayıf -> [0 Puan]\\n"; }
           else               { h1_points = 40; h1_text = "H1 (Makro): Yeni Düzeltme Başlıyor (Önü Açık) -> [+40 Puan]\\n"; }
       }
   }
   total_points += h1_points;

   // --- M30 MODIFIER LOGIC ---
   int m30_points = 0;
   bool m30_momentum = ((mp_m30 - p_m30) >= 20.0);
   bool is_m30_aligned = (t_m30 == trigger_dir);

   if (m30_momentum) {
       if (is_m30_aligned) { m30_points = 15; m30_text = "M30 (Ara Filtre): Sert Momentum Desteği -> [+15 Puan]\\n"; }
       else                { m30_points = -5; m30_text = "M30 (Ara Filtre): Ters Yönlü Sert Çekilme (Engel) -> [-5 Puan]\\n"; }
   } else {
       if (p_m30 >= 50.0) {
           if (is_m30_aligned) { m30_points = 10;  m30_text = "M30 (Ara Filtre): Şişkin Bölgede Destekliyor -> [+10 Puan]\\n"; }
           else                { m30_points = -10; m30_text = "M30 (Ara Filtre): Şişkin Bölgede Direnç (Ters) -> [-10 Puan]\\n"; }
       } else {
           if (is_m30_aligned) { m30_points = 10;  m30_text = "M30 (Ara Filtre): Yolun Başında Destekliyor -> [+10 Puan]\\n"; }
           else                { m30_points = 10;  m30_text = "M30 (Ara Filtre): Sağlıklı Düzeltme Yapıyor (Olumlu) -> [+10 Puan]\\n"; }
       }
   }
   total_points += m30_points;

   // --- M15 MODIFIER LOGIC (De-duplication) ---
   int m15_points = 0;
   bool m15_momentum = ((mp_m15 - p_m15) >= 20.0);
   bool is_m15_aligned = (t_m15 == trigger_dir);
   bool is_duplicate = (th_m15 == th_m30 && tl_m15 == tl_m30); // Same swing anchor

   if (is_duplicate) {
       m15_points = 0; m15_text = "M15 (Ara Filtre): M30 ile aynı dalga, pas geçildi. -> [0 Puan]\\n";
   } else {
       if (m15_momentum) {
           if (is_m15_aligned) { m15_points = 10; m15_text = "M15 (Ara Filtre): Sert Momentum Desteği -> [+10 Puan]\\n"; }
           else                { m15_points = 0;  m15_text = "M15 (Ara Filtre): Ters Yönlü İvme (Zayıf Etki) -> [0 Puan]\\n"; }
       } else {
           if (p_m15 >= 50.0) {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15 (Ara Filtre): Şişkin Bölgede Destekliyor -> [+5 Puan]\\n"; }
               else                { m15_points = -5; m15_text = "M15 (Ara Filtre): Şişkin Bölgede Direnç (Ters) -> [-5 Puan]\\n"; }
           } else {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15 (Ara Filtre): Yolun Başında Destekliyor -> [+5 Puan]\\n"; }
               else                { m15_points = 5;  m15_text = "M15 (Ara Filtre): Sağlıklı Düzeltme Yapıyor -> [+5 Puan]\\n"; }
           }
       }
   }
   total_points += m15_points;

   // --- M5 MODIFIER LOGIC ---
   int m5_points = 0;
   bool is_m5_aligned = (t_m5 == trigger_dir);
   if (is_m5_aligned && p_m5 >= 50.0) {
       m5_points = 5; m5_text = "M5 (Mikro Filtre): Derin Çekilme Onayı -> [+5 Puan]\\n";
   } else {
       m5_points = 0; m5_text = "M5 (Mikro Filtre): Çekilme Onayı Yok -> [0 Puan]\\n";
   }
   total_points += m5_points;

   // --- M1 vs M3 RANGE EXPECTATION ---
   string range_text = (t_m1 == t_m3) ? "🚀 BEKLENTİ: UZUN MENZİL (Trend Takibi)" : "⚠️ BEKLENTİ: KISA SÜRECEK (Scalp/Tepki)";

   // --- BREAKOUT LEVEL PHASING ---
   string lvl_text = "BİLİNMİYOR";
   if (p_pct >= 40.0 && p_pct < 60.0) lvl_text = "KIRILIM 1 (Erken Seviye)";
   if (p_pct >= 60.0) lvl_text = "KIRILIM 2 (Ana Seviye)";

   // --- FINAL VERDICT ---
   string verdict = "";
   if (total_points >= 50) verdict = "✅ İŞLEME GİRİLEBİLİR (Yüksek Olasılıklı Kurulum)";
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Puan Yetersiz)";

   string dir_str = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";

   string msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\\n";
   msg += "Yön: " + dir_str + "\\n\\n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\\n" + m1_text + "\\n";
   msg += "📊 ZAMAN DİLİMİ ANALİZİ (Ana Yön H1: " + (t_h1==1?"⬆️":"⬇️") + "):\\n";
   msg += "* " + h1_text;
   msg += "* " + m30_text;
   msg += "* " + m15_text;
   msg += "* " + m5_text + "\\n";
   msg += "🎯 İŞLEM MENZİLİ (M1 ve M3 Uyumu):\\n" + range_text + "\\n\\n";
   msg += "📈 TOPLAM İŞLEM SKORU:\\n";
   msg += "Hesaplanan: " + IntegerToString(total_points) + " Puan (Gerekli Baraj: 50 Puan)\\n";
   msg += "KARAR: " + verdict;

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush) SendNotification(msg);
  }

//+------------------------------------------------------------------+
//| MTF Alert System (Smart Algorithmic Decision Engine)             |
//+------------------------------------------------------------------+"""

content = content.replace(search_target, engine_code)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Engine injected")
