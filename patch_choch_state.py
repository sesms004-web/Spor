import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# 1. Update CHoCH Settings to include Strong/Weak colors
inputs_search = """input color  InpColorChochBull = clrBlue;        // Yükseliş CHoCH Rengi
input color  InpColorChochBear = clrMagenta;     // Düşüş CHoCH Rengi"""
inputs_replace = """input color  InpColorChochStrong = clrPurple;      // Güçlü CHoCH (Mor)
input color  InpColorChochWeak   = clrRed;         // Güçsuz CHoCH (Kırmızı)
input color  InpColorChochPath   = clrGray;        // Yapı İzi (Gri)"""
content = content.replace(inputs_search, inputs_replace)

# 2. Update state to track Time indices of T1, D1, T2 to draw lines
state_search = """   // CHoCH Tracking
   double            t1_h;
   double            t1_l;
   double            d1_h;
   double            d1_l;
   double            t2_h;
   double            t2_l;
   int               choch_dir; // 1 = Bullish, -1 = Bearish, 0 = None"""
state_replace = """   // CHoCH Tracking
   double            t1_h;
   double            t1_l;
   int               t1_i;
   double            d1_h;
   double            d1_l;
   int               d1_i;
   double            t2_h;
   double            t2_l;
   int               t2_i;
   int               choch_dir; // 1 = Bullish, -1 = Bearish, 0 = None"""
content = content.replace(state_search, state_replace)

copy_search = """      t1_h           = source.t1_h;
      t1_l           = source.t1_l;
      d1_h           = source.d1_h;
      d1_l           = source.d1_l;
      t2_h           = source.t2_h;
      t2_l           = source.t2_l;
      choch_dir      = source.choch_dir;"""
copy_replace = """      t1_h           = source.t1_h;
      t1_l           = source.t1_l;
      t1_i           = source.t1_i;
      d1_h           = source.d1_h;
      d1_l           = source.d1_l;
      d1_i           = source.d1_i;
      t2_h           = source.t2_h;
      t2_l           = source.t2_l;
      t2_i           = source.t2_i;
      choch_dir      = source.choch_dir;"""
content = content.replace(copy_search, copy_replace)

# 3. Add cleanup for new objects in OnDeinit
deinit_search = """   ObjectsDeleteAll(0, "CHoCH_Bear_");
   ObjectsDeleteAll(0, "CHoCH_Bull_");"""
deinit_replace = """   ObjectsDeleteAll(0, "CHoCH_Bear_");
   ObjectsDeleteAll(0, "CHoCH_Bull_");
   ObjectsDeleteAll(0, "CHoCH_Path_");
   ObjectsDeleteAll(0, "CHoCH_Signal_");"""
content = content.replace(deinit_search, deinit_replace)

# 4. Also update cleanup in OnCalculate
oncalc_search = """      ObjectsDeleteAll(0, "CHoCH_Bear_");
      ObjectsDeleteAll(0, "CHoCH_Bull_");"""
oncalc_replace = """      ObjectsDeleteAll(0, "CHoCH_Bear_");
      ObjectsDeleteAll(0, "CHoCH_Bull_");
      ObjectsDeleteAll(0, "CHoCH_Path_");
      ObjectsDeleteAll(0, "CHoCH_Signal_");"""
content = content.replace(oncalc_search, oncalc_replace)

init_search = """      g_state_hist.t1_h = 0; g_state_hist.t1_l = 0;
      g_state_hist.d1_h = 0; g_state_hist.d1_l = 0;
      g_state_hist.t2_h = 0; g_state_hist.t2_l = 0;
      g_state_hist.choch_dir = 0;"""
init_replace = """      g_state_hist.t1_h = 0; g_state_hist.t1_l = 0; g_state_hist.t1_i = 0;
      g_state_hist.d1_h = 0; g_state_hist.d1_l = 0; g_state_hist.d1_i = 0;
      g_state_hist.t2_h = 0; g_state_hist.t2_l = 0; g_state_hist.t2_i = 0;
      g_state_hist.choch_dir = 0;"""
content = content.replace(init_search, init_replace)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("State and cleanup logic updated")
