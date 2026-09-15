import re

with open("mt5destekdirencm.mq5", "r") as f:
    code = f.read()

# Change OBJPROP_HIDDEN to false so they show up on the screen and in object list,
# Or just remove it if we want it to be false (default is false)
# Actually OBJPROP_HIDDEN true means it's hidden from the object list, not from the screen.
# BUT wait, maybe the user means "Ekranda gözükmüyor" (It doesn't appear on the screen)
# because time is not passed correctly or something else?

# Wait, `ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);`
# The 4th argument is subwindow. 0 is main chart window.
# But does the user mean the indicator itself doesn't show up?
# #property indicator_chart_window is correct.
# Wait! In OnCalculate we are setting limit = prev_calculated == 0 ? 0 : prev_calculated - 1;
# But for limit = 0, we set limit = i_baseAvgLookback + i_baseMaxCandles + 1;
# BUT wait, the lines and boxes are drawn based on `time[x]`.
# In MQL5 `time` array is indexed from 0 to rates_total-1.
# Since we used `ArraySetAsSeries(time, false);`, index 0 is the OLDEST bar.
# Is that what TradingView uses?
# TradingView uses `bar_index` where 0 is the oldest bar!
# But wait, in the Pine Script: `close[1]` means the previous bar (1 bar ago).
# In MQL5, `close[1]` only means the previous bar if `ArraySetAsSeries(..., true)` is used!
# If `ArraySetAsSeries(close, false)` is used, `close[1]` is the SECOND OLDEST BAR in history!
# Oh my god! That is why nothing works. Pine Script `close[j]` accesses history backwards.
