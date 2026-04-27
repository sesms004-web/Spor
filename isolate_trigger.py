import re

with open('smcv1.mq5', 'r') as f:
    content = f.read()

# Replace Trigger for Bearish
trigger_bear_search = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {"""

trigger_bear_replace = """   // CHoCH Trigger & Drawing Logic
   bool bear_trigger_ready = InpExtraSecurity ? (state.choch_dir == -1 && state.t3_h != 0 && state.d2_l != 0) : (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0);
   if (bear_trigger_ready) {"""
content = content.replace(trigger_bear_search, trigger_bear_replace)


bear_block_search = """      bool should_eval_bear = (!InpWaitRetest) ? (val_c < state.d1_l) : (is_history && val_c < state.d1_l);

      if (should_eval_bear && t2_valid) {
          // Bearish CHoCH confirmed!
          state.last_choch_dir = -1;
          state.last_choch_level = state.d1_l;
          state.last_choch_time = time[i];

          bool is_strong = (state.t2_h > state.t1_h); // T2 sweeps T1's high"""

bear_block_replace = """      double trigger_level = InpExtraSecurity ? state.d2_l : state.d1_l;
      bool should_eval_bear = (!InpWaitRetest) ? (val_c < trigger_level) : (is_history && val_c < trigger_level);

      if (should_eval_bear && t2_valid) {
          // Bearish CHoCH confirmed!
          state.last_choch_dir = -1;
          state.last_choch_level = trigger_level;
          state.last_choch_time = time[i];

          bool is_strong = InpExtraSecurity ? (state.t3_h > state.t2_h) : (state.t2_h > state.t1_h);"""
content = content.replace(bear_block_search, bear_block_replace)


bear_alert_search = """                  if (!InpWaitRetest) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, p_pct, is_strong, state.t2_h, state.maj_h_i);
                  } else {
                      // Retest Modu: İşlemi Pusuya Yatır
                      g_pending_active = true;
                      g_pending_dir = -1;
                      g_pending_bar_i = i;
                      g_pending_sl = state.t2_h;
                      g_pending_is_strong = is_strong;
                      g_pending_p_pct = p_pct;
                      g_pending_maj_extreme_i = state.maj_h_i;

                      // Entry = CHoCH Line + (SL - CHoCH Line) * Depth%
                      double dist = state.t2_h - state.d1_l;
                      g_pending_entry = state.d1_l + (dist * (InpRetestDepthPct / 100.0));
                  }

                  last_alert_d1_i_bear = state.d1_i;
                  last_alert_maj_i_bear = state.maj_h_i;
              }
          }

          if (InpShowChoch) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              // 1. Draw the minor structure path (T1 -> D1 -> T2 -> Signal Point)
              string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_h, GetTimeSafe(time, state.d1_i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

              string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_l, GetTimeSafe(time, state.t2_i), state.t2_h, InpColorChochPath, 1, STYLE_DOT, false);

              string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_h, GetTimeSafe(time, i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, GetTimeSafe(time, i), state.d1_l, GetTimeSafe(time, i) + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);
          }"""

bear_alert_replace = """                  double sl_level = InpExtraSecurity ? state.t3_h : state.t2_h;
                  if (!InpWaitRetest) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, p_pct, is_strong, sl_level, state.maj_h_i);
                  } else {
                      // Retest Modu: İşlemi Pusuya Yatır
                      g_pending_active = true;
                      g_pending_dir = -1;
                      g_pending_bar_i = i;
                      g_pending_sl = sl_level;
                      g_pending_is_strong = is_strong;
                      g_pending_p_pct = p_pct;
                      g_pending_maj_extreme_i = state.maj_h_i;

                      // Entry = CHoCH Line + (SL - CHoCH Line) * Depth%
                      double dist = sl_level - trigger_level;
                      g_pending_entry = trigger_level + (dist * (InpRetestDepthPct / 100.0));
                  }

                  last_alert_d1_i_bear = InpExtraSecurity ? state.d2_i : state.d1_i;
                  last_alert_maj_i_bear = state.maj_h_i;
              }
          }

          if (InpShowChoch) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              if (InpExtraSecurity) {
                  string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_h, GetTimeSafe(time, state.d1_i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_l, GetTimeSafe(time, state.t2_i), state.t2_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_h, GetTimeSafe(time, state.d2_i), state.d2_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_4 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_4, GetTimeSafe(time, state.d2_i), state.d2_l, GetTimeSafe(time, state.t3_i), state.t3_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_5 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_5, GetTimeSafe(time, state.t3_i), state.t3_h, GetTimeSafe(time, i), state.d2_l, InpColorChochPath, 1, STYLE_DOT, false);

                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t1_i), state.t1_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T1");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.d1_i), state.d1_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "D1");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t2_i), state.t2_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T2");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.d2_i), state.d2_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "D2");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t3_i), state.t3_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T3");

              } else {
                  string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_h, GetTimeSafe(time, state.d1_i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_l, GetTimeSafe(time, state.t2_i), state.t2_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_h, GetTimeSafe(time, i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);
              }

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, GetTimeSafe(time, i), trigger_level, GetTimeSafe(time, i) + PeriodSeconds() * 5, trigger_level, sig_color, 3, STYLE_SOLID, false);
          }"""
content = content.replace(bear_alert_search, bear_alert_replace)


# Replace Trigger for Bullish
trigger_bull_search = """   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {"""

trigger_bull_replace = """   } else {
       bool bull_trigger_ready = InpExtraSecurity ? (state.choch_dir == 1 && state.t3_l != 0 && state.d2_h != 0) : (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0);
       if (bull_trigger_ready) {"""
content = content.replace(trigger_bull_search, trigger_bull_replace)

bull_block_search = """      bool should_eval_bull = (!InpWaitRetest) ? (val_c > state.d1_h) : (is_history && val_c > state.d1_h);

      if (should_eval_bull && t2_valid) {
          // Bullish CHoCH confirmed!
          state.last_choch_dir = 1;
          state.last_choch_level = state.d1_h;
          state.last_choch_time = time[i];

          bool is_strong = (state.t2_l < state.t1_l); // T2 sweeps T1's low"""

bull_block_replace = """      double trigger_level = InpExtraSecurity ? state.d2_h : state.d1_h;
      bool should_eval_bull = (!InpWaitRetest) ? (val_c > trigger_level) : (is_history && val_c > trigger_level);

      if (should_eval_bull && t2_valid) {
          // Bullish CHoCH confirmed!
          state.last_choch_dir = 1;
          state.last_choch_level = trigger_level;
          state.last_choch_time = time[i];

          bool is_strong = InpExtraSecurity ? (state.t3_l < state.t2_l) : (state.t2_l < state.t1_l);"""
content = content.replace(bull_block_search, bull_block_replace)

bull_alert_search = """                  if (!InpWaitRetest) {
                      EvaluateTradeSignal(i, time[i], val_c, 1, p_pct, is_strong, state.t2_l, state.maj_l_i);
                  } else {
                      // Retest Modu: İşlemi Pusuya Yatır
                      g_pending_active = true;
                      g_pending_dir = 1;
                      g_pending_bar_i = i;
                      g_pending_sl = state.t2_l;
                      g_pending_is_strong = is_strong;
                      g_pending_p_pct = p_pct;
                      g_pending_maj_extreme_i = state.maj_l_i;

                      // Entry = CHoCH Line - (CHoCH Line - SL) * Depth%
                      double dist = state.d1_h - state.t2_l;
                      g_pending_entry = state.d1_h - (dist * (InpRetestDepthPct / 100.0));
                  }

                  last_alert_d1_i_bull = state.d1_i;
                  last_alert_maj_i_bull = state.maj_l_i;
              }
          }

          if (InpShowChoch) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              // 1. Draw the minor structure path (T1 -> D1 -> T2 -> Signal Point)
              string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_l, GetTimeSafe(time, state.d1_i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

              string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_h, GetTimeSafe(time, state.t2_i), state.t2_l, InpColorChochPath, 1, STYLE_DOT, false);

              string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_l, GetTimeSafe(time, i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, GetTimeSafe(time, i), state.d1_h, GetTimeSafe(time, i) + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);
          }"""

bull_alert_replace = """                  double sl_level = InpExtraSecurity ? state.t3_l : state.t2_l;
                  if (!InpWaitRetest) {
                      EvaluateTradeSignal(i, time[i], val_c, 1, p_pct, is_strong, sl_level, state.maj_l_i);
                  } else {
                      // Retest Modu: İşlemi Pusuya Yatır
                      g_pending_active = true;
                      g_pending_dir = 1;
                      g_pending_bar_i = i;
                      g_pending_sl = sl_level;
                      g_pending_is_strong = is_strong;
                      g_pending_p_pct = p_pct;
                      g_pending_maj_extreme_i = state.maj_l_i;

                      // Entry = CHoCH Line - (CHoCH Line - SL) * Depth%
                      double dist = trigger_level - sl_level;
                      g_pending_entry = trigger_level - (dist * (InpRetestDepthPct / 100.0));
                  }

                  last_alert_d1_i_bull = InpExtraSecurity ? state.d2_i : state.d1_i;
                  last_alert_maj_i_bull = state.maj_l_i;
              }
          }

          if (InpShowChoch) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              if (InpExtraSecurity) {
                  string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_l, GetTimeSafe(time, state.d1_i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_h, GetTimeSafe(time, state.t2_i), state.t2_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_l, GetTimeSafe(time, state.d2_i), state.d2_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_4 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_4, GetTimeSafe(time, state.d2_i), state.d2_h, GetTimeSafe(time, state.t3_i), state.t3_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_5 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_5, GetTimeSafe(time, state.t3_i), state.t3_l, GetTimeSafe(time, i), state.d2_h, InpColorChochPath, 1, STYLE_DOT, false);

                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t1_i), state.t1_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T1");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.d1_i), state.d1_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "D1");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t2_i), state.t2_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T2");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.d2_i), state.d2_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "D2");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t3_i), state.t3_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T3");

              } else {
                  string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_l, GetTimeSafe(time, state.d1_i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_h, GetTimeSafe(time, state.t2_i), state.t2_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_l, GetTimeSafe(time, i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);
              }

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, GetTimeSafe(time, i), trigger_level, GetTimeSafe(time, i) + PeriodSeconds() * 5, trigger_level, sig_color, 3, STYLE_SOLID, false);
          }"""

content = content.replace(bull_alert_search, bull_alert_replace)

# Add closing brace for the `} else {` added for Bullish
brace_search = """          state.choch_dir = 0; // Reset after trigger
      }
   }

   // MAJOR STRUCTURE
   if(state.maj_tr == 0)"""

brace_replace = """          state.choch_dir = 0; // Reset after trigger
      }
   }
   }

   // MAJOR STRUCTURE
   if(state.maj_tr == 0)"""
content = content.replace(brace_search, brace_replace)

with open('smcv1.mq5', 'w') as f:
    f.write(content)
