import re
with open('mt009.mq5', 'r') as f:
    code = f.read()

# Fix the duplicate insertions again correctly
code = code.replace("""   if (p_h1 == 0.0 && mp_h1 == 0.0) {
       h1_points = 0; h1_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
   } else if (p_h1 == 0.0 && mp_h1 == 0.0) {
       h1_points = 0; h1_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
   } else""", """   if (p_h1 == 0.0 && mp_h1 == 0.0) {
       h1_points = 0; h1_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
   } else""")

code = code.replace("""       if (p_m30 == 0.0 && mp_m30 == 0.0) {
           m30_points = 0; m30_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else if (p_m30 == 0.0 && mp_m30 == 0.0) {
           m30_points = 0; m30_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else""", """       if (p_m30 == 0.0 && mp_m30 == 0.0) {
           m30_points = 0; m30_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else""")

code = code.replace("""       if (p_m15 == 0.0 && mp_m15 == 0.0) {
           m15_points = 0; m15_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else if (p_m15 == 0.0 && mp_m15 == 0.0) {
           m15_points = 0; m15_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else""", """       if (p_m15 == 0.0 && mp_m15 == 0.0) {
           m15_points = 0; m15_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else""")

code = code.replace("""       if (p_m5 == 0.0 && mp_m5 == 0.0) {
           m5_points = 0; m5_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else if (p_m5 == 0.0 && mp_m5 == 0.0) {
           m5_points = 0; m5_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else""", """       if (p_m5 == 0.0 && mp_m5 == 0.0) {
           m5_points = 0; m5_text = "⚠️ Veri Yok / Trend Dışı -> [0 Puan]\\n";
       } else""")

with open('mt009.mq5', 'w') as f:
    f.write(code)
