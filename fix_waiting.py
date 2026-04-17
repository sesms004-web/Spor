import re

with open('smcvol01.mq5', 'r') as f:
    content = f.read()

# The user is complaining that CHoCH Validity Report works and correctly prints everything
# But in the `EvaluateTradeSignal` function, it prints "Veri Bekleniyor..." for all of them.
# Why? Because `GetMTFChochDetails` is returning 0!
# Why is it returning 0?
# In `GetMTFChochDetails`:
# `st.last_choch_dir` is being evaluated inside the `ProcessBar` function.
# But `ProcessBar` sets `last_choch_dir` only when `draw_ui` is true, or maybe when `!is_history`?
# Let's check `ProcessBar` again!
