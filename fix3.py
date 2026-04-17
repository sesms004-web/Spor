with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Add the two missing closing braces
text = text.replace('g_last_alert_trend = g_state_hist.maj_tr;\n           }\n\n         \n\n\n   static uint last_dash_update = 0;', 'g_last_alert_trend = g_state_hist.maj_tr;\n           }\n        }\n     }\n\n\n   static uint last_dash_update = 0;')
text = text.replace('return(rates_total);\n}\n}\n}', 'return(rates_total);\n}')

with open('smacv1.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
