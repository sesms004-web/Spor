import re

with open('smcvol01.mq5', 'r') as f:
    content = f.read()

# I will add `last_choch_dir` logic to ProcessBarMathOnly.
# But wait, `GetMTFChochDetails` uses `ProcessBarMathOnly`.
# I should just use `ProcessBar(i, open, high, low, close, time, state, false, false)`
# If `draw_ui == false`, `ProcessBar` will not draw any lines, but WILL calculate CHoCH properly!
# Let me verify ProcessBar signature:
# void ProcessBar(int i, const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], SState &state, bool is_history, bool draw_ui)
# Oh, that's exactly what I used: `ProcessBar(i, open, high, low, close, time, st, true, false);`
# But I changed it to `ProcessBarMathOnly` during my previous debugging session. Let's revert it!

content = content.replace("ProcessBarMathOnly(i, high, low, close, time, st);", "ProcessBar(i, open, high, low, close, time, st, true, false);")

with open('smcvol01.mq5', 'w') as f:
    f.write(content)
