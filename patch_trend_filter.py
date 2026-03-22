import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Bearish tracking is for Down Trends!
# Previously it was: if (state.maj_tr == 1 && in_pullback_zone)
# But a Bearish CHoCH should align with a Bearish Major trend (state.maj_tr == -1) according to user "Aşşağı ise aşşağı"
search_bear_track = "         // CHoCH Bearish sequence tracking\n         if (state.maj_tr == 1 && in_pullback_zone) {"
replace_bear_track = "         // CHoCH Bearish sequence tracking\n         if (state.maj_tr == -1 && in_pullback_zone) {"
content = content.replace(search_bear_track, replace_bear_track)

# Bullish tracking is for Up Trends!
# Previously it was: if (state.maj_tr == -1 && in_pullback_zone)
search_bull_track = "         // CHoCH Bullish sequence tracking\n         if (state.maj_tr == -1 && in_pullback_zone) {"
replace_bull_track = "         // CHoCH Bullish sequence tracking\n         if (state.maj_tr == 1 && in_pullback_zone) {"
content = content.replace(search_bull_track, replace_bull_track)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Trend filter applied")
