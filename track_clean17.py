import re
with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's find the start of the junk code
idx = text.find('   string swing_dir = t_m1 == 1 ? "🟢 YUKARI" : "🔴 AŞAĞI";\n   datetime start_t = t_m1 == 1 ? tl_m1 : th_m1;')
if idx != -1:
    end_idx = text.find('   g_alert_bar_index = current_bar_i;\n   return true;\n  }', idx)
    if end_idx != -1:
        text = text[:idx] + text[end_idx+56:]

with open('smacv1.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
