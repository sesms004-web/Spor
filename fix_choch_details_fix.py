# If ProcessBar math logic evaluates CHOCH, and c_dir_h1 = st.last_choch_dir ...
# Wait. If c_dir_h1 was defaulting to 0, my last commit already added the `else` fallback:
# `else { h1_sup_text = "⚪ H1 Veri Bekleniyor... -> [0 Puan]\n"; }`
# Did the user say "hala bos" because it outputs "⚪ H1 Veri Bekleniyor..." instead of the logic?
# If it outputs "Veri Bekleniyor", it means it's returning 0!
# Why would it return 0?
# Let's check `st.last_choch_dir = 0;`
# ProcessBar inside `GetMTFChochDetails`:
# `ProcessBar(i, open, high, low, close, time, st, true, false);`
# Let's check what `is_history = true` does in ProcessBar!
