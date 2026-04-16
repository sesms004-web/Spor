import re

with open('smcvol01.mq5', 'r') as f:
    content = f.read()

# Ah! ProcessBar calculates `state.last_choch_dir` and saves it.
# Let me search for where `state.last_choch_dir` is assigned in ProcessBar.
