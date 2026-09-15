import re

with open("mt5destekdirencm.mq5", "r") as f:
    code = f.read()

# Fix ArraySetAsSeries: if we use true, then index 0 is current bar, index rates_total-1 is oldest bar.
# But our loop is `for(int i = limit; i < rates_total; i++)`, which means we go from oldest to newest if limit=0 to rates_total.
# But if we use ArraySetAsSeries=true, then i=0 is NEWEST bar, so looping `i=limit to rates_total` would go from NEWEST to OLDEST.
# The indicator loop MUST go from oldest to newest.
# So `ArraySetAsSeries(..., false)` (index 0 is oldest) is correct for the loop structure.

# HOWEVER, in the pine script conversion, when accessing `close[i-j]`, since `i` is the current bar in the loop (where 0 is oldest, rates_total-1 is newest), `i-j` correctly points to the `j`-th previous bar!
# Example: i=100 (current). i-1 = 99 (previous bar).
# Because index 0 is oldest.
# So `close[i-j]` actually is perfectly correct with `ArraySetAsSeries(..., false)`.

# So why did the user say "Ekranda gözükmüyor" (It doesn't appear on the screen)?
# Let's look at DrawBox and DrawLine again.
# In `DrawBox`, we have `ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);`
# `time1` and `time2` are datetimes.
# Are we drawing boxes correctly? Yes.
# Are we passing time1/time2? Yes, `time[si]`, `time[ti]`.

# Let's check `OnCalculate` logic for Box:
# datetime start_t = time[i-base_start+1];
# datetime end_t = time[i] + PeriodSeconds()*5;
# Is PeriodSeconds() correct? In MT5 `PeriodSeconds()` returns the timeframe in seconds.
# `time[i] + PeriodSeconds()*5` is correct.

# What about DrawMinorLine?
# `DrawMinorLine(time[si], sp, time[ti], tp);`
# Wait, in the Pine script, `lp_i` and `ti` are `bar_index`es!
# In the initialization:
# `g_state_hist.anc_i = 0;` (index)
# `g_state_hist.lp_i = 0;` (index)
# So `time[si]` gets the time of the bar at index `si`. This is correct.

# Are we returning `rates_total` correctly? Yes.

# Could it be because `i_showChoch` etc are false by default? No, they are true.

# Wait, `ArraySetAsSeries` is called in `OnCalculate` every tick. That's fine.

# Could it be related to `c_boxBull = clrBlue; color c_weakBull = C'0,25,55';` ?
# In MQL5, `C'0,25,55'` is valid.

# Wait! Look at `ObjectSetInteger(0, name, OBJPROP_BACK, true);`
# And `ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);`
# OBJPROP_HIDDEN hides it from the object list.
# Is `OBJPROP_RAY_RIGHT` setting valid for `OBJ_TREND`? Yes.
# But what about the `ObjectCreate` itself?
# `ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);`
# `time1, price1` and `time2, price2`.
# `ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);`

# What if `limit` calculation is skipping history?
# `int limit = prev_calculated == 0 ? 0 : prev_calculated - 1;`
# `if(prev_calculated == 0) { ... limit = i_baseAvgLookback + i_baseMaxCandles + 1; }`
# `for(int i = limit; i < rates_total; i++)`
# If we have 1000 bars, it processes i=16 to 999.
# Then `rates_total` is returned.
# On the next tick, `prev_calculated = 1000`.
# `limit = 1000 - 1 = 999`.
# Loop runs for `i = 999` (last bar).
# This is completely correct!

# Wait, look at `is_inside` logic!
"""
      bool is_inside = c_h <= g_state_curr.mb_h && c_l >= g_state_curr.mb_l;

      if(!is_inside)
        {
         if(c_h > g_state_curr.mb_h || c_l < g_state_curr.mb_l)
           {
            g_state_curr.mb_h = c_h;
            g_state_curr.mb_l = c_l;
            g_state_curr.mb_i = i;
           }
"""
# `mb_h` is initialized to `high[0]`, `mb_l` to `low[0]`.
# If `is_inside` is true, the rest of the bar processing is SKIPPED!
# Is this correct?
# In Pine Script:
# `bool is_inside = high <= mb_h and low >= mb_l`
# `if not is_inside`
# Yes, it is skipped. This is "inside bar" logic.

# Let's review the minor structure logic:
"""
         if(g_state_curr.min_tr == 1)
           {
            double ob = g_state_curr.trig_l;
            if(val_h > g_state_curr.min_h)
              {
               g_state_curr.min_h = val_h;
               g_state_curr.min_h_i = i;
               g_state_curr.trig_l = val_l;
              }
            if(val_l < ob)
"""
# Wait, if `val_l < ob`, it draws `DrawMinorLine(time[si], sp, time[ti], tp);`
# But it uses `si` and `ti` from the PREVIOUS state because they are captured BEFORE updating `min_tr = -1`.
# Let's check `si` and `ti`:
"""
               int ti = g_state_curr.min_h_i;
               double tp = g_state_curr.min_h;
               int si = g_state_curr.lp_i;
               double sp = g_state_curr.lp_p;
"""
# If `min_h_i` is updated in the same bar, `ti` is current bar.
# Then `lp_i = ti` is set.
# This matches pine script.

# Why would it NOT SHOW ON SCREEN?
# Is it because `i_days` input is there but not used?
# In pine script: `i_days = input.float(1.0, "Lookback Days (Main)", group=grp_lookback)`
# It is actually NOT USED anywhere in the pine script!
# Wait, in the user's MQL5 code snippet, `InpDaysM1` etc are used to limit calculation. We didn't do that, which is fine, we calculate all history.

# Maybe `g_state_curr` is not retaining data between ticks?
# In `OnCalculate`:
# `g_state_curr.CopyFrom(g_state_hist);`
# `g_state_hist` is ONLY updated if `!is_live`:
# `if(is_live) { ... } else { g_state_hist.CopyFrom(g_state_curr); }`
# Is `is_live` logic correct?
# `bool is_live = (i == rates_total - 1);`
# Since we return `rates_total`, on a new tick, `rates_total` is the same, so `prev_calculated == rates_total`.
# Wait, MT5 returns `rates_total`. On next tick on the SAME BAR, `prev_calculated` is `rates_total`.
# So `limit = rates_total - 1`.
# `i = limit`, which is `rates_total - 1`.
# `is_live` is true!
# So `g_state_hist` is NOT updated.
# But what if a NEW BAR comes?
# `rates_total` becomes `old_rates_total + 1`.
# `prev_calculated` is `old_rates_total`.
# `limit = old_rates_total - 1`.
# Loop runs for `i = old_rates_total - 1` AND `i = old_rates_total`.
# For `i = old_rates_total - 1` (the bar that just closed), `is_live` is `(old_rates_total - 1 == old_rates_total) -> FALSE`!
# So `g_state_hist.CopyFrom(g_state_curr)` IS EXECUTED for the closed bar!
# This logic is PERFECT.

# Wait, what if we initialize `limit` and `g_state_hist.CopyFrom` is failing somehow?
# Let's check `CopyFrom`:
"""
      st_h_val.CopyFrom(other.st_h_val);
      st_h_idx.CopyFrom(other.st_h_idx);
      st_l_val.CopyFrom(other.st_l_val);
      st_l_idx.CopyFrom(other.st_l_idx);
"""
# All CStack classes have a `CopyFrom` method that uses `ArrayResize` properly.
# BUT wait! If `other` is `g_state_hist` and `this` is `g_state_curr`, we are doing `g_state_curr.CopyFrom(g_state_hist)`.
# Inside `CopyFrom`, we do `m_size = other.Size(); ArrayResize(m_vals, m_size); for(int i=0; i<m_size; i++) m_vals[i] = other.Get(i);`
# This is completely correct.

# Could it be the chart scaling?
# `DrawMinorLine(time[si], sp, time[ti], tp);`
# What if `si` is 0 and `ti` is 0 at the beginning and it creates a line that is invisible?
# If `si == 0`, `time[si]` is valid.

# Wait, the user said "Ekranda gözükmüyor" (It doesn't appear on the screen).
# Could it be that the Pine Script needs more history? `if(rates_total < i_baseAvgLookback + i_baseMaxCandles + 2) return 0;` (17 bars). That's fine.

# Let's look at `DeleteCustomObjects()`.
# `if(StringFind(name, "str_") == 0 || StringFind(name, "bx_") == 0) ObjectDelete(0, name);`
# In `OnCalculate` (limit==0) it calls `DeleteCustomObjects()`.
# In `OnDeinit` it calls `DeleteCustomObjects()`.
# In `ClearLiveObjects()`, it calls `ObjectDelete(0, g_live_objects.Get(i))`.
# Are we accidentally deleting EVERYTHING?
# `ClearLiveObjects()` ONLY deletes objects in `g_live_objects`.
# When does `g_live_objects` get populated?
# When `g_is_live == true`, `DrawLine` and `DrawBox` push the object name to `g_live_objects`.
# `g_is_live` is `is_live`.
# Wait! In `DrawLine` and `DrawBox`:
"""
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
   else ...
   if(g_is_live) AddLiveObject(name);
"""
# For history bars (`g_is_live == false`), it creates the object but DOES NOT add it to `g_live_objects`.
# For the live bar, it adds it to `g_live_objects`.
# Next tick, `ClearLiveObjects()` is called. It DELETES those objects.
# But wait! If `ObjectCreate` creates the object, and then `AddLiveObject` adds it, and then next tick it is deleted...
# What if it's the SAME structure?
# E.g., `DrawMinorLine` is called on the live bar. The line is drawn and added to `g_live_objects`.
# Next tick, it is deleted.
# If the condition STILL holds, it is redrawn and re-added.
# If the bar closes, on the NEXT tick, `is_live` was false for that closed bar. Wait.
# Look at the loop when a bar closes:
# `limit = old_rates_total - 1`
# Loop runs for `i = old_rates_total - 1` (is_live = false)
# The object is created. `g_is_live = false`. So it is NOT added to `g_live_objects`.
# But wait, in the PREVIOUS ticks, this object was drawn when `is_live == true`, so its name is in `g_live_objects`!
# So before the loop, `ClearLiveObjects()` DELETES the object.
# Then the loop runs for the closed bar, creates the object anew, and DOES NOT add it to `g_live_objects`.
# This is PERFECT.

# BUT wait.
# `StringFind(name, "str_") == 0`
# Are all objects named starting with "str_" or "bx_"?
# `string name = "str_min_" + IntegerToString((int)time2);`
# `string name = "str_maj_" + IntegerToString((int)time2);`
# `string name = "str_choch_" + IntegerToString((int)time2);`
# `string name = "str_choch_path_" + IntegerToString((int)time2);`
# `string name = "bx_" + ...`
# YES.

# So why does it not show up?
# Maybe the Pine Script logic actually produces NO objects on typical charts?
# Let's check `min_tr = -1`. `g_state_curr.choch_dir = 0`.
# Is `DrawMinorLine` being called?
# `DrawMinorLine(time[si], sp, time[ti], tp);`
# Is `time[si]` valid? Yes.
# Wait! `time2` in `DrawMinorLine` is passed as `time[ti]`.
# `string name = "str_min_" + IntegerToString((int)time2);`
# In `ObjectCreate` we use `time1` and `time2`.
# In MT5, if `time1 == time2`, a trendline might not be visible.
# But `si` (start index) is `g_state_curr.lp_i`, and `ti` is `g_state_curr.min_h_i`.
# These are different indexes, so different times.
