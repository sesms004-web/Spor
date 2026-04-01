import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Bearish abort rule
search_bear = """         // CHoCH Bearish sequence tracking
         if (state.maj_tr == -1 && in_pullback_zone) {"""

replace_bear = """         // CHoCH Sequence Abort Rule (Out of Pullback Zone)
         if (state.choch_dir != 0 && !in_pullback_zone) {
             state.choch_dir = 0; // Zone exceeded/failed, kill sequence
         }

         // CHoCH Bearish sequence tracking
         if (state.maj_tr == -1 && in_pullback_zone) {"""

content = content.replace(search_bear, replace_bear)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Zone abort logic added")
