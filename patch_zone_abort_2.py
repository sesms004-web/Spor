import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Modify the Abort rule to kill the sequence the SECOND it passes the MaxBreakoutPct
search_abort = """         // CHoCH Sequence Abort Rule (Out of Pullback Zone)
         if (state.choch_dir != 0 && !in_pullback_zone) {
             state.choch_dir = 0; // Zone exceeded/failed, kill sequence
         }"""

replace_abort = """         // CHoCH Sequence Abort Rule (Out of Pullback Zone or Exceeded Max Breakout Pct)
         if (state.choch_dir != 0) {
             if (!in_pullback_zone || p_pct > InpMaxBreakoutPct) {
                 state.choch_dir = 0; // Zone exceeded/failed or went too deep, kill sequence
             }
         }"""

content = content.replace(search_abort, replace_abort)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Abort rule patched to instantly kill sequence")
