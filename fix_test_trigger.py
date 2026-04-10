import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's fix the test logic block directly
test_start = text.find('// 🧪 TEST TRIGGER EXECUTION')
test_end = text.find('// --- MTF SLAVE DASHBOARD (SADECE M1 İÇİN) ---', test_start)

if test_start != -1 and test_end != -1:
    clean_test_trigger = """// 🧪 TEST TRIGGER EXECUTION (Yalnızca bir kez ve en güncel veriler işlendikten sonra çalıştırılır)
   static bool prev_test_state = false;
   if (InpTestTradeExecution != prev_test_state) {
       prev_test_state = InpTestTradeExecution;

       if (InpTestTradeExecution && last_idx > 0) {
           int live_tr = g_state_curr.maj_tr;
           double live_pct = 0.0;

           double h_m1 = g_state_curr.maj_h;
           double l_m1 = g_state_curr.maj_l;
           double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
           if (h_m1 != EMPTY_VALUE && l_m1 != EMPTY_VALUE && h_m1 != l_m1) {
               double range = h_m1 - l_m1;
               if (live_tr == 1) {
                   live_pct = ((h_m1 - bid) / range) * 100.0;
                   if (bid >= h_m1) live_pct = 0;
               } else {
                   live_pct = ((bid - l_m1) / range) * 100.0;
                   if (bid <= l_m1) live_pct = 0;
               }
               if (live_pct < 0) live_pct = 0;
           }

           // Test Analizi, kullanıcının "Pullback sonrası ana trend devamı (BOS/Continuation CHoCH)" mantığına göre simüle edilir.
           int test_choch_dir = live_tr; // Trend Yönü ile aynı olmalı
           EvaluateTradeSignal(last_idx, TimeCurrent(), bid, test_choch_dir, live_pct, true, bid, true);
       }
   }

   """
    text = text[:test_start] + clean_test_trigger + text[test_end:]


with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
