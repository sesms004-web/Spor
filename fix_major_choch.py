import re

def main():
    with open("gist_code.mq5", "r", encoding="utf-8") as f:
        gist_content = f.read()

    with open("paste_code.mq5", "r", encoding="utf-8") as f:
        paste_content = f.read()

    content = gist_content

    # Add GetTimeSafe
    if "datetime GetTimeSafe" not in content:
        gettimesafe_func = """
datetime GetTimeSafe(const datetime &time_array[], int idx) {
    if (idx >= 0 && idx < ArraySize(time_array)) {
        return time_array[idx];
    }
    return 0;
}
"""
        content = re.sub(r'(#property.*?\n)\n', r'\1\n' + gettimesafe_func, content, count=1)

    p_trig_start = paste_content.find("   // CHoCH Trigger & Drawing Logic")
    p_trig_end = paste_content.find("   // MAJOR STRUCTURE", p_trig_start)

    # In Gist, look for "// CHoCH Trigger & Drawing Logic" since I replaced it in earlier scripts
    g_trig_start = gist_content.find("   // CHoCH Trigger & Drawing Logic")
    if g_trig_start == -1:
         # Try looking for "4. CHoCH"
         g_trig_start = gist_content.find("// 4. CHoCH")
         if g_trig_start != -1:
              g_trig_start = gist_content.rfind("   // ---------------------------------------------------------", 0, g_trig_start)

    g_trig_end = gist_content.find("   // MAJOR STRUCTURE", g_trig_start)

    if p_trig_start != -1 and g_trig_start != -1:
        paste_block = paste_content[p_trig_start:p_trig_end]

        # Manually patch MTF states into paste_block
        bear_anchor = "          // Bearish CHoCH confirmed!"
        bear_insert = """          // Bearish CHoCH confirmed!
          state.last_choch_dir = -1;
          state.last_choch_level = state.d1_l;
          state.last_choch_time = GetTimeSafe(time, i);
"""
        paste_block = paste_block.replace(bear_anchor, bear_insert)

        bull_anchor = "          // Bullish CHoCH confirmed!"
        bull_insert = """          // Bullish CHoCH confirmed!
          state.last_choch_dir = 1;
          state.last_choch_level = state.d1_h;
          state.last_choch_time = GetTimeSafe(time, i);
"""
        paste_block = paste_block.replace(bull_anchor, bull_insert)

        # Manually patch Evaluation and Retest into paste_block
        bear_old = """                  if (InpEnableTradeExecution) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, p_pct, is_strong);
                  }"""
        bear_new = """                  if (InpEnableTradeExecution) {
                      if (!InpWaitRetest) {
                          EvaluateTradeSignal(i, GetTimeSafe(time, i), val_c, -1, p_pct, is_strong, state.t2_h, state.maj_h_i);
                      } else {
                          g_pending_active = true;
                          g_pending_dir = -1;
                          g_pending_bar_i = i;
                          g_pending_sl = state.t2_h;
                          g_pending_is_strong = is_strong;
                          g_pending_p_pct = p_pct;
                          g_pending_maj_extreme_i = state.maj_h_i;
                          double dist = state.t2_h - state.d1_l;
                          g_pending_entry = state.d1_l + (dist * (InpRetestDepthPct / 100.0));
                      }
                  }"""
        paste_block = paste_block.replace(bear_old, bear_new)

        bull_old = """                  if (InpEnableTradeExecution) {
                      EvaluateTradeSignal(i, time[i], val_c, 1, p_pct, is_strong);
                  }"""
        bull_new = """                  if (InpEnableTradeExecution) {
                      if (!InpWaitRetest) {
                          EvaluateTradeSignal(i, GetTimeSafe(time, i), val_c, 1, p_pct, is_strong, state.t2_l, state.maj_l_i);
                      } else {
                          g_pending_active = true;
                          g_pending_dir = 1;
                          g_pending_bar_i = i;
                          g_pending_sl = state.t2_l;
                          g_pending_is_strong = is_strong;
                          g_pending_p_pct = p_pct;
                          g_pending_maj_extreme_i = state.maj_l_i;
                          double dist = state.d1_h - state.t2_l;
                          g_pending_entry = state.d1_h - (dist * (InpRetestDepthPct / 100.0));
                      }
                  }"""
        paste_block = paste_block.replace(bull_old, bull_new)

        content = content[:g_trig_start] + paste_block + content[g_trig_end:]
    else:
        print("Failed to replace Trigger Logic cleanly")

    # Wrap any leftover times
    content = re.sub(r'time\[state\.([a-zA-Z0-9_]+)\]', r'GetTimeSafe(time, state.\1)', content)
    content = re.sub(r'DrawLine\(([^,]+),\s*time\[i\]', r'DrawLine(\1, GetTimeSafe(time, i)', content)
    content = re.sub(r'DrawLine\(([^,]+),\s*GetTimeSafe\(time, state\.([a-zA-Z0-9_]+)\),\s*([^,]+),\s*time\[i\]', r'DrawLine(\1, GetTimeSafe(time, state.\2), \3, GetTimeSafe(time, i)', content)
    content = re.sub(r'time\[i\] \+ PeriodSeconds\(\) \* 5', r'GetTimeSafe(time, i) + PeriodSeconds() * 5', content)

    with open("smc_trade.pro", "w", encoding="utf-8") as f:
        f.write(content)

    print("Done")

if __name__ == "__main__":
    main()
