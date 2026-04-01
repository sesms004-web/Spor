import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Bearish block insertion (Making a HIGH)
search_bear = "         // CHoCH Bearish sequence tracking"
replace_bear = """         // CHoCH Invalidation (Making a High)
         if (state.choch_dir == -1 && state.t2_h != 0) {
             // T1, D1, T2 formed. Making ANOTHER High means Leg 3 failed to break D1. Reset.
             state.choch_dir = 0;
         }
         if (state.choch_dir == 1 && state.t2_l != 0 && state.min_h <= state.d1_h) {
             // Bullish: T1, D1, T2 formed. Making a High that is <= D1 means failure to break. Reset.
             state.choch_dir = 0;
         }

         // CHoCH Bearish sequence tracking"""

content = content.replace(search_bear, replace_bear)

# Bullish block insertion (Making a LOW)
search_bull = "         // CHoCH Bullish sequence tracking"
replace_bull = """         // CHoCH Invalidation (Making a Low)
         if (state.choch_dir == 1 && state.t2_l != 0) {
             // T1, D1, T2 formed. Making ANOTHER Low means Leg 3 failed to break D1. Reset.
             state.choch_dir = 0;
         }
         if (state.choch_dir == -1 && state.t2_h != 0 && state.min_l >= state.d1_l) {
             // Bearish: T1, D1, T2 formed. Making a Low that is >= D1 means failure to break. Reset.
             state.choch_dir = 0;
         }

         // CHoCH Bullish sequence tracking"""

content = content.replace(search_bull, replace_bull)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Zigzag reset logic added")
