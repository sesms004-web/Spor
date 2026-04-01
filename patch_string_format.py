import re

# We need to process part2.txt where the EvaluateTradeSignal function is located.
with open('denemevol1_part2.txt', 'r') as f:
    content = f.read()

# H1 StringFormat Rewrite
search_h1 = """   string peak_str_h1 = DoubleToString(mp_h1, 1);
   string bounce_str_h1 = DoubleToString(mp_h1 - p_h1, 1);
   string stats_h1 = "[Zirve:%" + peak_str_h1 + " | Çekilme:%" + bounce_str_h1 + "] ";"""

replace_h1 = """   string stats_h1 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_h1, (mp_h1 - p_h1));"""
content = content.replace(search_h1, replace_h1)

# M30 StringFormat Rewrite
search_m30 = """   string peak_str_m30 = DoubleToString(mp_m30, 1);
   string bounce_str_m30 = DoubleToString(mp_m30 - p_m30, 1);
   string stats_m30 = "[Zirve:%" + peak_str_m30 + " | Çekilme:%" + bounce_str_m30 + "] ";"""

replace_m30 = """   string stats_m30 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_m30, (mp_m30 - p_m30));"""
content = content.replace(search_m30, replace_m30)

# M15 StringFormat Rewrite
search_m15 = """   string peak_str_m15 = DoubleToString(mp_m15, 1);
   string bounce_str_m15 = DoubleToString(mp_m15 - p_m15, 1);
   string stats_m15 = "[Zirve:%" + peak_str_m15 + " | Çekilme:%" + bounce_str_m15 + "] ";"""

replace_m15 = """   string stats_m15 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_m15, (mp_m15 - p_m15));"""
content = content.replace(search_m15, replace_m15)

with open('denemevol1_part2.txt', 'w') as f:
    f.write(content)

print("StringFormat applied to part 2")
