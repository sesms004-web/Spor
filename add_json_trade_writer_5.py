import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Modify the RANGE SIKIŞMASI code block to skip testere protection if InpTestMode is true
    pattern_testere = r"(           // RANGE SIKIŞMASI \(TESTERE\) KORUMASI:.*?)(?=           double sl = 0\.0;)"

    new_testere_logic = """           // RANGE SIKIŞMASI (TESTERE) KORUMASI:
           // 2. işlem atılacaksa, fiyat eski 1. işlemin SL bölgesinin dışına tamamen çıkmış olmalı!
           if (g_json_trades_in_swing > 0 && !InpTestMode) { // <-- Test Modunda Testere Koruması Devre Dışı!
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

"""
    content = re.sub(pattern_testere, new_testere_logic, content, flags=re.DOTALL)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_code('mukemmeliyet.mq5')
