with open('denemevol1.mq5', 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    line = line.replace('string stats_h1 = "[Z:%" + peak_str_h1 + " Ç:%" + bounce_str_h1 + "] ";', 'string stats_h1 = "[Zirve:%" + peak_str_h1 + " | Çekilme:%" + bounce_str_h1 + "] ";')
    line = line.replace('string stats_m30 = "[Z:%" + peak_str_m30 + " Ç:%" + bounce_str_m30 + "] ";', 'string stats_m30 = "[Zirve:%" + peak_str_m30 + " | Çekilme:%" + bounce_str_m30 + "] ";')
    line = line.replace('string stats_m15 = "[Z:%" + peak_str_m15 + " Ç:%" + bounce_str_m15 + "] ";', 'string stats_m15 = "[Zirve:%" + peak_str_m15 + " | Çekilme:%" + bounce_str_m15 + "] ";')

    line = line.replace('DoubleToString(mp_h1, 0)', 'DoubleToString(mp_h1, 1)')
    line = line.replace('DoubleToString(mp_h1 - p_h1, 0)', 'DoubleToString(mp_h1 - p_h1, 1)')

    line = line.replace('DoubleToString(mp_m30, 0)', 'DoubleToString(mp_m30, 1)')
    line = line.replace('DoubleToString(mp_m30 - p_m30, 0)', 'DoubleToString(mp_m30 - p_m30, 1)')

    line = line.replace('DoubleToString(mp_m15, 0)', 'DoubleToString(mp_m15, 1)')
    line = line.replace('DoubleToString(mp_m15 - p_m15, 0)', 'DoubleToString(mp_m15 - p_m15, 1)')

    new_lines.append(line)

with open('denemevol1.mq5', 'w') as f:
    f.writelines(new_lines)
