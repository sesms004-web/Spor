import re

with open('smcvol01.mq5', 'r') as f:
    content = f.read()

# Okay, it is applied. The issue must be that GetMTFChochDetails wasn't updating `last_choch_dir` because I had `ProcessBarMathOnly`.
# But wait, did I change `ProcessBarMathOnly` back to `ProcessBar` inside `GetMTFChochDetails` in `fix_choch_details2.py`? Let's verify.
