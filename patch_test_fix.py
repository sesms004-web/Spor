import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Replace the faulty test logic
search_test = """          // Test varsayımı: Ana yön H1'in trend yönüne (g_state_hist.maj_tr) göre bir kırılım (CHoCH) geldiğini farz ediyoruz.
          int test_dir = (live_tr != 0) ? live_tr : 1; // Default to buy if unknown

          EvaluateTradeSignal(rates_total-1, TimeCurrent(), SymbolInfoDouble(Symbol(), SYMBOL_BID), test_dir, live_pct, true, true);"""

replace_test = """          // Test varsayımı: O anki M1 yönünün devamı niteliğinde bir kırılım (CHoCH) geldiğini farz ediyoruz.
          // In real signals, M1 break direction is explicitly 1 (Bullish) or -1 (Bearish). Here we fetch current live_tr.
          int test_dir = live_tr;
          if (test_dir == 0) test_dir = g_state_hist.maj_tr; // Fallback to macro if absolutely no M1 trend identified yet

          EvaluateTradeSignal(rates_total-1, TimeCurrent(), SymbolInfoDouble(Symbol(), SYMBOL_BID), test_dir, live_pct, true, true);"""

content = content.replace(search_test, replace_test)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Test button direction patched")
