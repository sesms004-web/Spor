# The user's problem has 2 parts:
# 1. "%40 altinda choch geliyor" -> The 40% rule is still failing to stop small pullbacks.
# 2. "3 4 5 olmuyo" -> The sequence only prints 1, 2, but 3,4,5 are not appearing.

# Let's tackle "3 4 5 olmuyo":
# My sequence check logic:
# if (g_trade_count_h == 0) valid_sequence = true;
# else if (g_trade_count_h > 0 && g_trade_count_h < 5) {
#     int prev_i = g_trade_count_h - 1;
#     double prev_peak = MathMax(g_trade_t1_h[prev_i], g_trade_t2_h[prev_i]);
#     if (state.t2_h > prev_peak) valid_sequence = true;
# }
# if (is_new_signal) {
#     if (valid_sequence && g_trade_count_h < 5) {
#         current_trade_index = g_trade_count_h;
#         g_trade_t1_h[current_trade_index] = state.t1_h;
#         g_trade_t2_h[current_trade_index] = state.t2_h;
#         g_trade_count_h++;
#     }
# }

# wait! `is_new_signal` is `(state.d1_i != last_alert_d1_i_bear)`.
# The very first CHoCH makes `g_trade_count_h` = 1. `current_trade_index` = 0.
# The second CHoCH comes along. `g_trade_count_h` is 1. `prev_i` = 0.
# `prev_peak` is the peak of the 0th trade.
# If `state.t2_h > prev_peak`, `valid_sequence` = true.
# Then `current_trade_index` = 1. `g_trade_count_h` becomes 2.
# Next signal! `g_trade_count_h` is 2. `prev_i` = 1.
# `prev_peak` is the peak of the 1st trade!
# If `state.t2_h > prev_peak`, `valid_sequence` = true.
# Then `current_trade_index` = 2. `g_trade_count_h` becomes 3.

# This logic is fundamentally perfect! WHY would it not reach 3, 4, 5?
# Maybe `is_new_signal` is not behaving right?
# If `!valid_sequence`, we do `current_trade_index = -1`.
# And we STILL DO:
# if (is_new_signal) {
#     last_alert_d1_i_bear = state.d1_i;
#     last_alert_maj_i_bear = state.maj_h_i;
# }
# This means if an invalid signal comes (a weak CHoCH that didn't sweep), it UPDATES `last_alert_d1_i_bear`.
# So the NEXT strong signal comes... but wait! If a weak signal breaks structure, the major anchor doesn't change, but D1 changes.
# If the weak signal updates `last_alert_d1_i_bear`, the next strong signal will be compared to it.
# BUT wait! If a strong signal comes in the same wave, does it create a NEW `state.d1_i`?
# YES, because every time a CHoCH line is broken, the price drops. To create a new CHoCH, it must rally again, create a new D1, drop to a new T2, and break D1.
# But what if `t2_pct >= 40.0` check FAILS?
# Ah! I did this:
# if (should_eval_bear) {
#     if (!t2_valid) {
#         state.choch_dir = 0;
#     } else {
#         ...
#     }
# }
# If `t2_valid` is false, it resets `choch_dir = 0` and DOES NOT process it.
# BUT wait! If `t2_pct` is wrong, it might process it anyway?

# Let's look closely at `t2_pct` calculation.
# range = state.maj_h - state.maj_l
# For bearish (price going down):
# maj_h is high. maj_l is low.
# t2_h is the peak of the rally.
# `t2_pct = ((state.t2_h - state.maj_l) / range) * 100.0`
# If price rallies from maj_l to t2_h, the distance is `state.t2_h - state.maj_l`.
# If `t2_h` equals `maj_h`, pct is 100%.
# If `t2_h` is halfway, pct is 50%.
# This is mathematically perfect! WHY is the 40% check failing?
# "Hala %40 muhabbet var ve 3 4 5 olmuyo"
# Oh... I understand.
# In the original code, the 40% pullback was calculated from the *current minor swing*, NOT from the major trend!
# Wait! Let's check `smcv1.mq5` again!
