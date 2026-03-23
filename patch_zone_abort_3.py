import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Remove the faulty "p_pct > InpMaxBreakoutPct" abort rule which restricts it to [40, 50].
search_abort = """         // CHoCH Sequence Abort Rule (Out of Pullback Zone or Exceeded Max Breakout Pct)
         if (state.choch_dir != 0) {
             if (!in_pullback_zone || p_pct > InpMaxBreakoutPct) {
                 state.choch_dir = 0; // Zone exceeded/failed or went too deep, kill sequence
             }
         }"""

# Revert to just checking if it is entirely outside the valid Pullback Zone ([MinPct, MaxPct])
replace_abort = """         // CHoCH Sequence Abort Rule (Out of Pullback Zone)
         if (state.choch_dir != 0 && !in_pullback_zone) {
             state.choch_dir = 0; // Left the authorized zone entirely ([InpMinPullbackPct, InpMaxPullbackPct])
         }"""

content = content.replace(search_abort, replace_abort)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Restored original zone abort")
