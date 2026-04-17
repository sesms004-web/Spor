import re
with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's change test_time to use TimeCurrent() inside GetMTFPullback and EvaluateTradeSignal for now.
# And inside EvaluateTradeSignal, c_t_h1 will get the CHoCH time.
# But wait, EvaluateTradeSignal uses t to query MTF data. When t is exact time of bar open (iTime),
# GetMTFChochDetails uses current_time for CopyRates. But current_time passed to CopyRates(..., current_time)
# will only pull data UP TO that exact second. Since M15 bar opens at 13:00 and we request 13:00, it might just pull 13:00 bar as the very last.
# Actually, the user says "Veri bekleniyor diyor hala".
# Let's read why h1_sup_text says "Veri Bekleniyor...".
# "Veri Bekleniyor..." means c_dir_h1 == 0.
# Why is c_dir_h1 == 0?
# Because st.last_choch_dir is 0 at the end of GetMTFChochDetails.
# Why is it 0? Because the history passed (tf_days) isn't long enough to capture an H1 CHoCH, OR because it resets to 0.

# Look at GetMTFChochDetails:
# st.last_choch_dir = 0;
# for(int i=1; i<copied; i++) { ... ProcessBar(..., st, true, false); }
# If there's no CHoCH in the copied window, it remains 0.
# The user's input:
# input double InpDaysH1   = 180.0;
# That's 6 months. It should definitely find a CHoCH.
# Wait! In GetMTFChochDetails:
#       if(i == copied - 1) {
#            double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
#            _close[i] = bid;
#            if(bid > _high[i]) _high[i] = bid;
#            if(bid < _low[i]) _low[i] = bid;
#         }
# Why would it be 0?
# Let's check `GetMTFChochDetails` logic...
