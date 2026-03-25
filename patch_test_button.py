import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# 1. Add Input Toggle
search_toggles = """input bool   InpEnableTradeExecution   = true;       // 50 Puanlık 'İşleme Gir' Analiz Sistemini Aç"""
replace_toggles = """input bool   InpEnableTradeExecution   = true;       // 50 Puanlık 'İşleme Gir' Analiz Sistemini Aç
input bool   InpTestTradeExecution     = false;      // 🧪 [TEST] Anlık Puanları Hesapla ve Bildir"""
content = content.replace(search_toggles, replace_toggles)

# 2. Modify EvaluateTradeSignal to accept a boolean `is_test` flag
search_sig = "void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong)"
replace_sig = "void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, bool is_test = false)"
content = content.replace(search_sig, replace_sig)

# 3. Update the Title String in EvaluateTradeSignal if it's a test
search_msg_title = """   string msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\\n";"""
replace_msg_title = """   string msg = "";
   if (is_test) msg = "🧪 [" + Symbol() + "] TEST ANALİZ RAPORU (Şu Anki Durum)\\n";
   else msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\\n";"""
content = content.replace(search_msg_title, replace_msg_title)

# 4. Inject the Test Trigger at the end of the init block inside OnCalculate
search_init_end = """      limit = start_idx + 1;
     }
   else"""

replace_init_end = """      limit = start_idx + 1;

      // TEST TRIGGER
      if (InpTestTradeExecution) {
          int live_tr = 0; double live_pct = 0; double mp_pct = 0;
          double dh, dl; datetime dth, dtl;
          GetMTFPullback(PERIOD_M1, live_tr, live_pct, mp_pct, TimeCurrent(), dh, dl, dth, dtl);

          // Test varsayımı: Ana yön H1'in trend yönüne (g_state_hist.maj_tr) göre bir kırılım (CHoCH) geldiğini farz ediyoruz.
          int test_dir = (live_tr != 0) ? live_tr : 1; // Default to buy if unknown

          EvaluateTradeSignal(rates_total-1, TimeCurrent(), SymbolInfoDouble(Symbol(), SYMBOL_BID), test_dir, live_pct, true, true);
      }
     }
   else"""
content = content.replace(search_init_end, replace_init_end)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Test button patched")
