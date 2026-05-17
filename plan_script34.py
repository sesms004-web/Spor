import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# No `if(is_history)` around `BxAdvanceTrim`.
# What about `g_bx_touch_state`?
# In `BxUpdateStats`:
"""
        bool im=(h>=bot)&&(l<=top);
        if(im) {
            g_bx_bars_since_touch[k] = 0;
            g_bx_last_bar_time[k] = bar_time; // Reset is always registered
        } else if(bar_time != g_bx_last_bar_time[k]) {
            g_bx_bars_since_touch[k]++;
            g_bx_last_bar_time[k] = bar_time;
        }
        int na;if(prev_c>top)na=1;else if(prev_c<bot)na=-1;else na=g_bx_approach[k];
        int ts=g_bx_touch_state[k];
        if(ts==0){if(im){
            g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);
            g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;
        }}
"""
# Is it possible that `bar_time != g_bx_last_bar_time[k]` causes issues?
# Wait! In the new `BxUpdateStats`:
# `if(im) { ... } else if(bar_time != g_bx_last_bar_time[k]) { ... g_bx_last_bar_time[k] = bar_time; }`
# If price is OUTSIDE the box (`im == false`), we increment the counter, and THEN SET `last_bar_time = bar_time`.
# What happens on the next tick of the SAME bar if price enters the box (`im == true`)?
# `if(im) { g_bx_bars_since_touch = 0; g_bx_last_bar_time = bar_time; }`
# This successfully resets it!
# But what if `im == false` on the FIRST tick. `last_bar_time` becomes `bar_time`.
# On the SECOND tick, `im == false` still. `bar_time != last_bar_time` is FALSE, so we skip the `else if`.
# That's perfectly correct.
# What does `ts==1` do?
"""
        else if(ts==1){if(im){g_bx_inside_cnt[k]++;g_bx_event_time[k]=bar_time;}
            else{bool bd=(c<bot),bu=(c>top);int ap=g_bx_approach[k];
"""
# Wait. `g_bx_inside_cnt[k]++` inside `BxUpdateStats`.
# If `im == true`, `g_bx_inside_cnt` increments ON EVERY TICK!
# Because there is no `last_bar_time` guard for `g_bx_inside_cnt`!!!
# In the original code, `g_bx_inside_cnt[k]++` happened once per bar (since it was only called in history or on new bar? No, it was called in `OnCalculate` on live ticks too).
# The original code:
"""
        else if(ts==1){if(im){g_bx_inside_cnt[k]++;g_bx_event_time[k]=bar_time;}
"""
# This means `g_bx_inside_cnt` would explode to huge numbers in live markets.
# But does that break `BxAdvanceTrim`?
# No, `BxAdvanceTrim` only checks `g_bx_touch_state[k] == 1`.
# When price EXITS the box (`im == false`), `ts==1` enters the `else` block:
"""
            else{bool bd=(c<bot),bu=(c>top);int ap=g_bx_approach[k];
                if(ap==1){
                    if(bd){g_bx_touch_state[k]=2; g_bx_break_dn[k]++;}
                    else if(bu){g_bx_touch_state[k]=3; g_bx_break_up[k]++;}
                }
"""
# If `im == false`, it means `h < bot` OR `l > top`.
# So `c` MUST be either `< bot` (so `bd` is true) OR `c > top` (so `bu` is true).
# So `g_bx_touch_state[k]` becomes 2 or 3.
# Once `g_bx_touch_state` is 2 or 3, it's no longer 1.
# So `BxAdvanceTrim` should be able to trim it.

# What could possibly cause "Gereksiz şekilde kutularin uzunluğu sınırsız oldu"?
# "Gereksiz şekilde kutularin uzunluğu sınırsız oldu" (Boxes became unnecessarily infinite).
# Wait. Look at `BxAdvanceTrim` again.
