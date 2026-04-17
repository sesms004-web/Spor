# If it never hits, it means `copied` is tiny, or the logic `is_history = true` skips structure updating.
# Wait.
# Look at `st.last_choch_dir = 0;` inside `GetMTFChochDetails`!
# We set `st.last_choch_dir = 0;` AFTER the `ProcessBar` loop?
# Let's check `GetMTFChochDetails` AGAIN!
