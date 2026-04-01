import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# H1 String Patch
search_h1 = """   string peak_str_h1 = DoubleToString(mp_h1, 0);
   string bounce_str_h1 = DoubleToString(mp_h1 - p_h1, 0);
   string stats_h1 = "[Z:%" + peak_str_h1 + " Ç:%" + bounce_str_h1 + "] ";"""

replace_h1 = """   string peak_str_h1 = DoubleToString(mp_h1, 1);
   string bounce_str_h1 = DoubleToString(mp_h1 - p_h1, 1);
   string stats_h1 = "[Zirve:%" + peak_str_h1 + " | Çekilme:%" + bounce_str_h1 + "] ";"""

content = content.replace(search_h1, replace_h1)

# M30 String Patch
search_m30 = """   string peak_str_m30 = DoubleToString(mp_m30, 0);
   string bounce_str_m30 = DoubleToString(mp_m30 - p_m30, 0);
   string stats_m30 = "[Z:%" + peak_str_m30 + " Ç:%" + bounce_str_m30 + "] ";"""

replace_m30 = """   string peak_str_m30 = DoubleToString(mp_m30, 1);
   string bounce_str_m30 = DoubleToString(mp_m30 - p_m30, 1);
   string stats_m30 = "[Zirve:%" + peak_str_m30 + " | Çekilme:%" + bounce_str_m30 + "] ";"""

content = content.replace(search_m30, replace_m30)

# M15 String Patch
search_m15 = """   string peak_str_m15 = DoubleToString(mp_m15, 0);
   string bounce_str_m15 = DoubleToString(mp_m15 - p_m15, 0);
   string stats_m15 = "[Z:%" + peak_str_m15 + " Ç:%" + bounce_str_m15 + "] ";"""

replace_m15 = """   string peak_str_m15 = DoubleToString(mp_m15, 1);
   string bounce_str_m15 = DoubleToString(mp_m15 - p_m15, 1);
   string stats_m15 = "[Zirve:%" + peak_str_m15 + " | Çekilme:%" + bounce_str_m15 + "] ";"""

content = content.replace(search_m15, replace_m15)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Decimals patched")
