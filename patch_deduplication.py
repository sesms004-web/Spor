import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Fix the duplicate logic in EvaluateTradeSignal
search_duplicate = """   // --- M15 MODIFIER LOGIC (De-duplication) ---
   int m15_points = 0;
   bool m15_momentum = ((mp_m15 - p_m15) >= 20.0);
   bool is_m15_aligned = (t_m15 == trigger_dir);
   bool is_duplicate = (th_m15 == th_m30 && tl_m15 == tl_m30); // Same swing anchor"""

# Use prices instead of times to identify the same swing structure, as time anchors can vary slightly across timeframes (e.g. M30 bar covers two M15 bars).
# To account for floating-point inaccuracies, compare the absolute difference to the Point() value.
replace_duplicate = """   // --- M15 MODIFIER LOGIC (De-duplication) ---
   int m15_points = 0;
   bool m15_momentum = ((mp_m15 - p_m15) >= 20.0);
   bool is_m15_aligned = (t_m15 == trigger_dir);

   // Use MTF pullbacks to fetch the actual HIGH/LOW prices of the swings
   double h_m30, l_m30; datetime dmy1, dmy2;
   GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, h_m30, l_m30, dmy1, dmy2);
   double h_m15, l_m15;
   GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, h_m15, l_m15, dmy1, dmy2);

   // Determine if M15 and M30 are tracking the exact same structural swing bounds
   bool is_duplicate = (MathAbs(h_m15 - h_m30) < Point() * 5 && MathAbs(l_m15 - l_m30) < Point() * 5);"""

content = content.replace(search_duplicate, replace_duplicate)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("De-duplication patched")
