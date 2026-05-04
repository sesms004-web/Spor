import re

with open('mt009.mq5', 'r') as f:
    code = f.read()

# Add safety check at the top of EvaluateTradeSignal
safety_check = """   if (p_m5 == 0.0 && p_m15 == 0.0 && p_h1 == 0.0) {
       Print("⚠️ Tüm MTF verileri 0.0 (Sınır Dışı / Hata). İşlem iptal edildi.");
       return;
   }"""

insert_point = "   int total_points = 0;"
code = code.replace(insert_point, safety_check + "\n\n" + insert_point)

# Fix the sequence validation bug that allows #2 to execute after ResetBearishMemory
# "if (g_trade_count_h > 0 && g_trade_count_h < 5) { int prev_i = g_trade_count_h - 1; ... }"
# Wait, if `g_trade_count_h` resets, it loses the memory of the OLD `t1` and `t2` extremes!
# To preserve the memory across dynamic `maj_h_i` updates:
# We should NOT call `ResetBearishMemory()` when `state.maj_h_i` updates within the SAME BEARISH TREND!
# Wait, `state.maj_h_i` ONLY updates when the trend flips.
# If the trend flips to BULLISH, it becomes a BULLISH major wave!
# If it flips back to BEARISH, it is a NEW BEARISH major wave!
# If it is a NEW bearish major wave, `g_trade_count_h` MUST reset!
# BUT the user thinks it's the SAME major wave! ("aynı swing içersinde").
# Why does the user think it's the same major wave?
# Because the "flip" to bullish was probably a TINY micro-swing (a glitch) that immediately flipped back to bearish.
# So the algorithm technically started a NEW wave, but the user visually sees ONE wave.
# Because the algorithm started a new wave, `ResetBearishMemory` was called.
# And because it started a new wave, the NEW CHoCH is considered `#1` in the new wave (or `#2` if it happened twice).
# Wait! If it's a NEW wave, the FIRST CHoCH should be `#1`. Why was it `#2` ?
# Ah... If the first CHoCH in the new wave was #1, and then it formed ANOTHER CHoCH in the same new wave, that would be #2!
# And because the new wave is just a glitch, the price is already far away from the MTF extremes, causing `p_xx = 0.0`!

with open('mt009.mq5', 'w') as f:
    f.write(code)
