import re

with open('smcvol01.mq5', 'r') as f:
    content = f.read()

# 1. Change GetMTFChochDetails to use ProcessBarMathOnly
# GetMTFChochDetails currently does:
# ProcessBar(i, open, high, low, close, time, st, true, false);
# We must use ProcessBarMathOnly(i, high, low, close, time, st);
content = content.replace("ProcessBar(i, open, high, low, close, time, st, true, false);", "ProcessBarMathOnly(i, high, low, close, time, st);")

# 2. Fix the missing `else` block in matrix so it isn't completely empty if c_dir == 0
matrix_old_buy = """   if (trigger_dir == 1) { // M1 BUY
       if (c_dir_h1 == 1 && valid_h1) { h1_sup_points = 20; h1_sup_text = "🟢 H1 Yukarı + Geçerli -> [+20 Puan]\\n"; }
       else if (c_dir_h1 == 1 && !valid_h1) { h1_sup_points = -20; h1_sup_text = "🔴 H1 Yukarı + Geçersiz (Tuzak) -> [-20 Puan]\\n"; }
       else if (c_dir_h1 == -1 && valid_h1) { h1_sup_points = -20; h1_sup_text = "🔴 H1 Aşağı + Geçerli -> [-20 Puan]\\n"; }
       else if (c_dir_h1 == -1 && !valid_h1) { h1_sup_points = 20; h1_sup_text = "🟢 H1 Aşağı + Geçersiz (Tuzak) -> [+20 Puan]\\n"; }

       if (c_dir_m30 == 1 && valid_m30) { m30_sup_points = 15; m30_sup_text = "🟢 M30 Yukarı + Geçerli -> [+15 Puan]\\n"; }
       else if (c_dir_m30 == 1 && !valid_m30) { m30_sup_points = -15; m30_sup_text = "🔴 M30 Yukarı + Geçersiz (Tuzak) -> [-15 Puan]\\n"; }
       else if (c_dir_m30 == -1 && valid_m30) { m30_sup_points = -15; m30_sup_text = "🔴 M30 Aşağı + Geçerli -> [-15 Puan]\\n"; }
       else if (c_dir_m30 == -1 && !valid_m30) { m30_sup_points = 15; m30_sup_text = "🟢 M30 Aşağı + Geçersiz (Tuzak) -> [+15 Puan]\\n"; }

       if (c_dir_m15 == 1 && valid_m15) { m15_sup_points = 10; m15_sup_text = "🟢 M15 Yukarı + Geçerli -> [+10 Puan]\\n"; }
       else if (c_dir_m15 == 1 && !valid_m15) { m15_sup_points = -10; m15_sup_text = "🔴 M15 Yukarı + Geçersiz (Tuzak) -> [-10 Puan]\\n"; }
       else if (c_dir_m15 == -1 && valid_m15) { m15_sup_points = -10; m15_sup_text = "🔴 M15 Aşağı + Geçerli -> [-10 Puan]\\n"; }
       else if (c_dir_m15 == -1 && !valid_m15) { m15_sup_points = 10; m15_sup_text = "🟢 M15 Aşağı + Geçersiz (Tuzak) -> [+10 Puan]\\n"; }

       if (c_dir_m5 == 1 && valid_m5) { m5_sup_points = 5; m5_sup_text = "🟢 M5 Yukarı + Geçerli -> [+5 Puan]\\n"; }
       else if (c_dir_m5 == 1 && !valid_m5) { m5_sup_points = -5; m5_sup_text = "🔴 M5 Yukarı + Geçersiz (Tuzak) -> [-5 Puan]\\n"; }
       else if (c_dir_m5 == -1 && valid_m5) { m5_sup_points = -5; m5_sup_text = "🔴 M5 Aşağı + Geçerli -> [-5 Puan]\\n"; }
       else if (c_dir_m5 == -1 && !valid_m5) { m5_sup_points = 5; m5_sup_text = "🟢 M5 Aşağı + Geçersiz (Tuzak) -> [+5 Puan]\\n"; }
   } else { // M1 SELL"""

matrix_new_buy = """   if (trigger_dir == 1) { // M1 BUY
       if (c_dir_h1 == 1 && valid_h1) { h1_sup_points = 20; h1_sup_text = "🟢 H1 Yukarı + Geçerli -> [+20 Puan]\\n"; }
       else if (c_dir_h1 == 1 && !valid_h1) { h1_sup_points = -20; h1_sup_text = "🔴 H1 Yukarı + Geçersiz (Tuzak) -> [-20 Puan]\\n"; }
       else if (c_dir_h1 == -1 && valid_h1) { h1_sup_points = -20; h1_sup_text = "🔴 H1 Aşağı + Geçerli -> [-20 Puan]\\n"; }
       else if (c_dir_h1 == -1 && !valid_h1) { h1_sup_points = 20; h1_sup_text = "🟢 H1 Aşağı + Geçersiz (Tuzak) -> [+20 Puan]\\n"; }
       else { h1_sup_text = "⚪ H1 Veri Bekleniyor... -> [0 Puan]\\n"; }

       if (c_dir_m30 == 1 && valid_m30) { m30_sup_points = 15; m30_sup_text = "🟢 M30 Yukarı + Geçerli -> [+15 Puan]\\n"; }
       else if (c_dir_m30 == 1 && !valid_m30) { m30_sup_points = -15; m30_sup_text = "🔴 M30 Yukarı + Geçersiz (Tuzak) -> [-15 Puan]\\n"; }
       else if (c_dir_m30 == -1 && valid_m30) { m30_sup_points = -15; m30_sup_text = "🔴 M30 Aşağı + Geçerli -> [-15 Puan]\\n"; }
       else if (c_dir_m30 == -1 && !valid_m30) { m30_sup_points = 15; m30_sup_text = "🟢 M30 Aşağı + Geçersiz (Tuzak) -> [+15 Puan]\\n"; }
       else { m30_sup_text = "⚪ M30 Veri Bekleniyor... -> [0 Puan]\\n"; }

       if (c_dir_m15 == 1 && valid_m15) { m15_sup_points = 10; m15_sup_text = "🟢 M15 Yukarı + Geçerli -> [+10 Puan]\\n"; }
       else if (c_dir_m15 == 1 && !valid_m15) { m15_sup_points = -10; m15_sup_text = "🔴 M15 Yukarı + Geçersiz (Tuzak) -> [-10 Puan]\\n"; }
       else if (c_dir_m15 == -1 && valid_m15) { m15_sup_points = -10; m15_sup_text = "🔴 M15 Aşağı + Geçerli -> [-10 Puan]\\n"; }
       else if (c_dir_m15 == -1 && !valid_m15) { m15_sup_points = 10; m15_sup_text = "🟢 M15 Aşağı + Geçersiz (Tuzak) -> [+10 Puan]\\n"; }
       else { m15_sup_text = "⚪ M15 Veri Bekleniyor... -> [0 Puan]\\n"; }

       if (c_dir_m5 == 1 && valid_m5) { m5_sup_points = 5; m5_sup_text = "🟢 M5 Yukarı + Geçerli -> [+5 Puan]\\n"; }
       else if (c_dir_m5 == 1 && !valid_m5) { m5_sup_points = -5; m5_sup_text = "🔴 M5 Yukarı + Geçersiz (Tuzak) -> [-5 Puan]\\n"; }
       else if (c_dir_m5 == -1 && valid_m5) { m5_sup_points = -5; m5_sup_text = "🔴 M5 Aşağı + Geçerli -> [-5 Puan]\\n"; }
       else if (c_dir_m5 == -1 && !valid_m5) { m5_sup_points = 5; m5_sup_text = "🟢 M5 Aşağı + Geçersiz (Tuzak) -> [+5 Puan]\\n"; }
       else { m5_sup_text = "⚪ M5 Veri Bekleniyor... -> [0 Puan]\\n"; }
   } else { // M1 SELL"""

matrix_old_sell = """   } else { // M1 SELL
       if (c_dir_h1 == -1 && valid_h1) { h1_sup_points = 20; h1_sup_text = "🔴 H1 Aşağı + Geçerli -> [+20 Puan]\\n"; }
       else if (c_dir_h1 == -1 && !valid_h1) { h1_sup_points = -20; h1_sup_text = "🟢 H1 Aşağı + Geçersiz (Tuzak) -> [-20 Puan]\\n"; }
       else if (c_dir_h1 == 1 && valid_h1) { h1_sup_points = -20; h1_sup_text = "🟢 H1 Yukarı + Geçerli -> [-20 Puan]\\n"; }
       else if (c_dir_h1 == 1 && !valid_h1) { h1_sup_points = 20; h1_sup_text = "🔴 H1 Yukarı + Geçersiz (Tuzak) -> [+20 Puan]\\n"; }

       if (c_dir_m30 == -1 && valid_m30) { m30_sup_points = 15; m30_sup_text = "🔴 M30 Aşağı + Geçerli -> [+15 Puan]\\n"; }
       else if (c_dir_m30 == -1 && !valid_m30) { m30_sup_points = -15; m30_sup_text = "🟢 M30 Aşağı + Geçersiz (Tuzak) -> [-15 Puan]\\n"; }
       else if (c_dir_m30 == 1 && valid_m30) { m30_sup_points = -15; m30_sup_text = "🟢 M30 Yukarı + Geçerli -> [-15 Puan]\\n"; }
       else if (c_dir_m30 == 1 && !valid_m30) { m30_sup_points = 15; m30_sup_text = "🔴 M30 Yukarı + Geçersiz (Tuzak) -> [+15 Puan]\\n"; }

       if (c_dir_m15 == -1 && valid_m15) { m15_sup_points = 10; m15_sup_text = "🔴 M15 Aşağı + Geçerli -> [+10 Puan]\\n"; }
       else if (c_dir_m15 == -1 && !valid_m15) { m15_sup_points = -10; m15_sup_text = "🟢 M15 Aşağı + Geçersiz (Tuzak) -> [-10 Puan]\\n"; }
       else if (c_dir_m15 == 1 && valid_m15) { m15_sup_points = -10; m15_sup_text = "🟢 M15 Yukarı + Geçerli -> [-10 Puan]\\n"; }
       else if (c_dir_m15 == 1 && !valid_m15) { m15_sup_points = 10; m15_sup_text = "🔴 M15 Yukarı + Geçersiz (Tuzak) -> [+10 Puan]\\n"; }

       if (c_dir_m5 == -1 && valid_m5) { m5_sup_points = 5; m5_sup_text = "🔴 M5 Aşağı + Geçerli -> [+5 Puan]\\n"; }
       else if (c_dir_m5 == -1 && !valid_m5) { m5_sup_points = -5; m5_sup_text = "🟢 M5 Aşağı + Geçersiz (Tuzak) -> [-5 Puan]\\n"; }
       else if (c_dir_m5 == 1 && valid_m5) { m5_sup_points = -5; m5_sup_text = "🟢 M5 Yukarı + Geçerli -> [-5 Puan]\\n"; }
       else if (c_dir_m5 == 1 && !valid_m5) { m5_sup_points = 5; m5_sup_text = "🔴 M5 Yukarı + Geçersiz (Tuzak) -> [+5 Puan]\\n"; }
   }

   total_points += h1_sup_points + m30_sup_points + m15_sup_points + m5_sup_points;"""

matrix_new_sell = """   } else { // M1 SELL
       if (c_dir_h1 == -1 && valid_h1) { h1_sup_points = 20; h1_sup_text = "🔴 H1 Aşağı + Geçerli -> [+20 Puan]\\n"; }
       else if (c_dir_h1 == -1 && !valid_h1) { h1_sup_points = -20; h1_sup_text = "🟢 H1 Aşağı + Geçersiz (Tuzak) -> [-20 Puan]\\n"; }
       else if (c_dir_h1 == 1 && valid_h1) { h1_sup_points = -20; h1_sup_text = "🟢 H1 Yukarı + Geçerli -> [-20 Puan]\\n"; }
       else if (c_dir_h1 == 1 && !valid_h1) { h1_sup_points = 20; h1_sup_text = "🔴 H1 Yukarı + Geçersiz (Tuzak) -> [+20 Puan]\\n"; }
       else { h1_sup_text = "⚪ H1 Veri Bekleniyor... -> [0 Puan]\\n"; }

       if (c_dir_m30 == -1 && valid_m30) { m30_sup_points = 15; m30_sup_text = "🔴 M30 Aşağı + Geçerli -> [+15 Puan]\\n"; }
       else if (c_dir_m30 == -1 && !valid_m30) { m30_sup_points = -15; m30_sup_text = "🟢 M30 Aşağı + Geçersiz (Tuzak) -> [-15 Puan]\\n"; }
       else if (c_dir_m30 == 1 && valid_m30) { m30_sup_points = -15; m30_sup_text = "🟢 M30 Yukarı + Geçerli -> [-15 Puan]\\n"; }
       else if (c_dir_m30 == 1 && !valid_m30) { m30_sup_points = 15; m30_sup_text = "🔴 M30 Yukarı + Geçersiz (Tuzak) -> [+15 Puan]\\n"; }
       else { m30_sup_text = "⚪ M30 Veri Bekleniyor... -> [0 Puan]\\n"; }

       if (c_dir_m15 == -1 && valid_m15) { m15_sup_points = 10; m15_sup_text = "🔴 M15 Aşağı + Geçerli -> [+10 Puan]\\n"; }
       else if (c_dir_m15 == -1 && !valid_m15) { m15_sup_points = -10; m15_sup_text = "🟢 M15 Aşağı + Geçersiz (Tuzak) -> [-10 Puan]\\n"; }
       else if (c_dir_m15 == 1 && valid_m15) { m15_sup_points = -10; m15_sup_text = "🟢 M15 Yukarı + Geçerli -> [-10 Puan]\\n"; }
       else if (c_dir_m15 == 1 && !valid_m15) { m15_sup_points = 10; m15_sup_text = "🔴 M15 Yukarı + Geçersiz (Tuzak) -> [+10 Puan]\\n"; }
       else { m15_sup_text = "⚪ M15 Veri Bekleniyor... -> [0 Puan]\\n"; }

       if (c_dir_m5 == -1 && valid_m5) { m5_sup_points = 5; m5_sup_text = "🔴 M5 Aşağı + Geçerli -> [+5 Puan]\\n"; }
       else if (c_dir_m5 == -1 && !valid_m5) { m5_sup_points = -5; m5_sup_text = "🟢 M5 Aşağı + Geçersiz (Tuzak) -> [-5 Puan]\\n"; }
       else if (c_dir_m5 == 1 && valid_m5) { m5_sup_points = -5; m5_sup_text = "🟢 M5 Yukarı + Geçerli -> [-5 Puan]\\n"; }
       else if (c_dir_m5 == 1 && !valid_m5) { m5_sup_points = 5; m5_sup_text = "🔴 M5 Yukarı + Geçersiz (Tuzak) -> [+5 Puan]\\n"; }
       else { m5_sup_text = "⚪ M5 Veri Bekleniyor... -> [0 Puan]\\n"; }
   }

   total_points += h1_sup_points + m30_sup_points + m15_sup_points + m5_sup_points;"""


content = content.replace(matrix_old_buy, matrix_new_buy)
content = content.replace(matrix_old_sell, matrix_new_sell)


with open('smcvol01.mq5', 'w') as f:
    f.write(content)
