import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Add CHoCH logic to ProcessBar function
search_str = """   // MINOR STRUCTURE
   if(state.min_tr == 1)"""

replace_str = """   // CHoCH & T1-D1-T2 TRACKING LOGIC
   // Current major trend structure
   double cur_maj_h = state.maj_h;
   double cur_maj_l = state.maj_l;
   double p_pct = 0;

   if (cur_maj_h != EMPTY_VALUE && cur_maj_l != EMPTY_VALUE && cur_maj_h != cur_maj_l) {
      double range = cur_maj_h - cur_maj_l;
      if (state.maj_tr == 1) { // Up Trend
         if (val_l >= cur_maj_l) {
             p_pct = ((cur_maj_h - val_l) / range) * 100.0;
         }
      } else if (state.maj_tr == -1) { // Down Trend
         if (val_h <= cur_maj_h) {
             p_pct = ((val_h - cur_maj_l) / range) * 100.0;
         }
      }
   }

   bool in_pullback_zone = (p_pct >= InpMinPullbackPct && p_pct <= InpMaxPullbackPct);

   // T1-D1-T2 State Machine based on Minor structure turns
   // (Calculated implicitly during Minor Structure state changes below)

   // MINOR STRUCTURE
   if(state.min_tr == 1)"""

content = content.replace(search_str, replace_str)

# Now inject logic inside the minor structure pivots.
# Downside turn (making a high)
min_h_search = """         if(state.maj_tr == 1 && state.maj_st == 0 && state.min_h < state.tmp_h && state.st_l.Size() > 0)
           {
            if(state.st_l.GetIdx(state.st_l.Size() - 1) > state.bos_i)
              {
               state.st_l.Pop();
              }
           }
         state.min_tr = -1;
         state.lp_i = state.min_h_i;
         state.lp_p = state.min_h;"""

min_h_replace = """         if(state.maj_tr == 1 && state.maj_st == 0 && state.min_h < state.tmp_h && state.st_l.Size() > 0)
           {
            if(state.st_l.GetIdx(state.st_l.Size() - 1) > state.bos_i)
              {
               state.st_l.Pop();
              }
           }

         // CHoCH Bearish sequence tracking
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
         }

         state.min_tr = -1;
         state.lp_i = state.min_h_i;
         state.lp_p = state.min_h;"""

content = content.replace(min_h_search, min_h_replace)

# Upside turn (making a low)
min_l_search = """         if(state.maj_tr == -1 && state.maj_st == 0 && state.min_l > state.tmp_l && state.st_h.Size() > 0)
           {
            if(state.st_h.GetIdx(state.st_h.Size() - 1) > state.bos_i)
              {
               state.st_h.Pop();
              }
           }
         state.min_tr = 1;
         state.lp_i = state.min_l_i;
         state.lp_p = state.min_l;"""

min_l_replace = """         if(state.maj_tr == -1 && state.maj_st == 0 && state.min_l > state.tmp_l && state.st_h.Size() > 0)
           {
            if(state.st_h.GetIdx(state.st_h.Size() - 1) > state.bos_i)
              {
               state.st_h.Pop();
              }
           }

         // CHoCH Bullish sequence tracking
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
         }

         state.min_tr = 1;
         state.lp_i = state.min_l_i;
         state.lp_p = state.min_l;"""

content = content.replace(min_l_search, min_l_replace)


# CHoCH Breakout condition check at the end of minor structure block
min_struct_end_search = """   // MAJOR STRUCTURE
   if(state.maj_tr == 0)"""

min_struct_end_replace = """   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h > state.t1_h && state.d1_l != 0) {
      if (val_c < state.d1_l) {
          // Bearish CHoCH confirmed!
          if (InpShowChoch && !is_history) {
              string choch_name = GetUniqueName(prefix + "CHoCH_Bear_");
              DrawLine(choch_name, time[state.lp_i], state.d1_l, time[i] + PeriodSeconds(), state.d1_l, InpColorChochBear, 2, STYLE_SOLID, true);
          }
          state.choch_dir = 0; // Reset after trigger
      }
   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.t2_l < state.t1_l && state.d1_h != 0) {
      if (val_c > state.d1_h) {
          // Bullish CHoCH confirmed!
          if (InpShowChoch && !is_history) {
              string choch_name = GetUniqueName(prefix + "CHoCH_Bull_");
              DrawLine(choch_name, time[state.lp_i], state.d1_h, time[i] + PeriodSeconds(), state.d1_h, InpColorChochBull, 2, STYLE_SOLID, true);
          }
          state.choch_dir = 0; // Reset after trigger
      }
   }

   // MAJOR STRUCTURE
   if(state.maj_tr == 0)"""

content = content.replace(min_struct_end_search, min_struct_end_replace)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("T1-D1-T2 logic injected")
