import re

with open("mt5destekdirencm.mq5", "r") as f:
    code = f.read()

# Is there an issue with time[i] being 0?
# ArraySetAsSeries is false. So time[0] is the oldest bar.
# That is correct.

# Wait, `ArraySetAsSeries` sets the indexing direction.
# If we do `ArraySetAsSeries(time, false)`, index 0 is oldest.
# BUT wait! When we pass `const datetime &time[]` to `OnCalculate`, it is ALREADY indexed from 0 to rates_total-1 where 0 is OLDEST, UNLESS we change it.
# BUT MT5's `CopyRates` returns data where 0 is OLDEST.
# The default for `time[]` in `OnCalculate` is 0 = OLDEST.
# So `ArraySetAsSeries(time, false)` is a no-op, it just ensures it.
# BUT wait, what about `close[i-j]` in the Box Logic?
"""
                     double body = MathAbs(close[i-base_start] - open[i-base_start]);
"""
# If 0 is OLDEST, and `i` is current (e.g. 100), then `i - base_start` (100 - 1 = 99) is the PREVIOUS bar (since 99 is older than 100).
# This is mathematically CORRECT.

# Wait, check `i_showBox` = true;
# What about the Major/Minor lines?
# `if(val_l < ob)` -> DrawMinorLine
# This is also correct.

# Could it be that the color `C'0,25,55'` is invalid or causing issues? No.
# Could it be that the user has a black background and the lines are invisible? `clrRed`, `clrGreen`, `clrBlue` are very visible on both black and white.

# Wait! Look at `draw_choch_line` in Pine Script:
# `draw_choch_line(bar_index, d1_h, bar_index+5, d1_h, is_strong)`
# In MQL5:
# `DrawChochLine(time[i], g_state_curr.d1_h, time[i] + PeriodSeconds()*5, g_state_curr.d1_h, is_strong, time[g_state_curr.t1_i], g_state_curr.d1_h);`
# `time[i] + PeriodSeconds()*5` is 5 bars into the future. That's perfectly fine.

# Wait, could `ObjectCreate` fail because of chart window ID?
# `ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);`
# The 4th argument is subwindow: 0 means main chart. This is correct.

# What about `OBJPROP_RAY_RIGHT`?
# In `DrawLine`, we have `ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, ray_right);`
# `ray_right` is false by default. This is correct.

# Look closely at `time[i]` usage inside the loop.
# `limit = prev_calculated == 0 ? 0 : prev_calculated - 1;`
# If we attach the indicator, `prev_calculated` is 0.
# `limit = i_baseAvgLookback + i_baseMaxCandles + 1;` (e.g. 10 + 5 + 1 = 16).
# The loop runs from i=16 to rates_total.
# For each bar, it processes logic.
# DOES IT ACTUALLY CALL `DrawMinorLine` during historical loop?
# Yes! `DrawMinorLine(time[si], sp, time[ti], tp);` is called unconditionally if conditions are met.
# But wait...
# `if(ObjectFind(0, name) < 0)`
# `name = "str_min_" + IntegerToString((int)time2);`
# Let's say it finds a minor line at time `T`. It creates it.
# Then later, the minor structure changes!
# `DrawMinorLine` is called AGAIN with a NEW `time2` (because `ti` is updated).
# But wait, `ti` is `g_state_curr.min_h_i`.
# In the Pine Script:
"""
               int ti = g_state_curr.min_l_i;
               double tp = g_state_curr.min_l;
               int si = g_state_curr.lp_i;
               double sp = g_state_curr.lp_p;
               DrawMinorLine(time[si], sp, time[ti], tp);
"""
# `ti` is the index of the minor low.
# So `time[ti]` is the time of the minor low.
# Since a minor low can be updated multiple times before the leg is finished, `ti` (and therefore `time2`) will CHANGE!
# If `time2` changes, `name` changes!
# `string name = "str_min_" + IntegerToString((int)time2);`
# If `name` changes, it creates a NEW object!
# And the OLD object is NEVER DELETED!
# Because TradingView's Pine Script uses `line.set_xy1` and `line.set_xy2` on a persistent line object!
# Ah!!!
