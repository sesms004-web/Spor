import re

with open("mt5destekdirencm.mq5", "r") as f:
    code = f.read()

# Let's read Pine Script to see how it manages lines.
# In Pine Script:
# draw_minor_line(x1, y1, x2, y2) => line.new(...)
# It creates a NEW line every time!
# Wait, if Pine Script creates a new line every time, then MQL5 creating a new object every time is exactly what the Pine Script does.
# But Pine Script has `max_lines_count=500`. It deletes the oldest automatically. MQL5 does not!
# Wait, no. Look at Pine Script:
"""
            if val_l < min_l
                min_l := val_l
                min_l_i := bar_index
                trig_h := val_h
"""
# `DrawMinorLine` is ONLY called when the leg breaks!
"""
            if val_h > ot
                int ti = min_l_i
                float tp = min_l
                int si = lp_i
                float sp = lp_p
                draw_minor_line(si, sp, ti, tp)
"""
# It's called ONCE when the condition `val_h > ot` triggers.
# It draws the line from `si` to `ti` and then sets `min_tr = 1`.
# So it doesn't redraw the same line over and over! It draws it once the leg is locked.

# EXCEPT for the live leg!
# Pine Script:
"""
var line live_leg_line = line.new(na, na, na, na, color=c_min, style=line.style_solid)
if barstate.islast
    if min_tr == 1
        if i_showMin
            line.set_xy1(live_leg_line, lp_i, lp_p)
            line.set_xy2(live_leg_line, min_h_i, min_h)
"""
# Our MQL5 code:
"""
      if(is_live)
        {
         // Render dynamic live minor leg if necessary
         if(i_showMin)
           {
            if(g_state_curr.min_tr == 1)
               DrawMinorLine(time[g_state_curr.lp_i], g_state_curr.lp_p, time[g_state_curr.min_h_i], g_state_curr.min_h);
            else
               DrawMinorLine(time[g_state_curr.lp_i], g_state_curr.lp_p, time[g_state_curr.min_l_i], g_state_curr.min_l);
           }
        }
"""
# Oh! In MQL5, we use `DrawMinorLine`, which uses `time2` to name the object.
# If `time[min_h_i]` changes on the live bar, it creates a NEW line and we track it in `g_live_objects`.
# Next tick, `ClearLiveObjects()` deletes it.
# So it behaves exactly like `live_leg_line`.

# Let's consider memory again:
# "In the user's MQL5 SMC indicator terminology, 'mavi top' (blue dot...)"
# "To prevent chart object spam and terminal freezes in MQL5 SMC indicators, use deterministic object naming based on timestamps" -> We DID THIS.
# "In MQL5 indicators, do not use ObjectsDeleteAll(0, 0) during initialization... Always use a specific custom prefix" -> We DID THIS (DeleteCustomObjects uses prefix).
# "In MQL5 indicator state-machines, to ensure that dynamically generated structural lines ... appear on historical data and trigger live notifications properly, do not restrict their drawing functions with live-only or history-only conditions" -> We DID THIS.
# "For SMC 'Box' visuals in the user's MQL5 indicators, the user explicitly prefers rendering only the 'IMB' boxes (pullback boxes within an active trend) and strictly wants to exclude the faint 'Extreme' boxes that are typically drawn after a BOS or CHoCH breakout." -> The pine script provides this (Base Drop Boxes).
# "To minimize visual clutter from zigzag structure lines, hide historical minor and major lines and only draw the 2 most recent swings by actively recycling UI object names (e.g., using a modulo-based cyclical name generator)."

# Ah!!!
# The user wants ONLY the 2 most recent swings by actively recycling UI object names!
# If we are drawing all historical minor/major lines, it might be cluttering the screen or maybe the user can't see the most recent ones.
# But wait. The feedback is "Ekranda gözükmüyor" (It doesn't appear on the screen).
# This implies NO objects are visible.

# Why would NO objects be visible?
# Are we returning 0 from OnCalculate?
# `if(rates_total < i_baseAvgLookback + i_baseMaxCandles + 2) return 0;`
# If we have enough bars, it proceeds.
# `limit = prev_calculated == 0 ? 0 : prev_calculated - 1;`
# `if(prev_calculated == 0) limit = 16;`
# Loop runs.
# Returns `rates_total`.

# Could it be `ArraySetAsSeries(time, false)` is not affecting `time`?
# `time` is a CONSTANT reference: `const datetime &time[]`
# `ArraySetAsSeries` CANNOT change the AS_SERIES flag of a `const` array passed to `OnCalculate`!
# WAIT! In MQL5, `time`, `open`, `high`, `low`, `close` passed to `OnCalculate` are CONSTANT.
# Wait, NO. The documentation says `ArraySetAsSeries` CAN be used on `time`, `open`, etc. inside `OnCalculate`.
# Let's check docs: `ArraySetAsSeries` is typically used on them.
# BUT, is it possible that `time` is ALREADY as series?
# By default, in MQL5, `time` array in `OnCalculate` is NOT as series. (Index 0 is oldest).
# So `ArraySetAsSeries(time, false)` is fine.
