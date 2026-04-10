with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

start = text.find('// 🧪 TEST TRIGGER EXECUTION')
end = text.find('   // --- MTF SLAVE DASHBOARD (SADECE M1 İÇİN) ---', start)

clean_logic = """// 🧪 TEST TRIGGER EXECUTION (Yalnızca bir kez ve en güncel veriler işlendikten sonra çalıştırılır)
   static bool prev_test_state = false;
   if (InpTestTradeExecution != prev_test_state) {
       prev_test_state = InpTestTradeExecution;

       if (InpTestTradeExecution && last_idx > 0) {
           int live_tr = 0;
           double live_pct = 0.0;
           double dmy_mpct = 0.0;
           double dmy_h, dmy_l; datetime dmy_th, dmy_tl;

           // Milimetrik olarak diğer grafikleri de besleyen ANA fonksiyonu çağır
           GetMTFPullback(PERIOD_M1, live_tr, live_pct, dmy_mpct, time[last_idx], dmy_h, dmy_l, dmy_th, dmy_tl);

           double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

           // Test Analizi, kullanıcının "Pullback sonrası ana trend devamı (BOS/Continuation CHoCH)" mantığına göre simüle edilir.
           int test_choch_dir = live_tr; // Trend Yönü ile aynı olmalı
           EvaluateTradeSignal(last_idx, TimeCurrent(), bid, test_choch_dir, live_pct, true, bid, true);
       }
   }

"""
text = text[:start] + clean_logic + text[end:]

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
