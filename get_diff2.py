# The ONLY reason it's 0 is if `c_dir_h1` is NEVER SET!
# But look:
#   st.last_choch_dir = 0;
#   for(int i = 1; i < copied; i++) {
#      ProcessBar(i, _open, _high, _low, _close, _time, st, true, false);
#   }
# Does `ProcessBar` overwrite `last_choch_dir` with 0?
# No, `state.last_choch_dir` is only set to `1` or `-1`.
# So if it's 0, it means the `for` loop NEVER hit `last_choch_dir = 1` or `-1`!
# WHY would an H1 loop over 180 days NEVER hit a CHoCH?
# Is `copied` very small?
# Let's check `GetDaysForTF(tf)`!
