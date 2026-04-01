import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Make it completely simple:
# InpMinPullbackPct = 40.0 (Don't show for 0, 10, 20, 30)
# InpMaxPullbackPct = 100.0 (Show up to 100)
# We can just remove the InpMaxBreakoutPct parameter altogether since it's just about the 40-100 zone.

search_inputs = """//--- CHoCH Settings ---
input double InpMinPullbackPct = 40.0;           // CHoCH Min Çekilme % (Onay Yüzdeliği)
input double InpMaxPullbackPct = 100.0;          // CHoCH Max Çekilme % (İşlem Yüzdeliği)
input double InpMaxBreakoutPct = 50.0;           // CHoCH Maksimum İzin Verilen Kırılım %"""

replace_inputs = """//--- CHoCH Settings ---
input double InpMinPullbackPct = 40.0;           // CHoCH Min Çekilme % (Örn: 40)
input double InpMaxPullbackPct = 100.0;          // CHoCH Max Çekilme % (Örn: 100)"""

content = content.replace(search_inputs, replace_inputs)

# Bear trigger remove breakout pct check
search_bear = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {
      if (val_c < state.d1_l && p_pct <= InpMaxBreakoutPct) {"""

replace_bear = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {
      if (val_c < state.d1_l && in_pullback_zone) {"""

content = content.replace(search_bear, replace_bear)

# Bull trigger remove breakout pct check
search_bull = """   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h && p_pct <= InpMaxBreakoutPct) {"""

replace_bull = """   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h && in_pullback_zone) {"""

content = content.replace(search_bull, replace_bull)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Inputs and trigger rules simplified")
