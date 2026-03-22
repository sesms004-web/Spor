import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# I need to ensure that the Mother bar fields are correctly initialized in OnCalculate when the first loop starts.
init_search = """      g_state_hist.mb_h = high[start_idx];
      g_state_hist.mb_l = low[start_idx];
      g_state_hist.mb_i = start_idx;"""

# check if we have it
print("has mb init in start:", "mb_h" in content and "start_idx" in content)

init_replace = """      g_state_hist.mb_h = high[start_idx];
      g_state_hist.mb_l = low[start_idx];
      g_state_hist.mb_i = start_idx;

      g_state_hist.t1_h = 0; g_state_hist.t1_l = 0;
      g_state_hist.d1_h = 0; g_state_hist.d1_l = 0;
      g_state_hist.t2_h = 0; g_state_hist.t2_l = 0;
      g_state_hist.choch_dir = 0;"""

# Add it around line 1250 (inside `if(prev_calculated == 0)`)
search_str2 = """      g_state_hist.anc_v   = close[start_idx];
      g_state_hist.lp_i    = start_idx;
      g_state_hist.lp_p    = close[start_idx];"""

replace_str2 = """      g_state_hist.anc_v   = close[start_idx];
      g_state_hist.lp_i    = start_idx;
      g_state_hist.lp_p    = close[start_idx];

      g_state_hist.mb_h = high[start_idx];
      g_state_hist.mb_l = low[start_idx];
      g_state_hist.mb_i = start_idx;

      g_state_hist.t1_h = 0; g_state_hist.t1_l = 0;
      g_state_hist.d1_h = 0; g_state_hist.d1_l = 0;
      g_state_hist.t2_h = 0; g_state_hist.t2_l = 0;
      g_state_hist.choch_dir = 0;"""

content = content.replace(search_str2, replace_str2)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Init injected")
