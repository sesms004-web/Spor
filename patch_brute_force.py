import re

with open('denemevol1.mq5', 'r') as f:
    text = f.read()

# Replace H1
text = re.sub(
    r'string peak_str_h1 = DoubleToString\(mp_h1, 0\);\s*string bounce_str_h1 = DoubleToString\(mp_h1 - p_h1, 0\);\s*string stats_h1 = "\[Z:%" \+ peak_str_h1 \+ " Ç:%" \+ bounce_str_h1 \+ "\] ";',
    r'string peak_str_h1 = DoubleToString(mp_h1, 1);\n   string bounce_str_h1 = DoubleToString(mp_h1 - p_h1, 1);\n   string stats_h1 = "[Zirve:%" + peak_str_h1 + " | Çekilme:%" + bounce_str_h1 + "] ";',
    text
)

# Replace M30
text = re.sub(
    r'string peak_str_m30 = DoubleToString\(mp_m30, 0\);\s*string bounce_str_m30 = DoubleToString\(mp_m30 - p_m30, 0\);\s*string stats_m30 = "\[Z:%" \+ peak_str_m30 \+ " Ç:%" \+ bounce_str_m30 \+ "\] ";',
    r'string peak_str_m30 = DoubleToString(mp_m30, 1);\n   string bounce_str_m30 = DoubleToString(mp_m30 - p_m30, 1);\n   string stats_m30 = "[Zirve:%" + peak_str_m30 + " | Çekilme:%" + bounce_str_m30 + "] ";',
    text
)

# Replace M15
text = re.sub(
    r'string peak_str_m15 = DoubleToString\(mp_m15, 0\);\s*string bounce_str_m15 = DoubleToString\(mp_m15 - p_m15, 0\);\s*string stats_m15 = "\[Z:%" \+ peak_str_m15 \+ " Ç:%" \+ bounce_str_m15 \+ "\] ";',
    r'string peak_str_m15 = DoubleToString(mp_m15, 1);\n   string bounce_str_m15 = DoubleToString(mp_m15 - p_m15, 1);\n   string stats_m15 = "[Zirve:%" + peak_str_m15 + " | Çekilme:%" + bounce_str_m15 + "] ";',
    text
)

with open('denemevol1.mq5', 'w') as f:
    f.write(text)
