//+------------------------------------------------------------------+
//|                                        yenistratejigeliyor.mq5   |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

// --- Inputs ---
input double InpDaysM1 = 1.0; // Lookback Days (Main)

// --- CHoCH ---
input double InpMinPullbackPct = 40.0;
input double InpMaxPullbackPct = 100.0;
input color  InpColorChochStrong = clrPurple;
input color  InpColorChochWeak = clrRed;
input color  InpColorChochPath = clrGray;
input bool   InpShowChoch = true;

// --- STRUCTURE ---
input bool   InpShowMin = true;
input bool   InpShowMaj = true;
input color  InpColorMin = clrRed;
input color  InpColorBear = clrRed;
input color  InpColorBull = clrGreen;

// --- BASE-DROP BOX ---
input double InpBigCandleMult = 1.6;
input int    InpBaseMaxCandles = 5;
input int    InpBaseAvgLookback = 10;
input bool   InpShowBox = true;
input bool   InpBoxTrendFilter = true;
input double InpMinBreakoutPct = 50.0;
input int    InpMinBaseHeightTicks = 10;
input double InpMaxBoxPct = 20.0;
input double InpWeakZonePct = 50.0;
input color  InpColorBoxBull = clrBlue;
input color  InpColorBoxBear = clrRed;
input color  InpColorWeakBull = C'0,25,55';
input color  InpColorWeakBear = C'55,15,0';




void DrawLine(string name, datetime time1, double price1, datetime time2, double price2, color clr, int width, ENUM_LINE_STYLE style, bool ray_right=false)
  {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price2);
     }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, ray_right);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

void DrawRect(string name, datetime time1, double price1, datetime time2, double price2, color clr)
  {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price2);
     }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

struct SBox
  {
   datetime          start_t;
   datetime          end_t;
   double            top;
   double            bot;
   string            name_main;
   string            name_abv;
   string            name_blw;
   bool              is_bull;
  };

struct CBoxList
  {

   SBox              m_boxes[];

                     void Init() { ArrayResize(m_boxes, 0); }
   int               Size() { return ArraySize(m_boxes); }
   void              Add(SBox &box)
     {
      int size = ArraySize(m_boxes);
      ArrayResize(m_boxes, size + 1);
      m_boxes[size] = box;
     }
   SBox              Get(int i) { return m_boxes[i]; }
   void              SetEndT(int i, datetime t) { m_boxes[i].end_t = t; }
   void              Remove(int i)
     {
      int size = ArraySize(m_boxes);
      if(i < 0 || i >= size) return;
      for(int j = i; j < size - 1; j++) m_boxes[j] = m_boxes[j+1];
      ArrayResize(m_boxes, size - 1);
     }
   void              Clear() { ArrayResize(m_boxes, 0); }
  };

struct CStackDouble
  {

   double            m_vals[];

                     void Init() { ArrayResize(m_vals, 0); }
   void              Push(double v)
     {
      int size = ArraySize(m_vals);
      ArrayResize(m_vals, size + 1);
      m_vals[size] = v;
     }
   double            Pop()
     {
      int size = ArraySize(m_vals);
      if(size == 0) return 0;
      double v = m_vals[size - 1];
      ArrayResize(m_vals, size - 1);
      return v;
     }
   double            Get(int idx) { return m_vals[idx]; }
   int               Size() { return ArraySize(m_vals); }
   void              Clear() { ArrayResize(m_vals, 0); }
  };

struct CStackInt
  {

   int               m_vals[];

                     void Init() { ArrayResize(m_vals, 0); }
   void              Push(int v)
     {
      int size = ArraySize(m_vals);
      ArrayResize(m_vals, size + 1);
      m_vals[size] = v;
     }
   int               Pop()
     {
      int size = ArraySize(m_vals);
      if(size == 0) return 0;
      int v = m_vals[size - 1];
      ArrayResize(m_vals, size - 1);
      return v;
     }
   int               Get(int idx) { return m_vals[idx]; }
   int               Size() { return ArraySize(m_vals); }
   void              Clear() { ArrayResize(m_vals, 0); }
  };

struct SState
  {
   int               min_tr;
   int               maj_tr;
   int               maj_st;
   double            min_h;
   int               min_h_i;
   double            min_l;
   int               min_l_i;
   double            trig_h;
   double            trig_l;
   int               lp_i;
   double            lp_p;
   double            maj_h;
   int               maj_h_i;
   double            maj_l;
   int               maj_l_i;
   double            tmp_h;
   int               tmp_h_i;
   double            tmp_l;
   int               tmp_l_i;
   int               anc_i;
   double            anc_v;
   int               bos_i;
   int               bos_count;
   double            mb_h;
   double            mb_l;
   int               mb_i;
   double            t1_h;
   double            t1_l;
   int               t1_i;
   double            d1_h;
   double            d1_l;
   int               d1_i;
   double            t2_h;
   double            t2_l;
   int               t2_i;
   int               choch_dir;
   bool              swept_choch;
   int               bx_phase;
   bool              bx_extreme;
   double            bx_swing_h;
   double            bx_swing_l;

   bool              has_pot_bull_minor;
   int               pot_bull_start_i;
   double            pot_bull_start_p;
   double            pot_bull_end_p;
   bool              has_pot_bear_minor;
   int               pot_bear_start_i;
   double            pot_bear_start_p;
   double            pot_bear_end_p;

   CStackDouble      st_h_val;
   CStackInt         st_h_idx;
   CStackDouble      st_l_val;
   CStackInt         st_l_idx;

   CBoxList          active_boxes;


   void              Init()
     {
      min_tr = 0; maj_tr = 0; maj_st = 0;
      min_h = 0; min_h_i = 0; min_l = 0; min_l_i = 0;
      trig_h = 0; trig_l = 0; lp_i = 0; lp_p = 0;
      maj_h = 0; maj_h_i = 0; maj_l = 0; maj_l_i = 0;
      tmp_h = 0; tmp_h_i = 0; tmp_l = 0; tmp_l_i = 0;
      anc_i = 0; anc_v = 0; bos_i = 0; bos_count = 0;
      mb_h = 0; mb_l = 0; mb_i = 0;
      t1_h = 0; t1_l = 0; t1_i = 0;
      d1_h = 0; d1_l = 0; d1_i = 0;
      t2_h = 0; t2_l = 0; t2_i = 0;
      choch_dir = 0; swept_choch = false;
      bx_phase = 0; bx_extreme = false;
      bx_swing_h = 0; bx_swing_l = 0;
      has_pot_bull_minor = false; has_pot_bear_minor = false;
      active_boxes.Init();
      st_h_val.Init();
      st_h_idx.Init();
      st_l_val.Init();
      st_l_idx.Init();
     }

   void              CopyFrom(SState &s)
     {
      min_tr = s.min_tr; maj_tr = s.maj_tr; maj_st = s.maj_st;
      min_h = s.min_h; min_h_i = s.min_h_i; min_l = s.min_l; min_l_i = s.min_l_i;
      trig_h = s.trig_h; trig_l = s.trig_l; lp_i = s.lp_i; lp_p = s.lp_p;
      maj_h = s.maj_h; maj_h_i = s.maj_h_i; maj_l = s.maj_l; maj_l_i = s.maj_l_i;
      tmp_h = s.tmp_h; tmp_h_i = s.tmp_h_i; tmp_l = s.tmp_l; tmp_l_i = s.tmp_l_i;
      anc_i = s.anc_i; anc_v = s.anc_v; bos_i = s.bos_i; bos_count = s.bos_count;
      mb_h = s.mb_h; mb_l = s.mb_l; mb_i = s.mb_i;
      t1_h = s.t1_h; t1_l = s.t1_l; t1_i = s.t1_i;
      d1_h = s.d1_h; d1_l = s.d1_l; d1_i = s.d1_i;
      t2_h = s.t2_h; t2_l = s.t2_l; t2_i = s.t2_i;
      choch_dir = s.choch_dir; swept_choch = s.swept_choch;
      bx_phase = s.bx_phase; bx_extreme = s.bx_extreme;
      bx_swing_h = s.bx_swing_h; bx_swing_l = s.bx_swing_l;
      has_pot_bull_minor = s.has_pot_bull_minor;
      pot_bull_start_i = s.pot_bull_start_i;
      pot_bull_start_p = s.pot_bull_start_p;
      pot_bull_end_p = s.pot_bull_end_p;
      has_pot_bear_minor = s.has_pot_bear_minor;
      pot_bear_start_i = s.pot_bear_start_i;
      pot_bear_start_p = s.pot_bear_start_p;
      pot_bear_end_p = s.pot_bear_end_p;

      st_h_val.Clear(); st_h_idx.Clear(); st_l_val.Clear(); st_l_idx.Clear();
      for(int i=0; i<s.st_h_val.Size(); i++) { st_h_val.Push(s.st_h_val.Get(i)); st_h_idx.Push(s.st_h_idx.Get(i)); }

      for(int i=0; i<s.st_l_val.Size(); i++) { st_l_val.Push(s.st_l_val.Get(i)); st_l_idx.Push(s.st_l_idx.Get(i)); }
      active_boxes.Clear();
      for(int i=0; i<s.active_boxes.Size(); i++) { SBox b = s.active_boxes.Get(i); active_boxes.Add(b); }

     }
  };

SState g_state_hist;
SState g_state_curr;

void DrawMinorLine(datetime t1, double p1, datetime t2, double p2)
  {
   if(InpShowMin) DrawLine("Min_"+IntegerToString((int)t1)+"_"+IntegerToString((int)t2), t1, p1, t2, p2, InpColorMin, 1, STYLE_SOLID);
  }

void DrawMajorLine(datetime t1, double p1, datetime t2, double p2, color c)
  {
   if(InpShowMaj) DrawLine("Maj_"+IntegerToString((int)t1)+"_"+IntegerToString((int)t2), t1, p1, t2, p2, c, 2, STYLE_SOLID);
  }

void DrawChochLine(datetime t1, double p1, datetime t2, double p2, bool is_strong, datetime path_t1, double path_p1)
  {
   if(InpShowChoch)
     {
      DrawLine("Choch_"+IntegerToString((int)t1), t1, p1, t2, p2, is_strong ? InpColorChochStrong : InpColorChochWeak, 3, STYLE_SOLID);
      DrawLine("Path_"+IntegerToString((int)path_t1)+"_"+IntegerToString((int)t1), path_t1, path_p1, t1, p1, InpColorChochPath, 1, STYLE_DOT);
     }
  }

void ProcessBar(int i, const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], SState &state)
  {
   double val_h = high[i];
   double val_l = low[i];
   double val_c = close[i];

   bool is_inside = (high[i] <= state.mb_h && low[i] >= state.mb_l);

   if(!is_inside)
     {
      if(val_h > state.mb_h || val_l < state.mb_l)
        {
         state.mb_h = val_h;
         state.mb_l = val_l;
         state.mb_i = i;
        }

      // Base Drop Logic
      if(InpShowBox)
        {
         // 1. Trim active boxes
         for(int b = state.active_boxes.Size() - 1; b >= 0; b--)
           {
            SBox box = state.active_boxes.Get(b);
            if(val_h >= box.bot && val_l <= box.top)
              {
               box.end_t = time[i];
               DrawRect(box.name_main, box.start_t, box.top, box.end_t, box.bot, box.is_bull ? InpColorBoxBull : InpColorBoxBear);
               if(box.name_abv != "") DrawRect(box.name_abv, box.start_t, box.top + (box.top-box.bot)*(InpWeakZonePct/100.0), box.end_t, box.top, box.is_bull ? InpColorWeakBull : InpColorWeakBear);
               if(box.name_blw != "") DrawRect(box.name_blw, box.start_t, box.bot, box.end_t, box.bot - (box.top-box.bot)*(InpWeakZonePct/100.0), box.is_bull ? InpColorWeakBull : InpColorWeakBear);
               state.active_boxes.Remove(b);
              }
            else
              {
               box.end_t = time[i] + PeriodSeconds() * 5;
               DrawRect(box.name_main, box.start_t, box.top, box.end_t, box.bot, box.is_bull ? InpColorBoxBull : InpColorBoxBear);
               if(box.name_abv != "") DrawRect(box.name_abv, box.start_t, box.top + (box.top-box.bot)*(InpWeakZonePct/100.0), box.end_t, box.top, box.is_bull ? InpColorWeakBull : InpColorWeakBear);
               if(box.name_blw != "") DrawRect(box.name_blw, box.start_t, box.bot, box.end_t, box.bot - (box.top-box.bot)*(InpWeakZonePct/100.0), box.is_bull ? InpColorWeakBull : InpColorWeakBear);
               state.active_boxes.SetEndT(b, box.end_t);
              }
           }

         // 2. Identify New Boxes
         if(i > InpBaseAvgLookback + InpBaseMaxCandles)
           {
            double sum_body = 0;
            for(int j = 1; j <= InpBaseAvgLookback; j++) sum_body += MathAbs(close[i-j] - open[i-j]);
            double avg_body = sum_body / InpBaseAvgLookback;

            if(avg_body > 0)
              {
               double cur_body = MathAbs(val_c - open[i]);
               if(cur_body > avg_body * InpBigCandleMult)
                 {
                  bool is_bullish = val_c > open[i];
                  int base_start = 1;
                  int base_count = 0;
                  double box_top = -1;
                  double box_bot = -1;

                  while(base_count < InpBaseMaxCandles && base_start <= InpBaseAvgLookback + InpBaseMaxCandles)
                    {
                     double body = MathAbs(close[i-base_start] - open[i-base_start]);
                     if(body < avg_body)
                       {
                        if(box_top == -1 || high[i-base_start] > box_top) box_top = high[i-base_start];
                        if(box_bot == -1 || low[i-base_start] < box_bot) box_bot = low[i-base_start];
                        base_count++;
                        base_start++;
                       }
                     else break;
                    }

                  if(base_count > 0)
                    {
                     double base_height = box_top - box_bot;
                     bool is_base_large_enough = (base_height / SymbolInfoDouble(Symbol(), SYMBOL_POINT)) >= InpMinBaseHeightTicks;

                     if(is_base_large_enough)
                       {
                        double req_break_dist = base_height * (InpMinBreakoutPct / 100.0);
                        bool strong_breakout = false;

                        if(is_bullish && (val_c - box_top) >= req_break_dist)
                          {
                           if(!InpBoxTrendFilter || state.maj_tr == 1) strong_breakout = true;
                          }
                        if(!is_bullish && (box_bot - val_c) >= req_break_dist)
                          {
                           if(!InpBoxTrendFilter || state.maj_tr == -1) strong_breakout = true;
                          }

                        if(strong_breakout)
                          {
                           bool overlaps = false;
                           for(int b = 0; b < state.active_boxes.Size(); b++)
                             {
                              SBox ab = state.active_boxes.Get(b);
                              if(!(box_bot > ab.top || box_top < ab.bot)) { overlaps = true; break; }
                             }

                           if(!overlaps)
                             {
                              SBox new_box;
                              new_box.start_t = time[i-base_start+1];
                              new_box.end_t = time[i] + PeriodSeconds() * 5;
                              new_box.top = box_top;
                              new_box.bot = box_bot;
                              new_box.is_bull = is_bullish;
                              new_box.name_main = "IMB_"+IntegerToString((int)time[i]);

                              double box_pct = (base_height / box_bot) * 100.0;
                              if(box_pct <= InpMaxBoxPct)
                                {
                                 double wk_dist = base_height * (InpWeakZonePct / 100.0);
                                 if(!is_bullish) new_box.name_abv = "IMB_ABV_"+IntegerToString((int)time[i]);
                                 else new_box.name_abv = "";

                                 if(is_bullish) new_box.name_blw = "IMB_BLW_"+IntegerToString((int)time[i]);
                                 else new_box.name_blw = "";
                                }
                              else
                                {
                                 new_box.name_abv = "";
                                 new_box.name_blw = "";
                                }

                              state.active_boxes.Add(new_box);
                             }
                          }
                       }
                    }
                 }
              }
           }
        } // End Box Logic

      // Minor Structure Logic
      bool in_pb = false;
      if(state.maj_tr == 1 && state.maj_st == 0)
        {
         double p_pct = (state.tmp_h - val_c) / (state.tmp_h - state.anc_v) * 100.0;
         if(p_pct >= InpMinPullbackPct && p_pct <= InpMaxPullbackPct) in_pb = true;
        }
      else if(state.maj_tr == -1 && state.maj_st == 0)
        {
         double p_pct = (val_c - state.tmp_l) / (state.anc_v - state.tmp_l) * 100.0;
         if(p_pct >= InpMinPullbackPct && p_pct <= InpMaxPullbackPct) in_pb = true;
        }

      if(state.min_tr == 1)
        {
         double ot = state.trig_l;
         if(val_h > state.min_h)
           {
            state.min_h = val_h;
            state.min_h_i = i;
            state.trig_l = val_l;
           }

         if(val_l < ot)
           {
            int ti = state.min_h_i;
            double tp = state.min_h;
            int si = state.lp_i;
            double sp = state.lp_p;

            DrawMinorLine(time[si], sp, time[ti], tp);

            if(state.maj_tr == -1 && !state.has_pot_bull_minor && si >= state.tmp_l_i)
              {
               state.has_pot_bull_minor = true;
               state.pot_bull_start_i = si;
               state.pot_bull_start_p = sp;
               state.pot_bull_end_p = tp;
              }

            if(state.maj_st == 0 && state.maj_tr == -1 && state.bx_phase == 1)
              {
               if(state.bx_extreme && tp > state.bx_swing_h) { state.bx_phase = 2; state.bx_extreme = false; }
               else state.bx_swing_h = tp;
              }

            state.st_h_val.Push(tp);
            state.st_h_idx.Push(ti);

            if(state.maj_tr == 1 && state.maj_st == 0 && tp < state.tmp_h && state.st_l_val.Size() > 0)
              {
               if(state.st_l_idx.Get(state.st_l_idx.Size()-1) > state.bos_i)
                 {
                  state.st_l_val.Pop();
                  state.st_l_idx.Pop();
                 }
              }

            if(state.choch_dir == -1 && state.t2_h != 0) state.choch_dir = 0;
            if(state.choch_dir == 1 && state.t2_l != 0 && state.min_h <= state.d1_h) state.choch_dir = 0;
            if(state.choch_dir != 0 && !in_pb) state.choch_dir = 0;

            if(state.maj_tr == -1 && in_pb)
              {
               if(state.choch_dir == 0 || state.choch_dir == 1)
                 {
                  state.t1_h = state.min_h;
                  state.t1_l = state.min_l;
                  state.t1_i = state.min_h_i;
                  state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
                  state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
                  state.choch_dir = -1;
                 }
               else if(state.choch_dir == -1)
                 {
                  if(state.d1_l == 0) { state.d1_l = state.min_l; state.d1_i = state.min_l_i; }
                  if(state.d1_l != 0 && state.t2_h == 0) { state.t2_h = state.min_h; state.t2_i = state.min_h_i; }
                 }
              }

            state.min_tr = -1;
            state.lp_i = ti;
            state.lp_p = tp;
            state.min_l = val_l;
            state.min_l_i = i;
            state.trig_h = val_h;
           }
        }
      else
        {
         double ot = state.trig_h;
         if(val_l < state.min_l)
           {
            state.min_l = val_l;
            state.min_l_i = i;
            state.trig_h = val_h;
           }

         if(val_h > ot)
           {
            int ti = state.min_l_i;
            double tp = state.min_l;
            int si = state.lp_i;
            double sp = state.lp_p;

            DrawMinorLine(time[si], sp, time[ti], tp);

            if(state.maj_tr == 1 && !state.has_pot_bear_minor && si >= state.tmp_h_i)
              {
               state.has_pot_bear_minor = true;
               state.pot_bear_start_i = si;
               state.pot_bear_start_p = sp;
               state.pot_bear_end_p = tp;
              }

            if(state.maj_st == 0 && state.maj_tr == 1 && state.bx_phase == 1)
              {
               if(state.bx_extreme && tp < state.bx_swing_l) { state.bx_phase = 2; state.bx_extreme = false; }
               else state.bx_swing_l = tp;
              }

            state.st_l_val.Push(tp);
            state.st_l_idx.Push(ti);

            if(state.maj_tr == -1 && state.maj_st == 0 && tp > state.tmp_l && state.st_h_val.Size() > 0)
              {
               if(state.st_h_idx.Get(state.st_h_idx.Size()-1) > state.bos_i)
                 {
                  state.st_h_val.Pop();
                  state.st_h_idx.Pop();
                 }
              }

            if(state.choch_dir == 1 && state.t2_l != 0) state.choch_dir = 0;
            if(state.choch_dir == -1 && state.t2_h != 0 && state.min_l >= state.d1_l) state.choch_dir = 0;
            if(state.choch_dir != 0 && !in_pb) state.choch_dir = 0;

            if(state.maj_tr == 1 && in_pb)
              {
               if(state.choch_dir == 0 || state.choch_dir == -1)
                 {
                  state.t1_l = state.min_l;
                  state.t1_h = state.min_h;
                  state.t1_i = state.min_l_i;
                  state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
                  state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
                  state.choch_dir = 1;
                 }
               else if(state.choch_dir == 1)
                 {
                  if(state.d1_h == 0) { state.d1_h = state.min_h; state.d1_i = state.min_h_i; }
                  if(state.d1_h != 0 && state.t2_l == 0) { state.t2_l = state.min_l; state.t2_i = state.min_l_i; }
                 }
              }

            state.min_tr = 1;
            state.lp_i = ti;
            state.lp_p = tp;
            state.min_h = val_h;
            state.min_h_i = i;
            state.trig_l = val_l;
           }
        }

      // CHoCH Trigger Logic
      if(state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0)
        {
         if(val_c < state.d1_l && in_pb)
           {
            bool is_strong = state.t2_h > state.t1_h;
            DrawChochLine(time[i], state.d1_l, time[i] + PeriodSeconds()*5, state.d1_l, is_strong, time[state.t1_i], state.d1_l);
            state.choch_dir = 0;
           }
        }

      if(state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0)
        {
         if(val_c > state.d1_h && in_pb)
           {
            bool is_strong = state.t2_l < state.t1_l;
            DrawChochLine(time[i], state.d1_h, time[i] + PeriodSeconds()*5, state.d1_h, is_strong, time[state.t1_i], state.d1_h);
            state.choch_dir = 0;
           }
        }

      // Major Structure Logic
      if(state.maj_tr == 1)
        {
         if(state.maj_st == 0)
           {
            if(val_h > state.tmp_h) { state.tmp_h = val_h; state.tmp_h_i = i; state.has_pot_bear_minor = false; }
            if(state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l) { state.maj_l = val_l; state.maj_l_i = i; }
            if(state.maj_l != 0 && val_c < state.maj_l)
              {
               state.choch_dir = 0; state.swept_choch = false;
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0;
               state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
               state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_h = state.tmp_h; state.maj_h_i = state.tmp_h_i;
               state.bos_i = i; state.bos_count++;
               DrawMajorLine(time[state.anc_i], state.anc_v, time[state.maj_h_i], state.maj_h, InpColorBull);
               state.st_l_val.Clear(); state.st_l_idx.Clear();
               state.maj_st = 1;
               state.anc_i = state.maj_h_i; state.anc_v = state.maj_h;
               state.tmp_l = val_l; state.tmp_l_i = i;
               state.bx_phase = 0; state.bx_swing_l = val_l; state.bx_swing_h = state.maj_h;
              }
           }
         else if(state.maj_st == 1)
           {
            if(val_l < state.tmp_l) { state.tmp_l = val_l; state.tmp_l_i = i; state.has_pot_bull_minor = false; }
            if(state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h) { state.maj_h = val_h; state.maj_h_i = i; state.swept_choch = true; }
            if(state.maj_h != 0 && val_c > state.maj_h)
              {
               state.choch_dir = 0; state.swept_choch = false;
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0;
               state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
               state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_tr = -1; state.maj_st = 0;
               state.bos_i = i; state.bos_count = 0;
               DrawMajorLine(time[state.anc_i], state.anc_v, time[state.tmp_h_i], state.tmp_h, InpColorBull);
               state.st_h_val.Clear(); state.st_h_idx.Clear();
               state.anc_i = state.tmp_h_i; state.anc_v = state.tmp_h;
               state.tmp_l = val_l; state.tmp_l_i = i;
               state.maj_h = state.tmp_h; state.maj_h_i = state.tmp_h_i;
               state.bx_phase = 0; state.bx_swing_l = state.tmp_h; state.bx_swing_h = val_l;
               state.has_pot_bear_minor = false;
              }
           }
        }
      else if(state.maj_tr == -1)
        {
         if(state.maj_st == 0)
           {
            if(val_l < state.tmp_l) { state.tmp_l = val_l; state.tmp_l_i = i; state.has_pot_bull_minor = false; }
            if(state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h) { state.maj_h = val_h; state.maj_h_i = i; }
            if(state.maj_h != 0 && val_c > state.maj_h)
              {
               state.choch_dir = 0; state.swept_choch = false;
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0;
               state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
               state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
               state.bos_i = i; state.bos_count++;
               DrawMajorLine(time[state.anc_i], state.anc_v, time[state.maj_l_i], state.maj_l, InpColorBear);
               state.st_h_val.Clear(); state.st_h_idx.Clear();
               state.maj_st = 1;
               state.anc_i = state.maj_l_i; state.anc_v = state.maj_l;
               state.tmp_h = val_h; state.tmp_h_i = i;
               state.bx_phase = 0; state.bx_swing_l = state.maj_l; state.bx_swing_h = val_h;
              }
           }
         else if(state.maj_st == 1)
           {
            if(val_h > state.tmp_h) { state.tmp_h = val_h; state.tmp_h_i = i; state.has_pot_bear_minor = false; }
            if(state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l) { state.maj_l = val_l; state.maj_l_i = i; }
            if(state.maj_l != 0 && val_c < state.maj_l)
              {
               state.choch_dir = 0; state.swept_choch = false;
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0;
               state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
               state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_h = state.tmp_h; state.maj_h_i = state.tmp_h_i;
               state.bos_i = i; state.bos_count++;
               DrawMajorLine(time[state.anc_i], state.anc_v, time[state.maj_h_i], state.maj_h, InpColorBear);
               state.st_l_val.Clear(); state.st_l_idx.Clear();
               state.maj_st = 0;
               state.anc_i = state.maj_h_i; state.anc_v = state.maj_h;
               state.tmp_l = val_l; state.tmp_l_i = i;
               state.bx_phase = 0; state.bx_swing_l = val_l; state.bx_swing_h = state.maj_h;
              }
            if(state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h) { state.maj_h = val_h; state.maj_h_i = i; state.swept_choch = true; }
            if(state.maj_h != 0 && val_c > state.maj_h)
              {
               state.choch_dir = 0; state.swept_choch = false;
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0;
               state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
               state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_tr = 1; state.maj_st = 0;
               state.bos_i = i; state.bos_count = 0;
               DrawMajorLine(time[state.anc_i], state.anc_v, time[state.tmp_l_i], state.tmp_l, InpColorBear);
               state.st_h_val.Clear(); state.st_h_idx.Clear();
               state.anc_i = state.tmp_l_i; state.anc_v = state.tmp_l;
               state.tmp_h = val_h; state.tmp_h_i = i;
               state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
               state.bx_phase = 0; state.bx_swing_l = state.tmp_l; state.bx_swing_h = val_h;
               state.has_pot_bull_minor = false;
              }
           }
        }
     } // End !is_inside
  }

int OnInit()
  {
   ObjectsDeleteAll(0, 0);

   g_state_hist.Init();
   g_state_curr.Init();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, 0);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < 100) return 0;

   ArraySetAsSeries(time, false);
   ArraySetAsSeries(open, false);
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(close, false);

   int limit = prev_calculated == 0 ? 1 : prev_calculated - 1;

   if(prev_calculated == 0)
     {
      int days = (int)InpDaysM1;
      datetime start_time = TimeCurrent() - days * 24 * 60 * 60;
      int start_idx = 1;
      for(int i = rates_total - 1; i >= 0; i--)
        {
         if(time[i] <= start_time)
           {
            start_idx = i;
            break;
           }
        }
      limit = start_idx;
      g_state_hist.Init();
      g_state_hist.min_h = high[limit]; g_state_hist.min_h_i = limit;
      g_state_hist.min_l = low[limit]; g_state_hist.min_l_i = limit;
      g_state_hist.trig_h = high[limit]; g_state_hist.trig_l = low[limit];
      g_state_hist.tmp_h = high[limit]; g_state_hist.tmp_h_i = limit;
      g_state_hist.tmp_l = low[limit]; g_state_hist.tmp_l_i = limit;
      g_state_hist.min_tr = (close[limit] > open[limit]) ? 1 : -1;
      g_state_hist.maj_tr = 0; g_state_hist.maj_st = 0; g_state_hist.bos_i = 0;
     }

   for(int i = limit; i < rates_total - 1; i++)
     {
      ProcessBar(i, open, high, low, close, time, g_state_hist);
     }

   g_state_curr.CopyFrom(g_state_hist);
   ProcessBar(rates_total - 1, open, high, low, close, time, g_state_curr);

   return(rates_total);
  }
