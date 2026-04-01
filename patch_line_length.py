import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Current drawing code for Bearish CHoCH:
# DrawLine(choch_name, time[state.lp_i], state.d1_l, time[i] + PeriodSeconds(), state.d1_l, InpColorChochBear, 2, STYLE_SOLID, true);

search_bear = """              string choch_name = GetUniqueName(prefix + "CHoCH_Bear_");
              DrawLine(choch_name, time[state.lp_i], state.d1_l, time[i] + PeriodSeconds(), state.d1_l, InpColorChochBear, 2, STYLE_SOLID, true);"""

# Replace with short horizontal line (from the start of the swing to 5 bars after breakout)
replace_bear = """              string choch_name = GetUniqueName(prefix + "CHoCH_Bear_");
              DrawLine(choch_name, time[state.lp_i], state.d1_l, time[i] + PeriodSeconds() * 5, state.d1_l, InpColorChochBear, 2, STYLE_SOLID, false);"""

content = content.replace(search_bear, replace_bear)

# Current drawing code for Bullish CHoCH:
# DrawLine(choch_name, time[state.lp_i], state.d1_h, time[i] + PeriodSeconds(), state.d1_h, InpColorChochBull, 2, STYLE_SOLID, true);

search_bull = """              string choch_name = GetUniqueName(prefix + "CHoCH_Bull_");
              DrawLine(choch_name, time[state.lp_i], state.d1_h, time[i] + PeriodSeconds(), state.d1_h, InpColorChochBull, 2, STYLE_SOLID, true);"""

replace_bull = """              string choch_name = GetUniqueName(prefix + "CHoCH_Bull_");
              DrawLine(choch_name, time[state.lp_i], state.d1_h, time[i] + PeriodSeconds() * 5, state.d1_h, InpColorChochBull, 2, STYLE_SOLID, false);"""

content = content.replace(search_bull, replace_bull)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Line length patched")
