# Look at `GenerateMTFChochReport`
#     reports[i].tf = tfs[i];
#     GetMTFChochDetails(tfs[i], t, reports[i].dir, reports[i].level, reports[i].time);
# And look at `EvaluateTradeSignal`:
#   GetMTFChochDetails(PERIOD_H1, t, c_dir_h1, c_lvl_h1, c_t_h1);
#   GetMTFChochDetails(PERIOD_M30, t, c_dir_m30, c_lvl_m30, c_t_m30);
#   GetMTFChochDetails(PERIOD_M15, t, c_dir_m15, c_lvl_m15, c_t_m15);
#   GetMTFChochDetails(PERIOD_M5, t, c_dir_m5, c_lvl_m5, c_t_m5);
# THIS IS IDENTICAL!!!

# IF THEY ARE IDENTICAL, THE ONLY DIFFERENCE IS IN `EvaluateTradeSignal`'s DISPLAY LOGIC!!
# `if (trigger_dir == 1) { // M1 BUY`
# wait!
# If it says "H1 Veri Bekleniyor... -> [0 Puan]", it means `trigger_dir` is NOT 0. It is 1 or -1.
# What is `c_dir_h1`? It must be 0!
# Why would `c_dir_h1` be 0?
# In `EvaluateTradeSignal`, wait...
# Are `c_dir_h1, c_lvl_h1, c_t_h1` initialized as 0? YES.
# If `GetMTFChochDetails` executes, it sets `c_dir_h1 = st.last_choch_dir` (which is 1 or -1).
# HOW IS IT NOT SETTING IT?
# Because `GetMTFChochDetails` IS RETURNING EARLY!
# WHY would it return early in `EvaluateTradeSignal` but not in `GenerateMTFChochReport`??
# The ONLY difference is `t = time[i]` vs `t = TimeCurrent()`.
# When does the CHoCH alert trigger?
# `EvaluateTradeSignal(i, time[i], val_c, 1, p_pct, is_strong, state.t2_l, state.maj_l_i);`
# `time[i]` is the exact OPEN TIME of the current M1 bar! (e.g. `2024.04.16 10:30:00`)
# BUT `CopyRates` inside `GetMTFChochDetails`:
# `CopyRates(Symbol(), tf, anchor_time, current_time, rates);`
# `anchor_time` = `time[i] - 180 days`.
# IF `current_time` is EXACTLY an open time (like `time[i]`), `CopyRates` copies the bars.
# WAIT.
# Does `CopyRates` include the currently forming bar if you use exactly `time[i]`?
# Yes! `time[i]` is the exact open time.
# But does MT5 cache the history?
# Yes.
# Does it return `< 2`?
# NO, if it returned `< 2`, `GenerateMTFChochReport` would ALSO fail if clicked right after the alert!

# I MUST find where `c_dir` gets set to 0.
# Wait! In `GetMTFChochDetails`:
#    st.last_choch_dir = 0;
#    for(int i = 1; i < copied; i++) {
#       ProcessBar(...)
#    }
# Is `ProcessBar` somehow overriding `last_choch_dir` to 0?
# `ProcessBar` NEVER sets `last_choch_dir = 0`.
# Is `ProcessBar` SKIPPING `last_choch_dir = 1` entirely because of `draw_ui`?
# Let's check `ProcessBar` line 383 (MAJOR CHOCH)
