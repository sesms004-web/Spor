import re

with open('smcv1.mq5', 'r') as f:
    content = f.read()

# Bearish logic: when we update D1, we MUST NOT update T2 in the same bar for InpExtraSecurity.
# Wait for the next swing! We need isolated updates.
bear_search = """                 if (InpExtraSecurity) {
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
                 } else {"""

bear_replace = """                 if (InpExtraSecurity) {
                     if (state.d1_l != 0 && state.t2_h == 0) {
                         if (state.min_h_i > state.d1_i) {
                             state.t2_h = state.min_h;
                             state.t2_i = state.min_h_i;
                         }
                     } else if (state.t2_h != 0 && state.d2_l == 0) {
                         if (state.min_l_i > state.t2_i) {
                             state.d2_l = state.min_l;
                             state.d2_i = state.min_l_i;
                         }
                     } else if (state.d2_l != 0 && state.t3_h == 0) {
                         if (state.min_h_i > state.d2_i) {
                             state.t3_h = state.min_h;
                             state.t3_i = state.min_h_i;
                         }
                     }
                 } else {"""
content = content.replace(bear_search, bear_replace)

bull_search = """                 if (InpExtraSecurity) {
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
                 } else {"""

bull_replace = """                 if (InpExtraSecurity) {
                     if (state.d1_h != 0 && state.t2_l == 0) {
                         if (state.min_l_i > state.d1_i) {
                             state.t2_l = state.min_l;
                             state.t2_i = state.min_l_i;
                         }
                     } else if (state.t2_l != 0 && state.d2_h == 0) {
                         if (state.min_h_i > state.t2_i) {
                             state.d2_h = state.min_h;
                             state.d2_i = state.min_h_i;
                         }
                     } else if (state.d2_h != 0 && state.t3_l == 0) {
                         if (state.min_l_i > state.d2_i) {
                             state.t3_l = state.min_l;
                             state.t3_i = state.min_l_i;
                         }
                     }
                 } else {"""
content = content.replace(bull_search, bull_replace)

with open('smcv1.mq5', 'w') as f:
    f.write(content)
