import re

with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Wait. I noticed something.
# In `BxUpdateStats`:
# I wrote:
"""
        if(im) {
            g_bx_bars_since_touch[k] = 0;
            g_bx_last_bar_time[k] = bar_time; // Reset is always registered
        } else if(bar_time != g_bx_last_bar_time[k]) {
            g_bx_bars_since_touch[k]++;
            g_bx_last_bar_time[k] = bar_time;
        }
"""
# If `im` is true on the FIRST tick of a bar, `last_bar_time` becomes `bar_time`.
# If `im` is false on the NEXT tick of the same bar... `bar_time == g_bx_last_bar_time[k]`, so it ignores the `else if`.
# That's perfectly correct for tracking staleness (we don't increment stale counter intra-bar).
# BUT did this block execution of anything else? No.

# Wait, what if the `EvaluateTradeSignal` logic caused it? No.
# What about `g_shd_state`?
# In my recent PR, I completely replaced `old_shd` and `old_bx` updates.

match = re.search(r"void BxUpdateStats.*?\}", code, re.DOTALL)
if match:
    print(match.group(0))
