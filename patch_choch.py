import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Add mother bar logic and parameters
inputs_search = """//--- Visual Options ---"""
inputs_replace = """//--- CHoCH Settings ---
input double InpMinPullbackPct = 20.0;           // CHoCH Min Çekilme % (Onay Yüzdeliği)
input double InpMaxPullbackPct = 100.0;          // CHoCH Max Çekilme % (İşlem Yüzdeliği)
input color  InpColorChochBull = clrBlue;        // Yükseliş CHoCH Rengi
input color  InpColorChochBear = clrMagenta;     // Düşüş CHoCH Rengi
input bool   InpShowChoch      = true;           // CHoCH Çizgilerini Göster

//--- Visual Options ---"""
content = content.replace(inputs_search, inputs_replace)

state_search = """   string            cur_top_line;
   string            cur_bot_line;

   CStack            st_h;
   CStack            st_l;"""

state_replace = """   string            cur_top_line;
   string            cur_bot_line;

   // Mother Bar Tracking
   double            mb_h;
   double            mb_l;
   int               mb_i;

   // CHoCH Tracking
   double            t1_h;
   double            t1_l;
   double            d1_h;
   double            d1_l;
   double            t2_h;
   double            t2_l;
   int               choch_dir; // 1 = Bullish, -1 = Bearish, 0 = None

   CStack            st_h;
   CStack            st_l;"""

content = content.replace(state_search, state_replace)

copy_search = """      cur_top_line   = source.cur_top_line;
      cur_bot_line   = source.cur_bot_line;

      st_h.CopyFrom(source.st_h);"""

copy_replace = """      cur_top_line   = source.cur_top_line;
      cur_bot_line   = source.cur_bot_line;

      mb_h           = source.mb_h;
      mb_l           = source.mb_l;
      mb_i           = source.mb_i;

      t1_h           = source.t1_h;
      t1_l           = source.t1_l;
      d1_h           = source.d1_h;
      d1_l           = source.d1_l;
      t2_h           = source.t2_h;
      t2_l           = source.t2_l;
      choch_dir      = source.choch_dir;

      st_h.CopyFrom(source.st_h);"""

content = content.replace(copy_search, copy_replace)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Basic state updated")
