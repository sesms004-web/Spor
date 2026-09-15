import re

with open("mt5destekdirencm.mq5", "r") as f:
    code = f.read()

# Let's check `is_inside` logic again.
# High[0], Low[0]
"""
      bool is_inside = c_h <= g_state_curr.mb_h && c_l >= g_state_curr.mb_l;
"""
# If `c_h <= mb_h` and `c_l >= mb_l`, it's an inside bar, so it SKIPS logic!
# BUT wait. In MQL5, `mb_h` and `mb_l` are initialized to `high[0]` and `low[0]`.
# If `is_inside` is true, the `val_h`, `val_l`, `val_c` variables are NEVER DECLARED for that tick/bar, so the logic is skipped!
# What if all bars are skipping?
# No, `mb_h` and `mb_l` are updated when it's NOT inside.

# WAIT. `min_tr = -1`. `g_state_curr.min_h = high[0]`.
# Let's look at the initialization:
"""
      g_state_hist.min_tr = close[0] > open[0] ? 1 : -1;
      g_state_hist.maj_tr = g_state_hist.min_tr;
"""
# This uses `close[0]` and `open[0]`.
# If index 0 is oldest, `close[0]` is the first bar in history.
# That's perfectly fine.

# BUT wait! Does Pine Script `bar_index` start at 0?
# Yes, `bar_index` in Pine Script is 0 for the first historical bar, and increases.
# In MQL5, `i` increases from 0 to rates_total - 1.
# So `i` perfectly maps to `bar_index`!

# So where is the bug?
# Look at `ClearLiveObjects()`.
# `for(int i=0; i<g_live_objects.Size(); i++) ObjectDelete(0, g_live_objects.Get(i));`
# It deletes objects in `g_live_objects`.
# `g_live_objects` is NOT cleared on init.
# But it's initialized as a global/member?
# `CStackString g_live_objects;` (Global).
# This is fine.

# Let's look at `DrawLine`:
"""
void DrawLine(string name, datetime time1, double price1, datetime time2, double price2, color clr, int width, ENUM_LINE_STYLE style, bool ray_right=false)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
"""
# If `time1 == time2` and `price1 == price2`, MT5 won't draw a trend line properly, it might be a single dot.
# But `lp_i` and `min_h_i` are different.

# WAIT, `rates_total < i_baseAvgLookback + i_baseMaxCandles + 2`
# If rates_total is small, it returns 0. That's fine.

# WHAT IF `DeleteCustomObjects` is being called CONSTANTLY?
# It's called when `prev_calculated == 0`.
# If the indicator is returning 0, `prev_calculated` becomes 0 on the next tick!
# Does our indicator return 0?
# `return(rates_total);`
# Yes, it returns `rates_total`.

# Could there be a compilation error causing it to not run at all?
# The code review passed.

# What about memory?
# "In MQL5 Custom Indicators, Sleep() is completely ignored... trigger background downloads using CopyRates when prev_calculated == 0, and gate execution in OnCalculate by returning 0 until Bars(Symbol(), tf) confirms sufficient historical data has loaded."
# We are not using MTF here. So that's fine.

# Let's add Print statements to debug or maybe there's a simpler issue.
# Is `OBJ_TREND` visible by default? Yes.
# Is `OBJ_RECTANGLE` visible by default? Yes.
# Are they drawn in the background? `ObjectSetInteger(0, name, OBJPROP_BACK, true);`. Yes, behind price.
# Are they hidden? `ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);`. Hidden from object list, NOT from screen.

# Wait, `DoubleToString(price1, 5)`. MT5's `DoubleToString` formats the price.
# What if the name exceeds 63 characters?
# `bx_1234567890_1.12345_1.12345` is about 30 chars. Safe.

# Wait, look at this:
# "To minimize visual clutter from zigzag structure lines, hide historical minor and major lines and only draw the 2 most recent swings by actively recycling UI object names (e.g., using a modulo-based cyclical name generator)."
# The user wants ONLY the 2 most recent swings!
# If I draw 500 lines, MT5 might be freezing or the user can't see them.
# BUT wait! Pine script says `max_lines_count=500` and `max_boxes_count=500`.
# TradingView automatically deletes oldest lines when it reaches 500!
# MT5 DOES NOT! It will draw 50,000 lines!
# This WILL cause MT5 to freeze or the user to see a completely cluttered screen!
# That's why the memory says: "use a modulo-based cyclical name generator".

# Let's fix this by implementing cyclical names for minor and major lines!
