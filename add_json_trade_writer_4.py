import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Define variables string to inject/replace
    globals_str = """
//--- JSON Auto-Trade Settings ---
input bool   InpEnableAutoTradeWriter = true;       // JSON Sinyal Gönderimini Aç
input int    InpMinTradeScoreLimit = 40;            // Minimum İşleme Giriş Skoru
input double InpStrongSLMultiplier = 1.0;           // Güçlü İşlem Stop Loss Çarpanı
input double InpWeakSLMultiplier = 1.5;             // Zayıf İşlem Stop Loss Çarpanı
input double InpTPRewardRatio = 3.0;                // İşlem Kâr/Zarar (R:R) Oranı
input int    InpMaxTradesPerSwing = 2;              // Aynı Majör Dalga İçinde Max Sinyal

//--- Test Ayarları ---
input bool   InpTestMode              = false;      // 🧪 Test Modu (Manuel Mesafe Testi İçin)
input double InpTestManualSLDistance  = 100.0;      // 🧪 Test SL Mesafesi (Point Cinsinden, Örn: 100)

//--- Trade Range/Testere Kontrol Değişkenleri ---
static int    g_json_last_maj_i = -1;
static int    g_json_trades_in_swing = 0;
static double g_json_last_sl = 0.0;
"""

    # Inject inputs before `//--- Visual Settings ---`
    if "JSON Auto-Trade Settings" not in content:
        content = content.replace("//--- Visual Settings ---", globals_str + "\n//--- Visual Settings ---")

    # Replace manual test trigger in OnInit with the new JSON format test trigger
    test_trigger_pattern = r"// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---.*?(?=\n   return\(INIT_SUCCEEDED\);)"

    new_test_trigger = """// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---
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
           double ext_pt = entry - ((InpTestManualSLDistance * point_size) / InpStrongSLMultiplier); // Tersine mühendislik ile base extreme bulalım

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
   }"""
    content = re.sub(test_trigger_pattern, new_test_trigger, content, flags=re.DOTALL)


    # The trade writer logic to be put in EvaluateTradeSignal
    json_logic = """
   // --- YENİ AKILLI JSON AUTO-TRADE YAZICI ---
   if (total_points >= InpMinTradeScoreLimit && InpEnableAutoTradeWriter) {

       // Yeni bir swing (majör dalga) başladıysa sayaçları sıfırla
       int current_maj_i = (trigger_dir == 1) ? g_state_curr.maj_l_i : g_state_curr.maj_h_i;
       if (current_maj_i != g_json_last_maj_i) {
           g_json_trades_in_swing = 0;
           g_json_last_maj_i = current_maj_i;
           g_json_last_sl = 0.0;
       }

       bool is_deep_elastic = (mp_m1 >= 40.0);
       int allowed_trades = is_deep_elastic ? InpMaxTradesPerSwing : 1;

       if (g_json_trades_in_swing < allowed_trades) {

           // RANGE SIKIŞMASI (TESTERE) KORUMASI:
           // 2. işlem atılacaksa, fiyat eski 1. işlemin SL bölgesinin dışına tamamen çıkmış olmalı!
           if (g_json_trades_in_swing > 0) {
               if (trigger_dir == 1) { // BUY arıyoruz
                   // Fiyat eğer eski SL'nin altına inemediyse (yani yukarıda testereye devam ediyorsa) girmiyoruz!
                   if (live_price >= g_json_last_sl) {
                        Print("⚠️ [JSON-TRADE] BUY reddedildi: Fiyat hala testere bölgesinde. (Eski SL: ", g_json_last_sl, " - Anlık: ", live_price, ") Seviyenin altına inip oradan CHoCH vermesi bekleniyor.");
                        return;
                   }
               }
               if (trigger_dir == -1) { // SELL arıyoruz
                   // Fiyat eğer eski SL'nin üstüne çıkamadıysa (yani aşağıda testereye devam ediyorsa) girmiyoruz!
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

           // EĞER TEST MODUNDAYSANIZ:
           if (InpTestMode) {
               double point_size = Point();
               base_dist = InpTestManualSLDistance * point_size;
               if (trigger_dir == 1) { // BUY TEST
                   sl = entry - base_dist;
                   tp = entry + (base_dist * InpTPRewardRatio);
                   ext_pt = entry - (base_dist / (is_strong ? InpStrongSLMultiplier : InpWeakSLMultiplier));
               } else { // SELL TEST
                   sl = entry + base_dist;
                   tp = entry - (base_dist * InpTPRewardRatio);
                   ext_pt = entry + (base_dist / (is_strong ? InpStrongSLMultiplier : InpWeakSLMultiplier));
               }
           } else {
               // NORMAL CANLI İŞLEM:
               if (trigger_dir == 1) { // BUY
                   base_dist = entry - ext_pt; // ext_pt = minör destek noktası (T2)
                   sl = is_strong ? entry - (base_dist * InpStrongSLMultiplier) : entry - (base_dist * InpWeakSLMultiplier);
                   tp = entry + ((entry - sl) * InpTPRewardRatio);
               } else { // SELL
                   base_dist = ext_pt - entry; // ext_pt = minör direnç noktası (T2)
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
               g_json_last_sl = sl; // RANGE KONTROLÜ İÇİN SL HAFIZAYA ALINIYOR
           } else {
               Print("❌ [JSON-TRADE] Dosya yazılamadı! Hata: ", GetLastError());
           }
       } else {
           string reason = (!is_deep_elastic) ? " (M1 Çekilmesi %40 seviyesine ulaşmadığı için sadece 1 işleme izin verildi)" : "";
           Print("⚠️ [JSON-TRADE] Bu majör dalga için maksimum işlem limitine (" + IntegerToString(allowed_trades) + ") ulaşıldı" + reason + ". Yeni sinyal gönderilmedi.");
       }
   }
"""
    # Replace the place we had AUTO TRADE before
    # Find `   if(InpAlertPush) SendNotification(msg);\n\n   }` -> it was changed previously. Let's find just `if(InpAlertPush) SendNotification(msg);` inside EvaluateTradeSignal
    # Wait, in EvaluateTradeSignal, we have:
    #    if(InpAlertPopup) Alert(msg);
    #    if(InpAlertPush) SendNotification(msg);
    #    // --- YENİ AKILLI JSON AUTO-TRADE YAZICI ---

    # We will remove any previous JSON logic we might have added, and place it clean.
    # First, let's remove everything from `if(InpAlertPush) SendNotification(msg);` until the `}` right before `//+------------------------------------------------------------------+ \n//| MTF Alert System`

    pattern_remove_old = r"(if\(InpAlertPush\) SendNotification\(msg\);)(.*?\n)(?=   \}\n//\+------------------------------------------------------------------\+\n//\| MTF Alert System)"
    content = re.sub(pattern_remove_old, r"\1\n\n", content, flags=re.DOTALL)

    # Now insert the new logic
    pattern_insert = r"(if\(InpAlertPush\) SendNotification\(msg\);\n\n)"
    replacement = r"\1" + json_logic + "\n"
    content = re.sub(pattern_insert, replacement, content)

    # We need to make sure `InpTestTradeExecution` isn't using `is_test = true` logic inside EvaluateTradeSignal to skip printing the exact score or something.
    # Check EvaluateTradeSignal signature: `void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, double ext_pt, bool is_test = false)`
    # The scoring mechanism in EvaluateTradeSignal calculates points unconditionally, which is correct.

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_code('mukemmeliyet.mq5')
