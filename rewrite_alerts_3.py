with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# My fix_alerts.py script logic to replace EvaluateTradeSignal block might have missed the target because of regex matching over newlines.
# Let's do it manually.

start_eval = text.find('   int total_points = 0;')
end_eval = text.find('   // --- YENİ AKILLI JSON AUTO-TRADE YAZICI ---', start_eval)

if start_eval != -1 and end_eval != -1:
    new_eval_block = """   int total_points = 0;
   string h1_text = "";
   string m30_text = "";
   string m15_text = "";
   string m5_text = "";
   string m1_text = "";

   // --- 1. M1 TETİK PUANLAMASI (Maks. 5 Puan) ---
   int m1_points = is_strong ? 5 : 0;
   total_points += m1_points;
   if(is_strong) m1_text = "  └ 💎 Durum: 🔥 GÜÇLÜ (Likidite Süpürüldü) -> [+5 Puan]\\n";
   else          m1_text = "  └ 💎 Durum: ⚠️ ZAYIF (Süpürme Yok, Direkt Kırılım) -> [+0 Puan]\\n";

   // --- 2. H1 MAKRO PUANLAMASI (Maks. 35 Puan) ---
   int h1_points = 0;
   double h1_bounce = mp_h1 - p_h1;
   bool h1_mom_20 = (h1_bounce >= 20.0);
   bool h1_mom_15 = (h1_bounce >= 15.0);
   bool is_h1_aligned = (t_h1 == trigger_dir);
   bool h1_is_premium = (p_h1 >= 50.0);
   string h1_dir_emoji = (t_h1 == 1) ? "🟢 YUKARI" : "🔴 AŞAĞI";
   string stats_h1 = "[Maks Çekilme: %" + DoubleToString(mp_h1, 2) + " | Anlık: %" + DoubleToString(p_h1, 2) + "]\\n";

   if (h1_mom_15) {
       if (is_h1_aligned) {
           if (h1_mom_20) { h1_points = 35; h1_text = h1_dir_emoji + " " + stats_h1 + "  └ 🚀 Yön Uyumlu, Çok Sert Dönüş (≥ %20 Momentum) -> [+35 Puan]\\n"; }
           else           { h1_points = 30; h1_text = h1_dir_emoji + " " + stats_h1 + "  └ 🚀 Yön Uyumlu, Sert Dönüş (≥ %15 Momentum) -> [+30 Puan]\\n"; }
       } else {
           h1_points = 0; h1_text = h1_dir_emoji + " " + stats_h1 + "  └ 🛑 Sert Dönüş Var AMA Yöne TERS (Tuzak İhtimali) -> [0 Puan]\\n";
       }
   } else {
       if (is_h1_aligned) {
           if (h1_is_premium) { h1_points = 30; h1_text = h1_dir_emoji + " " + stats_h1 + "  └ 🎯 %50 Premium Bölgesinde ve Yön Uyumlu -> [+30 Puan]\\n"; }
           else               { h1_points = 10; h1_text = h1_dir_emoji + " " + stats_h1 + "  └ ⚠️ Şişkin Piyasa (<%50) AMA Yön Uyumlu (Zayıf Filtre) -> [+10 Puan]\\n"; }
       } else {
           if (h1_is_premium) { h1_points = 20; h1_text = h1_dir_emoji + " " + stats_h1 + "  └ 📉 %50 Premium'da, Bize Ters AMA Momentum Yok -> [+20 Puan]\\n"; }
           else               { h1_points = 30; h1_text = h1_dir_emoji + " " + stats_h1 + "  └ 📉 Şişkin Piyasa, Bize Ters (Düzeltme Yeni Başlıyor) -> [+30 Puan]\\n"; }
       }
   }
   total_points += h1_points;

   // --- 3. M30 MAKRO PUANLAMASI (Maks. 25 Puan) ---
   int m30_points = 0;
   double m30_bounce = mp_m30 - p_m30;
   bool m30_mom_20 = (m30_bounce >= 20.0);
   bool m30_mom_15 = (m30_bounce >= 15.0);
   bool is_m30_aligned = (t_m30 == trigger_dir);
   bool m30_is_premium = (p_m30 >= 50.0);
   bool is_m30_duplicate = (MathAbs(h_m30 - h_h1) < Point() * 5 && MathAbs(l_m30 - l_h1) < Point() * 5);
   string m30_dir_emoji = (t_m30 == 1) ? "🟢 YUKARI" : "🔴 AŞAĞI";
   string stats_m30 = "[Maks Çekilme: %" + DoubleToString(mp_m30, 2) + " | Anlık: %" + DoubleToString(p_m30, 2) + "]\\n";

   if (is_m30_duplicate) {
       m30_points = 0; m30_text = "⚪ M30 (H1 ile Birebir Aynı, Klon Engelleme) -> [0 Puan]\\n";
   } else {
       if (!is_m30_aligned) {
           if (m30_mom_15) { m30_points = 0;  m30_text = m30_dir_emoji + " " + stats_m30 + "  └ 🛑 Bize Karşı %15 Momentum Var (Büyük Tehlike) -> [0 Puan]\\n"; }
           else            { m30_points = 10; m30_text = m30_dir_emoji + " " + stats_m30 + "  └ 📉 İvme Yok, Ters Yön Ufak Destek -> [+10 Puan]\\n"; }
       } else {
           if (m30_mom_20)      { m30_points = 25; m30_text = m30_dir_emoji + " " + stats_m30 + "  └ 🚀 Yön Uyumlu, ÇOK SERT (%20) Momentum -> [+25 Puan]\\n"; }
           else if (m30_mom_15) { m30_points = 20; m30_text = m30_dir_emoji + " " + stats_m30 + "  └ 🚀 Yön Uyumlu, SERT (%15) Momentum -> [+20 Puan]\\n"; }
           else {
               if (m30_is_premium) { m30_points = 15; m30_text = m30_dir_emoji + " " + stats_m30 + "  └ 🎯 Yön Uyumlu, %50 Premium, İvme Yok -> [+15 Puan]\\n"; }
               else                { m30_points = 5;  m30_text = m30_dir_emoji + " " + stats_m30 + "  └ ⚠️ Yön Uyumlu, %50 Altında (Zayıf Filtre) -> [+5 Puan]\\n"; }
           }
       }
   }
   total_points += m30_points;

   // --- 4. M15 MAKRO PUANLAMASI (Maks. 20 Puan) ---
   int m15_points = 0;
   double m15_bounce = mp_m15 - p_m15;
   bool m15_mom_20 = (m15_bounce >= 20.0);
   bool m15_mom_15 = (m15_bounce >= 15.0);
   bool is_m15_aligned = (t_m15 == trigger_dir);
   bool m15_is_premium = (p_m15 >= 50.0);
   bool is_m15_duplicate = (MathAbs(h_m15 - h_m30) < Point() * 5 && MathAbs(l_m15 - l_m30) < Point() * 5);
   string m15_dir_emoji = (t_m15 == 1) ? "🟢 YUKARI" : "🔴 AŞAĞI";
   string stats_m15 = "[Maks Çekilme: %" + DoubleToString(mp_m15, 2) + " | Anlık: %" + DoubleToString(p_m15, 2) + "]\\n";

   if (is_m15_duplicate) {
       m15_points = 0; m15_text = "⚪ M15 (M30 ile Birebir Aynı, Klon Engelleme) -> [0 Puan]\\n";
   } else {
       if (!is_m15_aligned) {
           if (m15_mom_15) { m15_points = 0; m15_text = m15_dir_emoji + " " + stats_m15 + "  └ 🛑 Bize Karşı %15 Momentum Var (Reddedildi) -> [0 Puan]\\n"; }
           else            { m15_points = 5; m15_text = m15_dir_emoji + " " + stats_m15 + "  └ 📉 Bize Karşı İvme Yok (Ufak Marj) -> [+5 Puan]\\n"; }
       } else {
           if (m15_mom_20)      { m15_points = 20; m15_text = m15_dir_emoji + " " + stats_m15 + "  └ 🚀 Yön Uyumlu, ÇOK SERT (%20) Momentum -> [+20 Puan]\\n"; }
           else if (m15_mom_15) { m15_points = 15; m15_text = m15_dir_emoji + " " + stats_m15 + "  └ 🚀 Yön Uyumlu, SERT (%15) Momentum -> [+15 Puan]\\n"; }
           else {
               if (m15_is_premium) { m15_points = 15; m15_text = m15_dir_emoji + " " + stats_m15 + "  └ 🎯 Yön Uyumlu, Premium Bölgede -> [+15 Puan]\\n"; }
               else                { m15_points = 5;  m15_text = m15_dir_emoji + " " + stats_m15 + "  └ ⚠️ Yön Uyumlu, %50 Altı (Zayıf Filtre) -> [+5 Puan]\\n"; }
           }
       }
   }
   total_points += m15_points;

   // --- 5. M5 MİKRO FİLTRE (Maks. 15 Puan) ---
   int m5_points = 0;
   double m5_bounce = mp_m5 - p_m5;
   bool m5_mom_20 = (m5_bounce >= 20.0);
   bool m5_mom_15 = (m5_bounce >= 15.0);
   bool is_m5_aligned = (t_m5 == trigger_dir);
   bool m5_is_premium = (p_m5 >= 50.0);
   bool is_m5_duplicate = (MathAbs(h_m5 - h_m15) < Point() * 5 && MathAbs(l_m5 - l_m15) < Point() * 5);
   string m5_dir_emoji = (t_m5 == 1) ? "🟢 YUKARI" : "🔴 AŞAĞI";
   string stats_m5 = "[Maks Çekilme: %" + DoubleToString(mp_m5, 2) + " | Anlık: %" + DoubleToString(p_m5, 2) + "]\\n";

   if (is_m5_duplicate) {
       m5_points = 0; m5_text = "⚪ M5 (M15 ile Birebir Aynı, Klon Engelleme) -> [0 Puan]\\n";
   } else {
       if (!is_m5_aligned) {
           if (m5_mom_15) { m5_points = 0; m5_text = m5_dir_emoji + " " + stats_m5 + "  └ 🛑 Bize Karşı %15 Momentum Var (Reddedildi) -> [0 Puan]\\n"; }
           else           { m5_points = 5; m5_text = m5_dir_emoji + " " + stats_m5 + "  └ 📉 İvme Yok (Ufak Marj Desteği) -> [+5 Puan]\\n"; }
       } else {
           if (m5_mom_20)      { m5_points = 15; m5_text = m5_dir_emoji + " " + stats_m5 + "  └ 🚀 Yön Uyumlu, ÇOK SERT (%20) Momentum -> [+15 Puan]\\n"; }
           else if (m5_mom_15) { m5_points = 10; m5_text = m5_dir_emoji + " " + stats_m5 + "  └ 🚀 Yön Uyumlu, SERT (%15) Momentum -> [+10 Puan]\\n"; }
           else {
               if (m5_is_premium) { m5_points = 10; m5_text = m5_dir_emoji + " " + stats_m5 + "  └ 🎯 Yön Uyumlu, Premium Bölgede -> [+10 Puan]\\n"; }
               else               { m5_points = 5;  m5_text = m5_dir_emoji + " " + stats_m5 + "  └ ⚠️ Yön Uyumlu, %50 Altı (Zayıf Filtre) -> [+5 Puan]\\n"; }
           }
       }
   }
   total_points += m5_points;

   string range_text = (t_m1 == t_m3) ? "🚀 UZUN MENZİL (Trend Takibi)" : "⚠️ KISA MENZİL (Scalp/Tepki)";
   string lvl_text = "BİLİNMİYOR";
   if (p_pct >= 40.0 && p_pct < 60.0) lvl_text = "KIRILIM 1 (Erken Seviye)";
   if (p_pct >= 60.0) lvl_text = "KIRILIM 2 (Ana Seviye)";

   string verdict = "";
   if (total_points >= InpMinTradeScoreLimit) verdict = "✅ İŞLEME GİRİLEBİLİR (Skor Yeterli)";
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Skor Yetersiz)";

   string dir_str = (trigger_dir == 1) ? "BUY" : "SELL";
   string dir_emoji = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";

   string msg = "";
   if (is_test) msg = "🧪 [" + Symbol() + "] TEST DETAYLI ANALİZ RAPORU\\n";
   else         msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\\n";

   msg += "🎯 Yön: " + dir_emoji + "\\n";
   msg += "📊 Karar: " + verdict + "\\n";
   msg += "📈 TOPLAM SKOR: " + IntegerToString(total_points) + " / 100 (Baraj: " + IntegerToString(InpMinTradeScoreLimit) + ")\\n\\n";

   msg += "--- ⏳ M1 (Ana Tetikleyici) ---\\n";
   msg += m1_text;
   msg += "--- ⏳ H1 (Makro Trend) ---\\n";
   msg += h1_text;
   msg += "--- ⏳ M30 (Makro Trend) ---\\n";
   msg += m30_text;
   msg += "--- ⏳ M15 (Makro Yapı) ---\\n";
   msg += m15_text;
   msg += "--- ⏳ M5 (Mikro Filtre) ---\\n";
   msg += m5_text;
   msg += "--- 🧭 BEKLENTİ ---\\n";
   msg += range_text + "\\n";

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush) SendNotification(msg);

"""
    text = text[:start_eval] + new_eval_block + text[end_eval:]

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
