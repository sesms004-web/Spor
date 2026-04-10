import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. ADD UI Dashboard logic to show MTF Status
# We'll inject a Comment() call into OnCalculate if InpUseMasterSlave is true and it's M1.
ui_dashboard_logic = """
   // --- MTF SLAVE DASHBOARD (SADECE M1 İÇİN) ---
   static uint last_ui_tick = 0;
   if (InpUseMasterSlave && Period() == PERIOD_M1 && GetTickCount() - last_ui_tick > 1000) {
       string ui = "\\n\\n--- 📡 MASTER/SLAVE MTF DURUMU ---\\n";
       ENUM_TIMEFRAMES tfs[] = {PERIOD_M3, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1};
       string tf_names[] = {"M3", "M5", "M15", "M30", "H1"};

       for(int j=0; j<5; j++) {
           string base_name = "ST_" + Symbol() + "_" + EnumToString(tfs[j]) + "_";
           if (GlobalVariableCheck(base_name + "TIME")) {
               datetime last_upd = (datetime)GlobalVariableGet(base_name + "TIME");
               int age = (int)(TimeCurrent() - last_upd);
               if (age <= InpMaxDataAge) {
                   ui += "✅ " + tf_names[j] + " : Bağlı (Gecikme: " + IntegerToString(age) + "sn)\\n";
               } else {
                   ui += "❌ " + tf_names[j] + " : KOPUK (Eski Veri: " + IntegerToString(age) + "sn)\\n";
               }
           } else {
               ui += "❌ " + tf_names[j] + " : KOPUK (Grafik Açık Değil!)\\n";
           }
       }
       Comment(ui);
       last_ui_tick = GetTickCount();
   } else if (!InpUseMasterSlave && Period() == PERIOD_M1) {
       Comment(""); // Master slave kapalıysa ekranı temizle
   }
"""

text = text.replace("   // --- SLAVE GÜNCELLEMESİ (SADECE ONAYLANAN BARLAR) ---", ui_dashboard_logic + "\n   // --- SLAVE GÜNCELLEMESİ (SADECE ONAYLANAN BARLAR) ---")


# 2. Fix the Test Trade Execution Trigger logic
# Currently `is_test_run` uses `prev_calculated == 0`. We need to track the boolean state `InpTestTradeExecution`
test_logic_find = r'   static bool is_test_run = false;\n   if \(prev_calculated == 0\) is_test_run = false; // Reset on re-compile/re-attach\n\n   if \(!is_test_run && last_idx > 0\) \{\n       // TEST TRIGGER FOR TRADE EXECUTION\n       if \(InpTestTradeExecution\) \{'
test_logic_replace = r"""   static bool prev_test_state = false;
   if (InpTestTradeExecution != prev_test_state) {
       prev_test_state = InpTestTradeExecution;

       if (InpTestTradeExecution && last_idx > 0) {
           // Ayar FALSE'dan TRUE'ya çekildiğinde 1 kere çalışır."""

text = re.sub(test_logic_find, test_logic_replace, text, flags=re.DOTALL)

# Remove the old `if(!InpTestTradeExecution) is_test_run = true;` block
text = re.sub(r'           int test_choch_dir = live_tr;.*?           EvaluateTradeSignal\(last_idx, TimeCurrent\(\), bid, test_choch_dir, live_pct, true, bid, true\);\n           is_test_run = true;\n       \}\n       if\(!InpTestTradeExecution\) is_test_run = true; // prevent infinite false state if both are off\n   \}',
r"""           int test_choch_dir = live_tr; // Trend Yönü ile aynı olmalı
           EvaluateTradeSignal(last_idx, TimeCurrent(), bid, test_choch_dir, live_pct, true, bid, true);
       }
   }""", text, flags=re.DOTALL)


with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
