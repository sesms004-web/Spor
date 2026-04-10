import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's write the string literal exactly as it needs to be in MQL5 to avoid python regex escaping issues.
# MQL5 wants: json += "  \"symbol\": \"" + Symbol() + "\",\\n";

# For manual block
manual_start = text.find('// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---')
manual_end = text.find('return(INIT_SUCCEEDED);', manual_start)

manual_clean = """// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---
   if (InpForceTestSignal) {
       Print("🧪 [TEST SİNYALİ] Gönderiliyor...");
       string filename = "signal_" + Symbol() + ".json";
       int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
       if (file_handle != INVALID_HANDLE) {
           double entry = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
           double point_size = Point();

           // Sahte bir BUY işlemi simüle edelim:
           double sl = entry - (InpTestManualSLDistance * point_size);
           double tp = entry + ((entry - sl) * InpTPRewardRatio);
           double ext_pt = entry - ((InpTestManualSLDistance * point_size) / InpStrongSLMultiplier);

           string json = "{\\n";
           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
           json += "  \\"direction\\": \\"BUY\\",\\n";
           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
           json += "  \\"is_strong\\": true,\\n";
           json += "  \\"is_test\\": true\\n";
           json += "}";

           FileWrite(file_handle, json);
           FileClose(file_handle);
           Print("✅ [TEST BAŞARILI] Ortak Klasöre (Common) Sahte JSON Sinyal Bırakıldı: ", filename);
           Print("⚠️ Lütfen bir sonraki gerçek işlem için gösterge ayarlarından 'InpForceTestSignal' ayarını tekrar FALSE yapmayı unutmayın!");
       } else {
           Print("❌ [TEST HATASI] Ortak klasöre dosya yazılamadı! Kod: ", GetLastError());
       }
   }
   """

text = text[:manual_start] + manual_clean + text[manual_end:]

auto_start = text.find('// --- YENİ AKILLI JSON AUTO-TRADE YAZICI ---')
auto_end = text.find('       } else {\n           string reason = (!is_deep_elastic)', auto_start)

auto_clean = """// --- YENİ AKILLI JSON AUTO-TRADE YAZICI ---
   if (total_points >= InpMinTradeScoreLimit && InpEnableAutoTradeWriter) {

       int current_maj_i = (trigger_dir == 1) ? g_state_curr.maj_l_i : g_state_curr.maj_h_i;
       if (current_maj_i != g_json_last_maj_i) {
           g_json_trades_in_swing = 0;
           g_json_last_maj_i = current_maj_i;
           g_json_last_sl = 0.0;
       }

       bool is_deep_elastic = (mp_m1 >= 40.0);
       int allowed_trades = is_deep_elastic ? InpMaxTradesPerSwing : 1;

       if (g_json_trades_in_swing < allowed_trades) {

           if (g_json_trades_in_swing > 0 && !InpTestMode) {
               if (trigger_dir == 1) {
                   if (live_price >= g_json_last_sl) {
                        Print("⚠️ [JSON-TRADE] BUY reddedildi: Fiyat hala testere bölgesinde. (Eski SL: ", g_json_last_sl, " - Anlık: ", live_price, ") Seviyenin altına inip oradan CHoCH vermesi bekleniyor.");
                        return;
                   }
               }
               if (trigger_dir == -1) {
                   if (live_price <= g_json_last_sl) {
                        Print("⚠️ [JSON-TRADE] SELL reddedildi: Fiyat hala testere bölgesinde. (Eski SL: ", g_json_last_sl, " - Anlık: ", live_price, ") Seviyenin üstüne çıkıp oradan CHoCH vermesi bekleniyor.");
                        return;
                   }
               }
           }

           double sl = 0.0;
           double tp = 0.0;
           double entry = live_price;
           double base_dist = 0.0;
           string dir_str = (trigger_dir == 1) ? "BUY" : "SELL";

           if (InpTestMode) {
               double point_size = Point();
               base_dist = InpTestManualSLDistance * point_size;
               if (trigger_dir == 1) {
                   sl = entry - base_dist;
                   tp = entry + (base_dist * InpTPRewardRatio);
                   ext_pt = entry - (base_dist / (is_strong ? InpStrongSLMultiplier : InpWeakSLMultiplier));
               } else {
                   sl = entry + base_dist;
                   tp = entry - (base_dist * InpTPRewardRatio);
                   ext_pt = entry + (base_dist / (is_strong ? InpStrongSLMultiplier : InpWeakSLMultiplier));
               }
           } else {
               if (trigger_dir == 1) {
                   base_dist = entry - ext_pt;
                   sl = is_strong ? entry - (base_dist * InpStrongSLMultiplier) : entry - (base_dist * InpWeakSLMultiplier);
                   tp = entry + ((entry - sl) * InpTPRewardRatio);
               } else {
                   base_dist = ext_pt - entry;
                   sl = is_strong ? entry + (base_dist * InpStrongSLMultiplier) : entry + (base_dist * InpWeakSLMultiplier);
                   tp = entry - ((sl - entry) * InpTPRewardRatio);
               }
           }

           string filename = "signal_" + Symbol() + ".json";
           int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
           if (file_handle != INVALID_HANDLE) {
               string json = "{\\n";
               json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
               json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";
               json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
               json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
               json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
               json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
               json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";
               json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";
               json += "}";

               FileWrite(file_handle, json);
               FileClose(file_handle);

               Print("✅ [JSON-TRADE] Sinyal Gönderildi: ", filename, " | Yön: ", dir_str, " | Entry: ", entry, " | SL: ", sl, " | TP: ", tp);

               g_json_trades_in_swing++;
               g_json_last_sl = sl;
           } else {
               Print("❌ [JSON-TRADE] Dosya yazılamadı! Hata: ", GetLastError());
           }
"""
text = text[:auto_start] + auto_clean + text[auto_end:]

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
