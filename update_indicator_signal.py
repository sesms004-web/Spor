import re

with open('vol100.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add new Inputs for Auto-Trade Integration
alert_inputs = """//--- Alert Settings ---
input bool   InpEnableAlertTrendChange = true;       // Ana Trend (Kapanış) Dönüş Bildirimini Aç
input bool   InpEnableAlertCHoCHBase   = true;       // Temel CHoCH (Kırılım) Bildirimini Aç
input bool   InpEnableTradeExecution   = true;       // 50 Skorlık 'İşleme Gir' Analiz Sistemini Aç
input bool   InpTestTradeExecution     = false;      // 🧪 [TEST] Anlık Skorları Hesapla ve Bildir
input bool   InpAlertPopup       = true;
input bool   InpAlertPush        = false;"""

new_alert_inputs = """//--- Alert Settings ---
input bool   InpEnableAlertTrendChange = true;       // Ana Trend (Kapanış) Dönüş Bildirimini Aç
input bool   InpEnableAlertCHoCHBase   = true;       // Temel CHoCH (Kırılım) Bildirimini Aç
input bool   InpEnableTradeExecution   = true;       // Özel Skorluk 'İşleme Gir' Analiz Sistemini Aç
input int    InpMinTradeScore          = 30;         // Minimum İşleme Giriş Skoru (Varsayılan 30)
input bool   InpEnableAutoTradeWriter  = true;       // MT5 Ortak Klasöre Sinyal Dosyası Gönder (Auto-Trade EA için)
input int    InpMaxTradesPerSwing      = 2;          // Aynı Majör Dalga İçinde Maksimum Sinyal Sayısı
input bool   InpTestTradeExecution     = false;      // 🧪 [TEST] Anlık Skorları Hesapla ve Bildir
input bool   InpAlertPopup       = true;
input bool   InpAlertPush        = false;"""

content = content.replace(alert_inputs, new_alert_inputs)


# 2. Modify EvaluateTradeSignal signature and add Extreme variables tracking
eval_sig_old = "void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, bool is_test = false)"
eval_sig_new = "void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, double ext_pt, bool is_test = false)"
content = content.replace(eval_sig_old, eval_sig_new)

# Find calls to EvaluateTradeSignal and pass ext_pt (which is extreme_pt)
call1 = "EvaluateTradeSignal(i, time[i], val_c, -1, ext_pct, is_strong);"
call1_new = "EvaluateTradeSignal(i, time[i], val_c, -1, ext_pct, is_strong, extreme_pt);"
content = content.replace(call1, call1_new)

call2 = "EvaluateTradeSignal(i, time[i], val_c, 1, ext_pct, is_strong);"
call2_new = "EvaluateTradeSignal(i, time[i], val_c, 1, ext_pct, is_strong, extreme_pt);"
content = content.replace(call2, call2_new)

call_test = "EvaluateTradeSignal(last_idx, TimeCurrent(), bid, test_choch_dir, live_pct, true, true);"
call_test_new = "EvaluateTradeSignal(last_idx, TimeCurrent(), bid, test_choch_dir, live_pct, true, bid, true);"
content = content.replace(call_test, call_test_new)


# 3. Add Auto-Trade File Writer Logic at the end of EvaluateTradeSignal
# Search for final verdict and total points comparison

verdict_old = """   // --- FINAL VERDICT ---
   string verdict = "";
   if (total_points >= 50) verdict = "✅ İŞLEME GİRİLEBİLİR (Yüksek Olasılıklı Kurulum)";
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Skor Yetersiz)";

   string dir_str = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";

   string msg = "";
   if (is_test) msg = "🧪 [" + Symbol() + "] TEST ANALİZ RAPORU (Şu Anki Durum)\\n";
   else msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\\n";
   msg += "Yön: " + dir_str + "\\n\\n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\\n" + m1_text + "\\n";
   msg += "📊 ZAMAN DİLİMİ ANALİZİ (Ana Yön H1: " + (t_h1==1?"⬆️":"⬇️") + "):\\n";
   msg += "* " + h1_text;
   msg += "* " + m30_text;
   msg += "* " + m15_text;
   msg += "* " + m5_text + "\\n";
   msg += "🎯 İŞLEM MENZİLİ (M1 ve M3 Uyumu):\\n" + range_text + "\\n\\n";
   msg += "📈 TOPLAM İŞLEM SKORU:\\n";
   msg += "Hesaplanan: " + IntegerToString(total_points) + " Skor (Gerekli Baraj: 50 Skor)\\n";
   msg += "KARAR: " + verdict;

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush) SendNotification(msg);
  }"""

verdict_new = """   // --- FINAL VERDICT ---
   string verdict = "";
   if (total_points >= InpMinTradeScore) verdict = "✅ İŞLEME GİRİLEBİLİR (Skor Yeterli)";
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Skor Yetersiz)";

   string dir_str = (trigger_dir == 1) ? "BUY" : "SELL";
   string dir_emoji = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";

   string msg = "";
   if (is_test) msg = "🧪 [" + Symbol() + "] TEST ANALİZ RAPORU (Şu Anki Durum)\\n";
   else msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\\n";
   msg += "Yön: " + dir_emoji + "\\n\\n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\\n" + m1_text + "\\n";
   msg += "📊 ZAMAN DİLİMİ ANALİZİ (Ana Yön H1: " + (t_h1==1?"⬆️":"⬇️") + "):\\n";
   msg += "* " + h1_text;
   msg += "* " + m30_text;
   msg += "* " + m15_text;
   msg += "* " + m5_text + "\\n";
   msg += "🎯 İŞLEM MENZİLİ (M1 ve M3 Uyumu):\\n" + range_text + "\\n\\n";
   msg += "📈 TOPLAM İŞLEM SKORU:\\n";
   msg += "Hesaplanan: " + IntegerToString(total_points) + " Skor (Gerekli Baraj: " + IntegerToString(InpMinTradeScore) + " Skor)\\n";
   msg += "KARAR: " + verdict;

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush) SendNotification(msg);

   // --- AUTO-TRADE FILE WRITER LOGIC ---
   static int last_maj_i = -1;
   static int current_swing_trades = 0;

   // Yeni bir ana dalga (swing) oluştuğunda sayaçları sıfırla
   if (g_state_curr.maj_h_i != last_maj_i && g_state_curr.maj_l_i != last_maj_i) {
       current_swing_trades = 0;
       last_maj_i = (trigger_dir == 1) ? g_state_curr.maj_l_i : g_state_curr.maj_h_i;
   }

   if (total_points >= InpMinTradeScore && InpEnableAutoTradeWriter && !is_test) {
       if (current_swing_trades < InpMaxTradesPerSwing) {

           double sl = 0.0;
           double tp = 0.0;
           double entry = live_price;

           if (trigger_dir == 1) { // BUY
               if (is_strong) { // Likidite alındı (Güçlü)
                   sl = ext_pt; // SL direkt en dibe konur
                   double dist = entry - sl;
                   tp = entry + (dist * 3.0); // 1:3 RR
               } else { // Likidite alınmadı (Zayıf)
                   double raw_sl = ext_pt;
                   double dist = entry - raw_sl;
                   sl = raw_sl - dist; // Zayıf dibin 1 boy daha altına (güvenlik)
                   double new_dist = entry - sl;
                   tp = entry + (new_dist * 3.0); // 1:3 RR
               }
           } else { // SELL
               if (is_strong) {
                   sl = ext_pt; // SL direkt en tepeye konur
                   double dist = sl - entry;
                   tp = entry - (dist * 3.0); // 1:3 RR
               } else {
                   double raw_sl = ext_pt;
                   double dist = raw_sl - entry;
                   sl = raw_sl + dist; // Zayıf tepenin 1 boy daha üstüne (güvenlik)
                   double new_dist = sl - entry;
                   tp = entry - (new_dist * 3.0); // 1:3 RR
               }
           }

           // Dosyayı Common klasörüne yaz (Her iki MT5 terminalinin okuyabilmesi için)
           string filename = "vol100_signal_" + Symbol() + ".txt";
           int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
           if (file_handle != INVALID_HANDLE) {
               string trade_cmd = Symbol() + "," + dir_str + "," + DoubleToString(entry, 5) + "," + DoubleToString(sl, 5) + "," + DoubleToString(tp, 5);
               FileWrite(file_handle, trade_cmd);
               FileClose(file_handle);
               Print("✅ [AUTO-TRADE] Sinyal Gönderildi: ", trade_cmd);
               current_swing_trades++; // Aynı dalgadaki işlem sayısını artır
           } else {
               Print("❌ [AUTO-TRADE] Sinyal Dosyası Oluşturulamadı! Hata Kodu: ", GetLastError());
           }
       } else {
           Print("⚠️ [AUTO-TRADE] Bu majör dalga için maksimum işlem limitine (" + IntegerToString(InpMaxTradesPerSwing) + ") ulaşıldı. Yeni sinyal gönderilmedi.");
       }
   }
  }"""

content = content.replace(verdict_old, verdict_new)

with open('vol100.mq5', 'w', encoding='utf-8') as f:
    f.write(content)

print("Indicator auto-trade signal writer added.")
