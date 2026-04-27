import re

with open('smcv1.mq5', 'r') as f:
    content = f.read()

# Make isolated tracking logic replacement. We will do this by taking the original blocks and wrapping them with if (InpExtraSecurity) {...} else { original }

# 1. Invalidation (Making a High)
inv_high_search = """         // CHoCH Invalidation (Making a High)
         if (state.choch_dir == -1 && state.t2_h != 0) {
             // T1, D1, T2 formed. Making ANOTHER High means Leg 3 failed to break D1. Reset.
             state.choch_dir = 0;
         }
         if (state.choch_dir == 1 && state.t2_l != 0 && state.min_h <= state.d1_h) {
             // Bullish: T1, D1, T2 formed. Making a High that is <= D1 means failure to break. Reset.
             state.choch_dir = 0;
         }"""

inv_high_replace = """         // CHoCH Invalidation (Making a High)
         if (InpExtraSecurity) {
             if (state.choch_dir == -1 && state.t3_h != 0) {
                 state.choch_dir = 0;
             }
             if (state.choch_dir == 1 && state.t3_l != 0 && state.min_h <= state.d2_h) {
                 state.choch_dir = 0;
             }
         } else {
             if (state.choch_dir == -1 && state.t2_h != 0) {
                 // T1, D1, T2 formed. Making ANOTHER High means Leg 3 failed to break D1. Reset.
                 state.choch_dir = 0;
             }
             if (state.choch_dir == 1 && state.t2_l != 0 && state.min_h <= state.d1_h) {
                 // Bullish: T1, D1, T2 formed. Making a High that is <= D1 means failure to break. Reset.
                 state.choch_dir = 0;
             }
         }"""
content = content.replace(inv_high_search, inv_high_replace)


# 2. Invalidation (Making a Low)
inv_low_search = """         // CHoCH Invalidation (Making a Low)
         if (state.choch_dir == 1 && state.t2_l != 0) {
             // T1, D1, T2 formed. Making ANOTHER Low means Leg 3 failed to break D1. Reset.
             state.choch_dir = 0;
         }
         if (state.choch_dir == -1 && state.t2_h != 0 && state.min_l >= state.d1_l) {
             // Bearish: T1, D1, T2 formed. Making a Low that is >= D1 means failure to break. Reset.
             state.choch_dir = 0;
         }"""

inv_low_replace = """         // CHoCH Invalidation (Making a Low)
         if (InpExtraSecurity) {
             if (state.choch_dir == 1 && state.t3_l != 0) {
                 state.choch_dir = 0;
             }
             if (state.choch_dir == -1 && state.t3_h != 0 && state.min_l >= state.d2_l) {
                 state.choch_dir = 0;
             }
         } else {
             if (state.choch_dir == 1 && state.t2_l != 0) {
                 // T1, D1, T2 formed. Making ANOTHER Low means Leg 3 failed to break D1. Reset.
                 state.choch_dir = 0;
             }
             if (state.choch_dir == -1 && state.t2_h != 0 && state.min_l >= state.d1_l) {
                 // Bearish: T1, D1, T2 formed. Making a Low that is >= D1 means failure to break. Reset.
                 state.choch_dir = 0;
             }
         }"""
content = content.replace(inv_low_search, inv_low_replace)


# 3. Bearish Tracking Sequence
bear_search = """                 if (state.d1_l != 0 && state.t2_h == 0) {
                     // T2 marks the turn back up towards T1 (regardless of whether it sweeps it or not).
                     state.t2_h = state.min_h;
                     state.t2_i = state.min_h_i;
                 }"""

bear_replace = """                 if (InpExtraSecurity) {
                     if (state.d1_l != 0 && state.t2_h == 0) {
                         state.t2_h = state.min_h;
                         state.t2_i = state.min_h_i;
                     } else if (state.t2_h != 0 && state.d2_l == 0) {
                         state.d2_l = state.min_l;
                         state.d2_i = state.min_l_i;
                     } else if (state.d2_l != 0 && state.t3_h == 0) {
                         state.t3_h = state.min_h;
                         state.t3_i = state.min_h_i;
                     }
                 } else {
                     if (state.d1_l != 0 && state.t2_h == 0) {
                         // T2 marks the turn back up towards T1 (regardless of whether it sweeps it or not).
                         state.t2_h = state.min_h;
                         state.t2_i = state.min_h_i;
                     }
                 }"""
content = content.replace(bear_search, bear_replace)


# 4. Bullish Tracking Sequence
bull_search = """                 if (state.d1_h != 0 && state.t2_l == 0) {
                     // T2 marks the turn back down towards T1 (regardless of whether it sweeps it or not).
                     state.t2_l = state.min_l;
                     state.t2_i = state.min_l_i;
                 }"""

bull_replace = """                 if (InpExtraSecurity) {
                     if (state.d1_h != 0 && state.t2_l == 0) {
                         state.t2_l = state.min_l;
                         state.t2_i = state.min_l_i;
                     } else if (state.t2_l != 0 && state.d2_h == 0) {
                         state.d2_h = state.min_h;
                         state.d2_i = state.min_h_i;
                     } else if (state.d2_h != 0 && state.t3_l == 0) {
                         state.t3_l = state.min_l;
                         state.t3_i = state.min_l_i;
                     }
                 } else {
                     if (state.d1_h != 0 && state.t2_l == 0) {
                         // T2 marks the turn back down towards T1 (regardless of whether it sweeps it or not).
                         state.t2_l = state.min_l;
                         state.t2_i = state.min_l_i;
                     }
                 }"""
content = content.replace(bull_search, bull_replace)


with open('smcv1.mq5', 'w') as f:
    f.write(content)
