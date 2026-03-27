import re

with open('denemevol2.mq5', 'r') as f:
    text = f.read()

# Make absolutely sure StringFormat is in there
text = re.sub(
    r'string peak_str_h1 = DoubleToString\(mp_h1, 0\);\s*string bounce_str_h1 = DoubleToString\(mp_h1 - p_h1, 0\);\s*string stats_h1 = "\[Z:%" \+ peak_str_h1 \+ " Ç:%" \+ bounce_str_h1 \+ "\] ";',
    r'string stats_h1 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_h1, (mp_h1 - p_h1));',
    text
)

text = re.sub(
    r'string peak_str_m30 = DoubleToString\(mp_m30, 0\);\s*string bounce_str_m30 = DoubleToString\(mp_m30 - p_m30, 0\);\s*string stats_m30 = "\[Z:%" \+ peak_str_m30 \+ " Ç:%" \+ bounce_str_m30 \+ "\] ";',
    r'string stats_m30 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_m30, (mp_m30 - p_m30));',
    text
)

text = re.sub(
    r'string peak_str_m15 = DoubleToString\(mp_m15, 0\);\s*string bounce_str_m15 = DoubleToString\(mp_m15 - p_m15, 0\);\s*string stats_m15 = "\[Z:%" \+ peak_str_m15 \+ " Ç:%" \+ bounce_str_m15 \+ "\] ";',
    r'string stats_m15 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_m15, (mp_m15 - p_m15));',
    text
)

# And check if it's currently using the DoubleToString(1) variant
text = re.sub(
    r'string peak_str_h1 = DoubleToString\(mp_h1, 1\);\s*string bounce_str_h1 = DoubleToString\(mp_h1 - p_h1, 1\);\s*string stats_h1 = "\[Zirve:%" \+ peak_str_h1 \+ " \| Çekilme:%" \+ bounce_str_h1 \+ "\] ";',
    r'string stats_h1 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_h1, (mp_h1 - p_h1));',
    text
)

text = re.sub(
    r'string peak_str_m30 = DoubleToString\(mp_m30, 1\);\s*string bounce_str_m30 = DoubleToString\(mp_m30 - p_m30, 1\);\s*string stats_m30 = "\[Zirve:%" \+ peak_str_m30 \+ " \| Çekilme:%" \+ bounce_str_m30 \+ "\] ";',
    r'string stats_m30 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_m30, (mp_m30 - p_m30));',
    text
)

text = re.sub(
    r'string peak_str_m15 = DoubleToString\(mp_m15, 1\);\s*string bounce_str_m15 = DoubleToString\(mp_m15 - p_m15, 1\);\s*string stats_m15 = "\[Zirve:%" \+ peak_str_m15 \+ " \| Çekilme:%" \+ bounce_str_m15 \+ "\] ";',
    r'string stats_m15 = StringFormat("[Zirve:%%.1f | Çekilme:%%.1f] ", mp_m15, (mp_m15 - p_m15));',
    text
)

with open('denemevol2.mq5', 'w') as f:
    f.write(text)
