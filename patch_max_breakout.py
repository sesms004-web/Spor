import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# 1. Add new Input parameter
inputs_search = """input double InpMaxPullbackPct = 100.0;          // CHoCH Max Çekilme % (İşlem Yüzdeliği)"""
inputs_replace = """input double InpMaxPullbackPct = 100.0;          // CHoCH Max Çekilme % (İşlem Yüzdeliği)
input double InpMaxBreakoutPct = 50.0;           // CHoCH Maksimum İzin Verilen Kırılım %"""
content = content.replace(inputs_search, inputs_replace)

# 2. Modify Trigger Condition to include Breakout Percentage threshold
trigger_search_bear = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {
      if (val_c < state.d1_l) {"""

trigger_replace_bear = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {
      if (val_c < state.d1_l && p_pct <= InpMaxBreakoutPct) {"""

content = content.replace(trigger_search_bear, trigger_replace_bear)

trigger_search_bull = """   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h) {"""

trigger_replace_bull = """   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h && p_pct <= InpMaxBreakoutPct) {"""

content = content.replace(trigger_search_bull, trigger_replace_bull)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Breakout percentage patched")
