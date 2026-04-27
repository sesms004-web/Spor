import re

with open('smcv1.mq5', 'r') as f:
    content = f.read()

# Replace initialization inside ProcessBarMathOnly and ProcessBar for bearish
content = content.replace("state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;", "state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;\n                 state.d2_h = 0; state.d2_l = 0; state.d2_i = 0;\n                 state.t3_h = 0; state.t3_l = 0; state.t3_i = 0;")

# Replace initialization inside ProcessBarMathOnly and ProcessBar for bullish
content = content.replace("state.t2_l = 0; state.t2_h = 0; state.t2_i = 0;", "state.t2_l = 0; state.t2_h = 0; state.t2_i = 0;\n                 state.d2_h = 0; state.d2_l = 0; state.d2_i = 0;\n                 state.t3_h = 0; state.t3_l = 0; state.t3_i = 0;")

# Replace global initialization
content = content.replace("g_state_hist.t2_h = 0; g_state_hist.t2_l = 0; g_state_hist.t2_i = 0;", "g_state_hist.t2_h = 0; g_state_hist.t2_l = 0; g_state_hist.t2_i = 0;\n      g_state_hist.d2_h = 0; g_state_hist.d2_l = 0; g_state_hist.d2_i = 0;\n      g_state_hist.t3_h = 0; g_state_hist.t3_l = 0; g_state_hist.t3_i = 0;")

with open('smcv1.mq5', 'w') as f:
    f.write(content)
