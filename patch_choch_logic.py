import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Bearish tracking logic (making a high)
min_h_search = """         // CHoCH Bearish sequence tracking
         if (state.maj_tr == 1 && in_pullback_zone) {
             if (state.choch_dir == 0 || state.choch_dir == 1) { // Initiate T1 for Bearish
                 state.t1_h = state.min_h;
                 state.t1_l = state.min_l;
                 state.d1_h = 0; state.d1_l = 0;
                 state.t2_h = 0; state.t2_l = 0;
                 state.choch_dir = -1; // Tracking potential downside break
             } else if (state.choch_dir == -1) {
                 if (state.d1_l == 0) { // First turn down after T1 (This is D1 forming)
                     state.d1_l = state.min_l;
                 }
                 if (state.d1_l != 0 && state.min_h > state.t1_h) {
                     // T2 guarantees sweep of T1's extreme
                     state.t2_h = state.min_h;
                 }
             }
         }"""

min_h_replace = """         // CHoCH Bearish sequence tracking
         if (state.maj_tr == 1 && in_pullback_zone) {
             if (state.choch_dir == 0 || state.choch_dir == 1) { // Initiate T1 for Bearish
                 state.t1_h = state.min_h;
                 state.t1_l = state.min_l;
                 state.t1_i = state.min_h_i;
                 state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
                 state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
                 state.choch_dir = -1; // Tracking potential downside break
             } else if (state.choch_dir == -1) {
                 if (state.d1_l == 0) { // First turn down after T1 (This is D1 forming)
                     state.d1_l = state.min_l;
                     state.d1_i = state.min_l_i;
                 }
                 if (state.d1_l != 0 && state.t2_h == 0) {
                     // T2 marks the turn back up towards T1 (regardless of whether it sweeps it or not).
                     state.t2_h = state.min_h;
                     state.t2_i = state.min_h_i;
                 }
             }
         }"""

content = content.replace(min_h_search, min_h_replace)

# Bullish tracking logic (making a low)
min_l_search = """         // CHoCH Bullish sequence tracking
         if (state.maj_tr == -1 && in_pullback_zone) {
             if (state.choch_dir == 0 || state.choch_dir == -1) { // Initiate T1 for Bullish
                 state.t1_l = state.min_l;
                 state.t1_h = state.min_h;
                 state.d1_l = 0; state.d1_h = 0;
                 state.t2_l = 0; state.t2_h = 0;
                 state.choch_dir = 1; // Tracking potential upside break
             } else if (state.choch_dir == 1) {
                 if (state.d1_h == 0) { // First turn up after T1 (This is D1 forming)
                     state.d1_h = state.min_h;
                 }
                 if (state.d1_h != 0 && state.min_l < state.t1_l) {
                     // T2 guarantees sweep of T1's extreme
                     state.t2_l = state.min_l;
                 }
             }
         }"""

min_l_replace = """         // CHoCH Bullish sequence tracking
         if (state.maj_tr == -1 && in_pullback_zone) {
             if (state.choch_dir == 0 || state.choch_dir == -1) { // Initiate T1 for Bullish
                 state.t1_l = state.min_l;
                 state.t1_h = state.min_h;
                 state.t1_i = state.min_l_i;
                 state.d1_l = 0; state.d1_h = 0; state.d1_i = 0;
                 state.t2_l = 0; state.t2_h = 0; state.t2_i = 0;
                 state.choch_dir = 1; // Tracking potential upside break
             } else if (state.choch_dir == 1) {
                 if (state.d1_h == 0) { // First turn up after T1 (This is D1 forming)
                     state.d1_h = state.min_h;
                     state.d1_i = state.min_h_i;
                 }
                 if (state.d1_h != 0 && state.t2_l == 0) {
                     // T2 marks the turn back down towards T1 (regardless of whether it sweeps it or not).
                     state.t2_l = state.min_l;
                     state.t2_i = state.min_l_i;
                 }
             }
         }"""

content = content.replace(min_l_search, min_l_replace)

# Final CHoCH Trigger & Drawing Logic
trigger_search = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h > state.t1_h && state.d1_l != 0) {
      if (val_c < state.d1_l) {
          // Bearish CHoCH confirmed!
          if (InpShowChoch) {
              string choch_name = GetUniqueName(prefix + "CHoCH_Bear_");
              DrawLine(choch_name, time[state.lp_i], state.d1_l, time[i] + PeriodSeconds() * 5, state.d1_l, InpColorChochBear, 2, STYLE_SOLID, false);
          }
          state.choch_dir = 0; // Reset after trigger
      }
   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.t2_l < state.t1_l && state.d1_h != 0) {
      if (val_c > state.d1_h) {
          // Bullish CHoCH confirmed!
          if (InpShowChoch) {
              string choch_name = GetUniqueName(prefix + "CHoCH_Bull_");
              DrawLine(choch_name, time[state.lp_i], state.d1_h, time[i] + PeriodSeconds() * 5, state.d1_h, InpColorChochBull, 2, STYLE_SOLID, false);
          }
          state.choch_dir = 0; // Reset after trigger
      }
   }"""

trigger_replace = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {
      if (val_c < state.d1_l) {
          // Bearish CHoCH confirmed!
          if (InpShowChoch) {
              bool is_strong = (state.t2_h > state.t1_h); // T2 sweeps T1's high
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              // 1. Draw the minor structure path (T1 -> D1 -> T2 -> Signal Point)
              string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_1, time[state.t1_i], state.t1_h, time[state.d1_i], state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

              string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_2, time[state.d1_i], state.d1_l, time[state.t2_i], state.t2_h, InpColorChochPath, 1, STYLE_DOT, false);

              string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_3, time[state.t2_i], state.t2_h, time[i], state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_l, time[i] + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);
          }
          state.choch_dir = 0; // Reset after trigger
      }
   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h) {
          // Bullish CHoCH confirmed!
          if (InpShowChoch) {
              bool is_strong = (state.t2_l < state.t1_l); // T2 sweeps T1's low
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              // 1. Draw the minor structure path (T1 -> D1 -> T2 -> Signal Point)
              string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_1, time[state.t1_i], state.t1_l, time[state.d1_i], state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

              string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_2, time[state.d1_i], state.d1_h, time[state.t2_i], state.t2_l, InpColorChochPath, 1, STYLE_DOT, false);

              string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_3, time[state.t2_i], state.t2_l, time[i], state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_h, time[i] + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);
          }
          state.choch_dir = 0; // Reset after trigger
      }
   }"""

content = content.replace(trigger_search, trigger_replace)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Logic patched")
