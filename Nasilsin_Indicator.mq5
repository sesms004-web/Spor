//+------------------------------------------------------------------+
//|                                            Nasilsin_Indicator.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

//--- Lookback ---
input double InpDaysM1   = 3.0;
input double InpDaysM3   = 10.0;
input double InpDaysM5   = 15.0;
input double InpDaysM15  = 45.0;
input double InpDaysM30  = 90.0;
input double InpDaysH1   = 180.0;
input double InpDaysH4   = 500.0;
input double InpDaysD1   = 1500.0;

//--- CHoCH ---
input double InpMinPullbackPct = 40.0;
input double InpMaxPullbackPct = 100.0;
input color  InpColorChochStrong = clrPurple;
input color  InpColorChochWeak = clrRed;
input color  InpColorChochPath = clrGray;
input bool   InpShowChoch = true;

//--- Structure ---
input bool   InpShowMin = true;
input bool   InpShowMaj = true;
input color  InpColorMin = clrRed;
input color  InpColorBear = clrRed;
input color  InpColorBull = clrGreen;

//--- Base-Drop Box ---
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

//--- Globals ---
datetime g_anchor_time = 0;

string GetUniqueName(SState &state, string prefix)
  {
   state.g_counter++;
   return prefix + "_" + IntegerToString(state.g_counter);
  }



double GetDaysForTF(ENUM_TIMEFRAMES tf)
  {
   if(tf == PERIOD_M1) return InpDaysM1;
   if(tf == PERIOD_M3) return InpDaysM3;
   if(tf == PERIOD_M5) return InpDaysM5;
   if(tf == PERIOD_M15) return InpDaysM15;
   if(tf == PERIOD_M30) return InpDaysM30;
   if(tf == PERIOD_H1) return InpDaysH1;
   if(tf == PERIOD_H4) return InpDaysH4;
   if(tf == PERIOD_D1) return InpDaysD1;
   return InpDaysM1;
  }

void DrawLine(string name, datetime time1, double price1, datetime time2, double price2, color clr, int width, ENUM_LINE_STYLE style, bool ray_right=false)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
     }
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

void DrawRect(string name, datetime time1, double price1, datetime time2, double price2, color clr, bool bg)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price2);
     }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BACK, bg);
   ObjectSetInteger(0, name, OBJPROP_FILL, bg);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

class CStack
  {
private:
   double            m_vals[];
   int               m_idx[];
public:
                     CStack() { ArrayResize(m_vals, 0); ArrayResize(m_idx, 0); }
                    ~CStack() { }
   void              Clear() { ArrayResize(m_vals, 0); ArrayResize(m_idx, 0); }
   int               Size() { return ArraySize(m_vals); }
   void              Push(double val, int idx)
     {
      int size = ArraySize(m_vals);
      ArrayResize(m_vals, size + 1);
      ArrayResize(m_idx, size + 1);
      m_vals[size] = val;
      m_idx[size]  = idx;
     }
   void              Pop()
     {
      int size = ArraySize(m_vals);
      if(size > 0)
        {
         ArrayResize(m_vals, size - 1);
         ArrayResize(m_idx, size - 1);
        }
     }
   double            GetVal(int index) { return m_vals[index]; }
   int               GetIdx(int index) { return m_idx[index]; }
   void              CopyFrom(CStack &source)
     {
      ArrayCopy(m_vals, source.m_vals);
      ArrayCopy(m_idx, source.m_idx);
     }
  };

class CBox
  {
public:
   string            name_main;
   string            name_abv;
   string            name_blw;
   datetime          time_start;
   datetime          time_end;
   double            top;
   double            bot;
   bool              is_active;

   void              CopyFrom(CBox &source)
     {
      name_main = source.name_main;
      name_abv = source.name_abv;
      name_blw = source.name_blw;
      time_start = source.time_start;
      time_end = source.time_end;
      top = source.top;
      bot = source.bot;
      is_active = source.is_active;
     }
  };

struct SState
  {
   int               min_tr;
   int               maj_tr;
   int               maj_st;
   int               g_counter;

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

   CStack            st_h;
   CStack            st_l;

   CBox              boxes[];

   void              CopyFrom(SState &source)
     {
      min_tr         = source.min_tr;
      maj_tr         = source.maj_tr;
      maj_st         = source.maj_st;
      g_counter      = source.g_counter;

      min_h          = source.min_h;
      min_h_i        = source.min_h_i;
      min_l          = source.min_l;
      min_l_i        = source.min_l_i;
      trig_h         = source.trig_h;
      trig_l         = source.trig_l;
      lp_i           = source.lp_i;
      lp_p           = source.lp_p;

      maj_h          = source.maj_h;
      maj_h_i        = source.maj_h_i;
      maj_l          = source.maj_l;
      maj_l_i        = source.maj_l_i;

      tmp_h          = source.tmp_h;
      tmp_h_i        = source.tmp_h_i;
      tmp_l          = source.tmp_l;
      tmp_l_i        = source.tmp_l_i;

      anc_i          = source.anc_i;
      anc_v          = source.anc_v;
      bos_i          = source.bos_i;
      bos_count      = source.bos_count;

      mb_h           = source.mb_h;
      mb_l           = source.mb_l;
      mb_i           = source.mb_i;

      t1_h           = source.t1_h;
      t1_l           = source.t1_l;
      t1_i           = source.t1_i;
      d1_h           = source.d1_h;
      d1_l           = source.d1_l;
      d1_i           = source.d1_i;
      t2_h           = source.t2_h;
      t2_l           = source.t2_l;
      t2_i           = source.t2_i;

      choch_dir      = source.choch_dir;
      swept_choch    = source.swept_choch;

      bx_phase       = source.bx_phase;
      bx_extreme     = source.bx_extreme;
      bx_swing_h     = source.bx_swing_h;
      bx_swing_l     = source.bx_swing_l;

      has_pot_bull_minor = source.has_pot_bull_minor;
      pot_bull_start_i = source.pot_bull_start_i;
      pot_bull_start_p = source.pot_bull_start_p;
      pot_bull_end_p = source.pot_bull_end_p;

      has_pot_bear_minor = source.has_pot_bear_minor;
      pot_bear_start_i = source.pot_bear_start_i;
      pot_bear_start_p = source.pot_bear_start_p;
      pot_bear_end_p = source.pot_bear_end_p;

      st_h.CopyFrom(source.st_h);
      st_l.CopyFrom(source.st_l);

      int b_size = ArraySize(source.boxes);
      ArrayResize(boxes, b_size);
      for(int i=0; i<b_size; i++)
         boxes[i].CopyFrom(source.boxes[i]);
     }
  };

SState g_state_hist;
SState g_state_curr;

void ProcessBar(int i, const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], SState &state, bool is_history)
  {
   double val_h = high[i];
   double val_l = low[i];
   double val_c = close[i];
   double val_o = open[i];
   datetime t = time[i];

   string prefix = is_history ? "" : "Live_";

   bool is_inside = (val_h <= state.mb_h && val_l >= state.mb_l);

   if(!is_inside)
     {
      if(val_h > state.mb_h || val_l < state.mb_l)
        {
         state.mb_h = val_h;
         state.mb_l = val_l;
         state.mb_i = i;
        }

      // Base Drop Logic & Box Trimming
      if(InpShowBox)
        {
         // 1. Trim active boxes
         for(int k=ArraySize(state.boxes)-1; k>=0; k--)
           {
            if(state.boxes[k].is_active)
              {
               if(val_h >= state.boxes[k].bot && val_l <= state.boxes[k].top)
                 {
                  state.boxes[k].time_end = t;
                  state.boxes[k].is_active = false;
                  ObjectSetInteger(0, state.boxes[k].name_main, OBJPROP_TIME, 1, t);
                  ObjectSetInteger(0, state.boxes[k].name_abv, OBJPROP_TIME, 1, t);
                  ObjectSetInteger(0, state.boxes[k].name_blw, OBJPROP_TIME, 1, t);
                 }
               else
                 {
                  state.boxes[k].time_end = time[MathMin(i+5, ArraySize(time)-1)];
                  ObjectSetInteger(0, state.boxes[k].name_main, OBJPROP_TIME, 1, state.boxes[k].time_end);
                  ObjectSetInteger(0, state.boxes[k].name_abv, OBJPROP_TIME, 1, state.boxes[k].time_end);
                  ObjectSetInteger(0, state.boxes[k].name_blw, OBJPROP_TIME, 1, state.boxes[k].time_end);
                 }
              }
           }

         // 2. Identify New Boxes
         int req_bars = InpBaseAvgLookback + InpBaseMaxCandles;
         if(i > req_bars)
           {
            double sum_body = 0;
            for(int j=1; j<=InpBaseAvgLookback; j++)
               sum_body += MathAbs(close[i-j] - open[i-j]);
            double avg_body = sum_body / InpBaseAvgLookback;

            if(avg_body > 0)
              {
               double cur_body = MathAbs(val_c - val_o);
               if(cur_body > avg_body * InpBigCandleMult)
                 {
                  bool is_bullish = val_c > val_o;
                  int base_start = 1;
                  int base_count = 0;
                  double box_top = -1;
                  double box_bot = -1;

                  while(base_count < InpBaseMaxCandles && base_start <= req_bars)
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

                  bool strong_breakout = false;
                  if(base_count > 0)
                    {
                     double base_height = box_top - box_bot;
                     bool is_base_large_enough = (base_height / SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE)) >= InpMinBaseHeightTicks;
                     if(is_base_large_enough)
                       {
                        double req_break_dist = base_height * (InpMinBreakoutPct / 100.0);
                        if(is_bullish && (val_c - box_top) >= req_break_dist)
                          {
                           if(!InpBoxTrendFilter || state.maj_tr == 1) strong_breakout = true;
                          }
                        if(!is_bullish && (box_bot - val_c) >= req_break_dist)
                          {
                           if(!InpBoxTrendFilter || state.maj_tr == -1) strong_breakout = true;
                          }
                       }
                    }

                  bool is_overlapping = false;
                  if(strong_breakout)
                    {
                     for(int k=0; k<ArraySize(state.boxes); k++)
                       {
                        if(state.boxes[k].is_active)
                          {
                           if(!(box_top < state.boxes[k].bot || box_bot > state.boxes[k].top))
                             {
                              is_overlapping = true;
                              break;
                             }
                          }
                       }
                    }

                  if(strong_breakout && !is_overlapping)
                    {
                     color box_clr = is_bullish ? InpColorBoxBull : InpColorBoxBear;
                     color wk_clr = is_bullish ? InpColorWeakBull : InpColorWeakBear;
                     double wk_sz = (box_top - box_bot) * InpWeakZonePct / 100.0;

                     int size = ArraySize(state.boxes);
                     ArrayResize(state.boxes, size + 1);
                     state.boxes[size].name_main = GetUniqueName(state, prefix + "Box_");
                     state.boxes[size].name_abv = GetUniqueName(state, prefix + "BoxA_");
                     state.boxes[size].name_blw = GetUniqueName(state, prefix + "BoxB_");
                     state.boxes[size].time_start = time[i-base_start+1];
                     state.boxes[size].time_end = time[MathMin(i+5, ArraySize(time)-1)];
                     state.boxes[size].top = box_top;
                     state.boxes[size].bot = box_bot;
                     state.boxes[size].is_active = true;

                     DrawRect(state.boxes[size].name_main, state.boxes[size].time_start, box_top, state.boxes[size].time_end, box_bot, box_clr, true); DrawRect(state.boxes[size].name_abv, state.boxes[size].time_start, box_top + wk_sz, state.boxes[size].time_end, box_top, wk_clr, true); DrawRect(state.boxes[size].name_blw, state.boxes[size].time_start, box_bot, state.boxes[size].time_end, box_bot - wk_sz, wk_clr, true);
                    }
                 }
              }
           }
        }

      // Pullback Pct calculation
      double ch_h = state.maj_h;
      double ch_l = state.maj_l;
      if(state.maj_st == 0)
        {
         if(state.maj_tr == 1 && state.tmp_h != 0) ch_h = state.tmp_h;
         if(state.maj_tr == -1 && state.tmp_l != 0) ch_l = state.tmp_l;
        }

      double p_pct = 0;
      if(ch_h != ch_l && ch_h != 0 && ch_l != 0)
        {
         double rng = ch_h - ch_l;
         if(rng > 0)
           {
            if(state.maj_tr == 1 && val_l >= ch_l) p_pct = ((ch_h - val_l) / rng) * 100.0;
            if(state.maj_tr == -1 && val_h <= ch_h) p_pct = ((val_h - ch_l) / rng) * 100.0;
           }
        }

      bool in_pb = (p_pct >= InpMinPullbackPct && p_pct <= InpMaxPullbackPct);

      // Minor Structure processing
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

            if(InpShowMin) DrawLine(GetUniqueName(state, prefix + "Minor_"), time[si], sp, time[ti], tp, InpColorMin, 1, STYLE_SOLID);

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

            state.st_h.Push(tp, ti);

            if(state.maj_tr == 1 && state.maj_st == 0 && tp < state.tmp_h && state.st_l.Size() > 0)
              {
               if(state.st_l.GetIdx(state.st_l.Size()-1) > state.bos_i) state.st_l.Pop();
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

            if(InpShowMin) DrawLine(GetUniqueName(state, prefix + "Minor_"), time[si], sp, time[ti], tp, InpColorMin, 1, STYLE_SOLID);

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

            state.st_l.Push(tp, ti);

            if(state.maj_tr == -1 && state.maj_st == 0 && tp > state.tmp_l && state.st_h.Size() > 0)
              {
               if(state.st_h.GetIdx(state.st_h.Size()-1) > state.bos_i) state.st_h.Pop();
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
                  state.d1_l = 0; state.d1_h = 0; state.d1_i = 0;
                  state.t2_l = 0; state.t2_h = 0; state.t2_i = 0;
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
            if(InpShowChoch)
              {
               color c = is_strong ? InpColorChochStrong : InpColorChochWeak;
               DrawLine(GetUniqueName(state, prefix + "CHoCH_"), time[i], state.d1_l, time[MathMin(i+5, ArraySize(time)-1)], state.d1_l, c, 3, STYLE_SOLID);
               DrawLine(GetUniqueName(state, prefix + "CHoCHPath_"), time[state.t1_i], state.d1_l, time[i], state.d1_l, InpColorChochPath, 1, STYLE_DOT);
              }
            state.choch_dir = 0;
           }
        }
      if(state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0)
        {
         if(val_c > state.d1_h && in_pb)
           {
            bool is_strong = state.t2_l < state.t1_l;
            if(InpShowChoch)
              {
               color c = is_strong ? InpColorChochStrong : InpColorChochWeak;
               DrawLine(GetUniqueName(state, prefix + "CHoCH_"), time[i], state.d1_h, time[MathMin(i+5, ArraySize(time)-1)], state.d1_h, c, 3, STYLE_SOLID);
               DrawLine(GetUniqueName(state, prefix + "CHoCHPath_"), time[state.t1_i], state.d1_h, time[i], state.d1_h, InpColorChochPath, 1, STYLE_DOT);
              }
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
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0; state.d1_h = 0; state.d1_l = 0; state.d1_i = 0; state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_h = state.tmp_h; state.maj_h_i = state.tmp_h_i;
               state.bos_i = i; state.bos_count++;
               if(InpShowMaj) DrawLine(GetUniqueName(state, prefix + "Major_"), time[state.anc_i], state.anc_v, time[state.maj_h_i], state.maj_h, InpColorBull, 2, STYLE_SOLID);
               state.st_l.Clear();
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
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0; state.d1_h = 0; state.d1_l = 0; state.d1_i = 0; state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_tr = -1; state.maj_st = 0;
               state.bos_i = i; state.bos_count = 0;
               if(InpShowMaj) DrawLine(GetUniqueName(state, prefix + "Major_"), time[state.anc_i], state.anc_v, time[state.tmp_h_i], state.tmp_h, InpColorBull, 2, STYLE_SOLID);
               state.st_h.Clear();
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
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0; state.d1_h = 0; state.d1_l = 0; state.d1_i = 0; state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
               state.bos_i = i; state.bos_count++;
               if(InpShowMaj) DrawLine(GetUniqueName(state, prefix + "Major_"), time[state.anc_i], state.anc_v, time[state.maj_l_i], state.maj_l, InpColorBear, 2, STYLE_SOLID);
               state.st_h.Clear();
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
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0; state.d1_h = 0; state.d1_l = 0; state.d1_i = 0; state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_h = state.tmp_h; state.maj_h_i = state.tmp_h_i;
               state.bos_i = i; state.bos_count++;
               if(InpShowMaj) DrawLine(GetUniqueName(state, prefix + "Major_"), time[state.anc_i], state.anc_v, time[state.maj_h_i], state.maj_h, InpColorBear, 2, STYLE_SOLID);
               state.st_l.Clear();
               state.maj_st = 0;
               state.anc_i = state.maj_h_i; state.anc_v = state.maj_h;
               state.tmp_l = val_l; state.tmp_l_i = i;
               state.bx_phase = 0; state.bx_swing_l = val_l; state.bx_swing_h = state.maj_h;
              }
            if(state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h) { state.maj_h = val_h; state.maj_h_i = i; state.swept_choch = true; }
            if(state.maj_h != 0 && val_c > state.maj_h)
              {
               state.choch_dir = 0; state.swept_choch = false;
               state.t1_h = 0; state.t1_l = 0; state.t1_i = 0; state.d1_h = 0; state.d1_l = 0; state.d1_i = 0; state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
               state.maj_tr = 1; state.maj_st = 0;
               state.bos_i = i; state.bos_count = 0;
               if(InpShowMaj) DrawLine(GetUniqueName(state, prefix + "Major_"), time[state.anc_i], state.anc_v, time[state.tmp_l_i], state.tmp_l, InpColorBear, 2, STYLE_SOLID);
               state.st_h.Clear();
               state.anc_i = state.tmp_l_i; state.anc_v = state.tmp_l;
               state.tmp_h = val_h; state.tmp_h_i = i;
               state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
               state.bx_phase = 0; state.bx_swing_l = state.tmp_l; state.bx_swing_h = val_h;
               state.has_pot_bull_minor = false;
              }
           }
        }
     }
  }


int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "Box_");
   ObjectsDeleteAll(0, "BoxA_");
   ObjectsDeleteAll(0, "BoxB_");
   ObjectsDeleteAll(0, "Minor_");
   ObjectsDeleteAll(0, "Major_");
   ObjectsDeleteAll(0, "CHoCH_");
   ObjectsDeleteAll(0, "CHoCHPath_");
   ObjectsDeleteAll(0, "LiveLeg_");
   ObjectsDeleteAll(0, "Live_");
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
   if(rates_total < 2) return(0);

   if(prev_calculated == 0)
     {
      double tf_days = GetDaysForTF(Period());
      g_anchor_time = TimeCurrent() - (datetime)(tf_days * 24.0 * 60.0 * 60.0);

      ObjectsDeleteAll(0, "Box_");
      ObjectsDeleteAll(0, "BoxA_");
      ObjectsDeleteAll(0, "BoxB_");
      ObjectsDeleteAll(0, "Minor_");
      ObjectsDeleteAll(0, "Major_");
      ObjectsDeleteAll(0, "CHoCH_");
      ObjectsDeleteAll(0, "CHoCHPath_");
      ObjectsDeleteAll(0, "LiveLeg_");

      int start_idx = 0;
      for(int k=0; k<rates_total; k++)
        {
         if(time[k] >= g_anchor_time)
           {
            start_idx = k;
            break;
           }
        }

      g_state_hist.min_tr = close[start_idx] > open[start_idx] ? 1 : -1;
      g_state_hist.maj_tr = g_state_hist.min_tr;
      g_state_hist.maj_st = 1;
      g_state_hist.g_counter = 0;
      g_state_hist.min_h   = high[start_idx];
      g_state_hist.min_h_i = start_idx;
      g_state_hist.min_l   = low[start_idx];
      g_state_hist.min_l_i = start_idx;
      g_state_hist.trig_h  = high[start_idx];
      g_state_hist.trig_l  = low[start_idx];
      g_state_hist.tmp_h   = high[start_idx];
      g_state_hist.tmp_h_i = start_idx;
      g_state_hist.tmp_l   = low[start_idx];
      g_state_hist.tmp_l_i = start_idx;
      g_state_hist.anc_i   = start_idx;
      g_state_hist.anc_v   = close[start_idx];
      g_state_hist.lp_i    = start_idx;
      g_state_hist.lp_p    = close[start_idx];
      g_state_hist.bos_i   = start_idx;
      g_state_hist.bos_count = 0;
      g_state_hist.mb_h    = high[start_idx];
      g_state_hist.mb_l    = low[start_idx];
      g_state_hist.mb_i    = start_idx;
      g_state_hist.t1_h = 0; g_state_hist.t1_l = 0; g_state_hist.t1_i = 0;
      g_state_hist.d1_h = 0; g_state_hist.d1_l = 0; g_state_hist.d1_i = 0;
      g_state_hist.t2_h = 0; g_state_hist.t2_l = 0; g_state_hist.t2_i = 0;
      g_state_hist.choch_dir = 0;

      double atr = high[start_idx] - low[start_idx] == 0 ? SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE) * 10 : high[start_idx] - low[start_idx];
      g_state_hist.maj_h = high[start_idx] + atr * 0.1;
      g_state_hist.maj_l = low[start_idx] - atr * 0.1;
      g_state_hist.bx_phase = 0;
      g_state_hist.bx_extreme = false;
      g_state_hist.bx_swing_l = low[start_idx];
      g_state_hist.bx_swing_h = high[start_idx];
      g_state_hist.st_h.Clear();
      g_state_hist.st_l.Clear();
      ArrayResize(g_state_hist.boxes, 0);

     }

   int limit = (prev_calculated == 0) ? start_idx : prev_calculated - 1;

   // 1. Process all newly completed bars into the historical state
   for(int i = limit; i < rates_total - 1; i++)
     {
      ProcessBar(i, open, high, low, close, time, g_state_hist, true);
     }

   // 2. Branch off the historical state for the current unclosed bar
   ObjectsDeleteAll(0, "Live_");
   g_state_curr.CopyFrom(g_state_hist);
   ProcessBar(rates_total-1, open, high, low, close, time, g_state_curr, false);

   // Draw Live Minor Leg
   if(InpShowMin)
     {
      string name = "LiveLeg_";
      if(g_state_curr.min_tr == 1)
         DrawLine(name, time[g_state_curr.lp_i], g_state_curr.lp_p, time[g_state_curr.min_h_i], g_state_curr.min_h, InpColorMin, 1, STYLE_SOLID);
      else
         DrawLine(name, time[g_state_curr.lp_i], g_state_curr.lp_p, time[g_state_curr.min_l_i], g_state_curr.min_l, InpColorMin, 1, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
     }



   return(rates_total);
  }
