//+------------------------------------------------------------------+
//|                                                    Structure.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

//--- Input Settings for Calculation Depth (Days Back) ---
input double InpDaysM1   = 3.0;
input double InpDaysM3   = 10.0;
input double InpDaysM5   = 15.0;
input double InpDaysM15  = 45.0;
input double InpDaysM30  = 90.0;
input double InpDaysH1   = 180.0;
input double InpDaysH4   = 500.0;
input double InpDaysD1   = 1500.0;

//--- Visual Options ---
input bool   InpShowMin = true;
input bool   InpShowMaj = true;
input color  InpColorMin = clrRed;
input color  InpColorBull = clrGreen;
input color  InpColorBear = clrRed;

//--- Alert Settings ---
input double InpTriggerLevel1    = 40.0;             // 1. Bildirim Çekilme % (örn. %40)
input double InpTriggerLevel2    = 60.0;             // 2. Bildirim Çekilme % (örn. %60)
input double InpGoodPullbackPct  = 40.0;
input double InpMomentumMinPeak  = 30.0;
input double InpMomentumMinBounce= 20.0;
input bool   InpAlertPopup       = true;
input bool   InpAlertPush        = false;
input bool   InpNotificationFilter = false;          // Bildirim Filtresi (True: Sadece Swing İçi, False: Kırılımdan İtibaren)
input bool   InpTestMode         = false;

//--- Onay ve İşlem Yüzdeliği ---
input double InpOnayIslemYuzdeMin = 20.0;
input double InpOnayIslemYuzdeMax = 100.0;

//--- Globals ---
int g_counter = 0;
datetime g_last_alert_time = 0;
int g_alert_bar_index = -1;
datetime g_anchor_time = 0;

double g_last_alert_maj_h = 0;
double g_last_alert_maj_l = 0;
int g_last_alert_trend = 0;
bool g_level1_triggered = false;
bool g_level2_triggered = false;
bool g_level1_missed = false;
bool g_level2_missed = false;

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

void DeleteLine(string name)
  {
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
  }

void CutLine(string name, datetime time_cut)
  {
   if(ObjectFind(0, name) >= 0)
     {
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time_cut);
     }
  }

void UpdateLineLevel(string name, double level)
  {
   if(ObjectFind(0, name) >= 0)
     {
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, level);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, level);
     }
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
   double            maj_l;
   int               maj_h_i;
   int               maj_l_i;

   double            tmp_h;
   int               tmp_h_i;
   double            tmp_l;
   int               tmp_l_i;
   int               anc_i;
   double            anc_v;
   int               bos_i;

   string            cur_top_line;
   string            cur_bot_line;

   CStack            st_h;
   CStack            st_l;

   // CHoCH Detection Variables
   bool              choch_active;
   int               choch_last_dir; // 1: uptrend choch triggered, -1: downtrend choch triggered
   datetime          choch_t1_time;
   double            choch_t1_val;
   datetime          choch_d1_time;
   double            choch_d1_val;
   datetime          choch_t2_time;
   double            choch_t2_val;
   datetime          choch_break_time;
   double            choch_break_val;
   bool              choch_is_strong;

   void              CopyFrom(SState &source)
     {
      min_tr         = source.min_tr;
      maj_tr         = source.maj_tr;
      maj_st         = source.maj_st;

      min_h          = source.min_h;
      min_h_i        = source.min_h_i;
      min_l          = source.min_l;
      min_l_i        = source.min_l_i;
      trig_h         = source.trig_h;
      trig_l         = source.trig_l;
      lp_i           = source.lp_i;
      lp_p           = source.lp_p;

      maj_h          = source.maj_h;
      maj_l          = source.maj_l;
      maj_h_i        = source.maj_h_i;
      maj_l_i        = source.maj_l_i;

      tmp_h          = source.tmp_h;
      tmp_h_i        = source.tmp_h_i;
      tmp_l          = source.tmp_l;
      tmp_l_i        = source.tmp_l_i;
      anc_i          = source.anc_i;
      anc_v          = source.anc_v;
      bos_i          = source.bos_i;

      cur_top_line   = source.cur_top_line;
      cur_bot_line   = source.cur_bot_line;

      st_h.CopyFrom(source.st_h);
      st_l.CopyFrom(source.st_l);

      choch_active     = source.choch_active;
      choch_last_dir   = source.choch_last_dir;
      choch_t1_time    = source.choch_t1_time;
      choch_t1_val     = source.choch_t1_val;
      choch_d1_time    = source.choch_d1_time;
      choch_d1_val     = source.choch_d1_val;
      choch_t2_time    = source.choch_t2_time;
      choch_t2_val     = source.choch_t2_val;
      choch_break_time = source.choch_break_time;
      choch_break_val  = source.choch_break_val;
      choch_is_strong  = source.choch_is_strong;
     }
  };

SState g_state_hist;
SState g_state_curr;

string GetUniqueName(string prefix)
  {
   g_counter++;
   return prefix + "_" + IntegerToString(g_counter);
  }

double GetDaysForTF(ENUM_TIMEFRAMES tf)
  {
   double days = InpDaysM1;
   if(tf == PERIOD_M1) days = InpDaysM1;
   else if(tf == PERIOD_M3) days = InpDaysM3;
   else if(tf == PERIOD_M5) days = InpDaysM5;
   else if(tf == PERIOD_M15) days = InpDaysM15;
   else if(tf == PERIOD_M30) days = InpDaysM30;
   else if(tf == PERIOD_H1) days = InpDaysH1;
   else if(tf == PERIOD_H4) days = InpDaysH4;
   else if(tf == PERIOD_D1) days = InpDaysD1;

   return days;
  }

void ProcessBarMathOnly(int i, const double &high[], const double &low[], const double &close[], SState &state)
  {
   double val_h = high[i];
   double val_l = low[i];
   double val_c = close[i];

   if(state.min_tr == 1)
     {
      double old_trig = state.trig_l;
      if(val_h > state.min_h) { state.min_h = val_h; state.min_h_i = i; state.trig_l = val_l; }
      if(val_l < old_trig)
        {
         state.st_h.Push(state.min_h, state.min_h_i);
         if(state.maj_tr == 1 && state.maj_st == 0 && state.min_h < state.tmp_h && state.st_l.Size() > 0)
           {
            if(state.st_l.GetIdx(state.st_l.Size() - 1) > state.bos_i) state.st_l.Pop();
           }
         state.min_tr = -1; state.lp_i = state.min_h_i; state.lp_p = state.min_h;
         state.min_l = val_l; state.min_l_i = i; state.trig_h = val_h;
        }
     }
   else
     {
      double old_trig = state.trig_h;
      if(val_l < state.min_l) { state.min_l = val_l; state.min_l_i = i; state.trig_h = val_h; }
      if(val_h > old_trig)
        {
         state.st_l.Push(state.min_l, state.min_l_i);
         if(state.maj_tr == -1 && state.maj_st == 0 && state.min_l > state.tmp_l && state.st_h.Size() > 0)
           {
            if(state.st_h.GetIdx(state.st_h.Size() - 1) > state.bos_i) state.st_h.Pop();
           }
         state.min_tr = 1; state.lp_i = state.min_l_i; state.lp_p = state.min_l;
         state.min_h = val_h; state.min_h_i = i; state.trig_l = val_l;
        }
     }

   if(state.maj_tr == 0) { state.maj_tr = 1; state.maj_l_i = state.min_l_i; }

   if(state.maj_tr == 1)
     {
      if(val_h > state.tmp_h) { state.tmp_h = val_h; state.tmp_h_i = i; }
      if(state.maj_st == 0)
        {
         double act = state.st_l.Size() > 0 ? state.st_l.GetVal(state.st_l.Size() - 1) : EMPTY_VALUE;
         if(act != EMPTY_VALUE && val_l < act)
           {
            state.maj_h = state.tmp_h; state.maj_h_i = state.tmp_h_i;
            state.st_l.Clear(); state.st_h.Clear(); state.maj_st = 1;
            state.tmp_l = val_l; state.tmp_l_i = i;
           }
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l) state.maj_l = val_l;
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1; state.maj_st = 0; state.bos_i = i;
            state.st_l.Clear(); state.tmp_l = val_l; state.tmp_l_i = i;
            state.maj_h = state.tmp_h; state.maj_h_i = state.tmp_h_i;
           }
        }
      else if(state.maj_st == 1)
        {
         if(val_l < state.tmp_l) { state.tmp_l = val_l; state.tmp_l_i = i; }
         if(val_h > state.maj_h && val_c <= state.maj_h) state.maj_h = val_h;
         if(val_c > state.maj_h)
           {
            state.bos_i = i; state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
            state.st_h.Clear(); state.maj_st = 0; state.tmp_h = val_h; state.tmp_h_i = i;
           }
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l) state.maj_l = val_l;
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1; state.maj_st = 0; state.bos_i = i;
            state.st_l.Clear(); state.tmp_l = val_l; state.tmp_l_i = i;
            state.maj_h = state.tmp_h; state.maj_h_i = state.tmp_h_i;
           }
        }
     }
   else // maj_tr == -1
     {
      if(val_l < state.tmp_l) { state.tmp_l = val_l; state.tmp_l_i = i; }
      if(state.maj_st == 0)
        {
         double act = state.st_h.Size() > 0 ? state.st_h.GetVal(state.st_h.Size() - 1) : EMPTY_VALUE;
         if(act != EMPTY_VALUE && val_h > act)
           {
            state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
            state.st_l.Clear(); state.st_h.Clear(); state.maj_st = 1;
            state.tmp_h = val_h; state.tmp_h_i = i;
           }
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h) state.maj_h = val_h;
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.maj_tr = 1; state.maj_st = 0; state.bos_i = i;
            state.st_h.Clear(); state.tmp_h = val_h; state.tmp_h_i = i;
            state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
           }
        }
      else if(state.maj_st == 1)
        {
         if(val_h > state.tmp_h) { state.tmp_h = val_h; state.tmp_h_i = i; }
         if(val_l < state.maj_l && val_c >= state.maj_l) state.maj_l = val_l;
         if(val_c < state.maj_l)
           {
            state.maj_h = state.tmp_h; state.bos_i = i; state.maj_h_i = state.tmp_h_i;
            state.st_l.Clear(); state.maj_st = 0; state.tmp_l = val_l; state.tmp_l_i = i;
           }
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h) state.maj_h = val_h;
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.maj_tr = 1; state.maj_st = 0; state.bos_i = i;
            state.st_h.Clear(); state.tmp_h = val_h; state.tmp_h_i = i;
            state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
           }
        }
     }
  }

bool GetMTFPullback(ENUM_TIMEFRAMES tf, int &trend, double &pct, double &max_pct, datetime current_time,
                    double &ref_h, double &ref_l, datetime &ref_t_h, datetime &ref_t_l)
  {
   MqlRates rates[];
   ArraySetAsSeries(rates, false);

   double tf_days = GetDaysForTF(tf);
   datetime anchor_time = current_time - (datetime)(tf_days * 24.0 * 60.0 * 60.0);

   int copied = CopyRates(Symbol(), tf, anchor_time, current_time, rates);
   if(copied < 2) return false;

   double high[], low[], close[];
   ArrayResize(high, copied);
   ArrayResize(low, copied);
   ArrayResize(close, copied);

   for(int i=0; i<copied; i++)
     {
      high[i] = rates[i].high;
      low[i]  = rates[i].low;
      close[i] = rates[i].close;
     }

   SState st;
   st.min_h   = high[0]; st.min_h_i = 0; st.min_l   = low[0]; st.min_l_i = 0;
   st.trig_h  = high[0]; st.trig_l  = low[0];
   st.tmp_h   = high[0]; st.tmp_h_i = 0; st.tmp_l   = low[0]; st.tmp_l_i = 0;
   st.min_tr  = (close[0] > rates[0].open) ? 1 : -1;

   double initial_gap = (high[0] - low[0]);
   if(initial_gap == 0) initial_gap = Point() * 10;
   double tiny_gap = initial_gap * 0.1;

   st.maj_h = high[0] + tiny_gap;
   st.maj_l = low[0] - tiny_gap;
   st.maj_tr = st.min_tr;
   st.maj_st = 1;
   st.bos_i = 0;
   st.maj_h_i = 0;
   st.maj_l_i = 0;

   for(int i = 1; i < copied; i++)
     {
      bool inside = (high[i] <= high[i-1]) && (low[i] >= low[i-1]);
      if(!inside)
        {
         if(i == copied - 1)
           {
            double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            close[i] = bid;
            if(bid > high[i]) high[i] = bid;
            if(bid < low[i]) low[i] = bid;
           }

         ProcessBarMathOnly(i, high, low, close, st);
        }
     }

   trend = st.maj_tr;
   pct = 0;
   max_pct = 0;
   double live_p = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   ref_h = st.maj_h;
   ref_l = st.maj_l;
   if(st.maj_h_i >= 0 && st.maj_h_i < copied) ref_t_h = rates[st.maj_h_i].time; else ref_t_h = 0;
   if(st.maj_l_i >= 0 && st.maj_l_i < copied) ref_t_l = rates[st.maj_l_i].time; else ref_t_l = 0;

   if(st.maj_h != EMPTY_VALUE && st.maj_l != EMPTY_VALUE && st.maj_h != st.maj_l)
     {
      double range = st.maj_h - st.maj_l;
      if(trend == 1)
        {
         if(live_p >= st.maj_h || st.maj_st == 0)
           {
            double dyn_range = st.tmp_h - st.maj_l;
            if(dyn_range > 0) pct = ((st.tmp_h - live_p) / dyn_range) * 100.0;
            else pct = 0;
            max_pct = 0;
           }
         else
           {
            pct = ((st.maj_h - live_p) / range) * 100.0;
            max_pct = ((st.maj_h - st.tmp_l) / range) * 100.0;
           }
        }
      else if(trend == -1)
        {
         if(live_p <= st.maj_l || st.maj_st == 0)
           {
            double dyn_range = st.maj_h - st.tmp_l;
            if(dyn_range > 0) pct = ((live_p - st.tmp_l) / dyn_range) * 100.0;
            else pct = 0;
            max_pct = 0;
           }
         else
           {
            pct = ((live_p - st.maj_l) / range) * 100.0;
            max_pct = ((st.tmp_h - st.maj_l) / range) * 100.0;
           }
        }
     }

   if(pct < 0) pct = 0;
   if(pct > 100) pct = 100;
   if(max_pct < 0) max_pct = 0;
   if(max_pct > 100) max_pct = 100;
   if(max_pct < pct) max_pct = pct; // Emniyet: Max pct her zaman en az anlık pct kadar olmalı

   return true;
  }

string GetTimeAgoString(datetime past_time, datetime now_time)
  {
   if (past_time == 0) return "";
   int diff = (int)(now_time - past_time);
   if (diff < 3600) return IntegerToString(diff/60) + " Dk Önce";
   if (diff < 86400)
     {
      int h = diff/3600;
      int m = (diff%3600)/60;
      if (m > 0) return IntegerToString(h) + " Saat " + IntegerToString(m) + " Dk Önce";
      return IntegerToString(h) + " Saat Önce";
     }
   int d = diff/86400;
   int hd = (diff%86400)/3600;
   if (hd > 0) return IntegerToString(d) + " Gün " + IntegerToString(hd) + " Saat Önce";
   return IntegerToString(d) + " Gün Önce";
  }

string PctToText(double pct, double max_pct, datetime swing_time, datetime current_time)
  {
   string age = "\n   └ Oluşum: " + GetTimeAgoString(swing_time, current_time);
   string base_str = "(Çekilme: %" + DoubleToString(pct, 0) + " ↑↑%" + DoubleToString(max_pct, 0);

   if(pct <= 10.0)
     {
      // Fiyat zirvedeyse veya yeni kırılmışsa geçmiş pullback aranmaz. Şişkindir.
      if(max_pct <= 10.0) return " (Trend Şişkin, Düzeltme Bekleniyor)" + age;
      else return base_str + " - Kırılıma Hazırlanıyor)" + age;
     }
   if(pct >= InpGoodPullbackPct && pct <= 75.0) return base_str + " - İdeal Düzeltme)" + age;
   if(pct > 85.0) return base_str + " - Dönüş Riski)" + age;
   return base_str + ")" + age;
  }

//+------------------------------------------------------------------+
//| MTF Alert System (Smart Algorithmic Decision Engine)             |
//+------------------------------------------------------------------+
bool TriggerMTFAlert(int current_bar_i, datetime t, double live_price, int triggered_level, bool is_revisit=false)
  {

   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double h_m1, l_m1; datetime th_m1, tl_m1;
   double dmy_h, dmy_l; datetime th_m3, tl_m3, th_m5, tl_m5, th_m15, tl_m15, th_m30, tl_m30, th_h1, tl_h1;

   bool hm1 = GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, h_m1, l_m1, th_m1, tl_m1);
   bool hm3 = GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, dmy_h, dmy_l, th_m3, tl_m3);
   bool hm5 = GetMTFPullback(PERIOD_M5, t_m5, p_m5, mp_m5, t, dmy_h, dmy_l, th_m5, tl_m5);
   bool hm15 = GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, dmy_h, dmy_l, th_m15, tl_m15);
   bool hm30 = GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, dmy_h, dmy_l, th_m30, tl_m30);
   bool hh1 = GetMTFPullback(PERIOD_H1, t_h1, p_h1, mp_h1, t, dmy_h, dmy_l, th_h1, tl_h1);

   if(!hm1 || !hm3 || !hm5 || !hm15 || !hm30 || !hh1) return false;

// --- Trend Baskınlık Analizi (Trend Dominance Analysis) ---
   // Büyük Zaman Aralığı (Macro/Core: H1, M30, M15)
   int macro_score = 0;
   if(t_h1 == 1) macro_score += 5; else macro_score -= 5;
   if(t_m30 == 1) macro_score += 4; else macro_score -= 4;
   if(t_m15 == 1) macro_score += 3; else macro_score -= 3;

   double macro_bull_pct = ((macro_score + 12.0) / 24.0) * 100.0;
   double macro_bear_pct = 100.0 - macro_bull_pct;

   // Küçük Zaman Aralığı (Micro/Trigger: M5, M3, M1)
   int micro_score = 0;
   if(t_m5 == 1) micro_score += 3; else micro_score -= 3;
   if(t_m3 == 1) micro_score += 2; else micro_score -= 2;
   if(t_m1 == 1) micro_score += 1; else micro_score -= 1;

   double micro_bull_pct = ((micro_score + 6.0) / 12.0) * 100.0;
   double micro_bear_pct = 100.0 - micro_bull_pct;

   int total_score = (t_h1 * 5) + (t_m30 * 4) + (t_m15 * 3) + (t_m5 * 2) + (t_m3 * 1) + (t_m1 * 1);
   double bull_pressure = ((total_score + 16.0) / 32.0) * 100.0;
   if (bull_pressure < 0) bull_pressure = 0;
   if (bull_pressure > 100) bull_pressure = 100;

   string lvl_text = (triggered_level == 2) ? DoubleToString(InpTriggerLevel2,0) : DoubleToString(InpTriggerLevel1,0);
   string msg1 = "🚨 [" + Symbol() + "] M1 Hedef Seviyede! (BÖLÜM 1/2)\n";
   if(InpTestMode) msg1 = "🧪 [TEST MODU - " + Symbol() + "] (BÖLÜM 1/2)\n";

   if(is_revisit)
     {
      msg1 += "⚠️ DİKKAT: Fiyat hedefi sert geçmişti. Bu bir geri dönüş (Re-visit) bildirimidir!\n\n";
     }

   string swing_dir = t_m1 == 1 ? "🟢 YUKARI" : "🔴 AŞAĞI";
   datetime start_t = t_m1 == 1 ? tl_m1 : th_m1;
   string swing_start_str = TimeToString(start_t, TIME_DATE|TIME_MINUTES);
   string ago_str = GetTimeAgoString(start_t, t);

   msg1 += "📌 REFERANS SWING (M1):\n";
   msg1 += "- Yön: " + swing_dir + "\n";
   msg1 += "- Başlangıç: " + swing_start_str + "\n";
   msg1 += "  └ Süre: " + ago_str + "\n";
   msg1 += "- Swing High: " + DoubleToString(h_m1, _Digits) + "\n";
   msg1 += "- Swing Low: " + DoubleToString(l_m1, _Digits) + "\n";
   if(p_m1 == 0 && mp_m1 == 0)
     {
      string temp_dir = (t_m1 == 1) ? "SELL" : "BUY";
      msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + "\n";
      msg1 += "⚠️ DİKKAT: Trend şişkin! M1 için kısa süreli düzeltme hareketi (" + temp_dir + ") fırsatı beklenebilir.\n\n";
     }
   else if(p_m1 <= 10.0 && mp_m1 <= 10.0)
     {
      msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Trend Şişkin, Düzeltme Bekleniyor)\n\n";
     }
   else
     {
      msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Çekilme: %" + DoubleToString(p_m1, 0) + " ↑↑%" + DoubleToString(mp_m1, 0) + ")\n\n";
     }

   msg1 += "🧭 MAKRO TREND (H1/M30)\n";
   msg1 += "Durum: " + (bull_pressure >= 50 ? "🟢 YÜKSELİŞ" : "🔴 DÜŞÜŞ") + " (%" + DoubleToString(bull_pressure, 0) + " Boğa Baskısı)\n";
   msg1 += "H1:  " + (t_h1 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_h1, mp_h1, (t_h1==1?tl_h1:th_h1), t) + "\n";
   msg1 += "M30: " + (t_m30 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m30, mp_m30, (t_m30==1?tl_m30:th_m30), t) + "\n\n";

   msg1 += "🔬 DÜZELTME VE HEDEF (M15/M5)\n";
   msg1 += "M15: " + (t_m15 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m15, mp_m15, (t_m15==1?tl_m15:th_m15), t) + "\n";
   msg1 += "M5:  " + (t_m5 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m5, mp_m5, (t_m5==1?tl_m5:th_m5), t) + "\n\n";

   msg1 += "🎯 TETİK VE ONAY GRUBU (M3/M1)\n";
   msg1 += "M3:  " + (t_m3 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m3, mp_m3, (t_m3==1?tl_m3:th_m3), t) + "\n";
   msg1 += "M1:  " + (t_m1 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m1, mp_m1, (t_m1==1?tl_m1:th_m1), t) + "\n\n";

   msg1 += "📊 Baskınlık: Makro=↑%" + DoubleToString(macro_bull_pct, 0) + " ↓%" + DoubleToString(macro_bear_pct, 0) + " | Mikro=↑%" + DoubleToString(micro_bull_pct, 0) + " ↓%" + DoubleToString(micro_bear_pct, 0) + "\n";
  bool macro_bull = (t_h1 == 1 && t_m30 == 1);
   bool macro_bear = (t_h1 == -1 && t_m30 == -1);

   string decision = "";
   string detail = "";

   bool m15_pullback_down = (t_m15 == 1 && t_m5 == -1);
   bool m15_pullback_up   = (t_m15 == -1 && t_m5 == 1);

   if (macro_bull)
     {
      if (t_m15 == -1) // M15 is in a Pullback (Down) against Macro
        {
         if (p_m15 >= InpGoodPullbackPct && t_m1 == 1 && t_m3 == 1)
           {
            decision = "✅ YAPISAL UYUM: İdeal Düzeltme Tamamlandı";
            detail = "Makro trend YUKARI. M15 yapısı yeterli ucuzluk bölgesine (discount) indi. Alt zaman dilimi tetikleyicileri (M1/M3) ana trend yönüne dönüş sinyali üretiyor. Trendin devam etme ihtimali istatistiksel olarak yüksek.";
           }
         else if (t_m1 == -1 && t_m3 == -1 && p_m15 < 30.0)
           {
            decision = "⚡ YAPISAL UYUM: Derin Düzeltme Başlangıcı";
            detail = "Makro trend YUKARI olmasına rağmen, M15 yapısı aşağı yönlü kırıldı ve henüz yeterli ucuzluk bölgesine inmedi. Kısa vadeli aşağı yönlü (Counter-Trend) momentum güçlü, ancak bu hareket makro trende terstir.";
           }
         else
           {
            decision = "❌ YAPISAL UYUMSUZLUK: Düzensiz Fiyat Hareketi (Gürültü)";
            detail = "M15 aşağı yönlü düzeltme aşamasında, ancak M1 ve M3 zıt yönde veya henüz kalıcı bir dönüş yapısı oluşturmadı. Fiyatta anlamlı bir trend yönü yok, izlemek en mantıklısı.";
           }
        }
      else if (t_m15 == 1) // M15 is UP (Aligned with Macro)
        {
         if (t_m5 == -1) // M5 is pulling back down
           {
            if (p_m15 >= InpGoodPullbackPct && t_m1 == 1 && t_m3 == 1)
              {
               decision = "✅ YAPISAL UYUM: Güçlü Trend Devamı";
               detail = "M15 Yukarı yönde ve yeterli ucuzluk bölgesinde. M5 düzeltmesini bitirmek üzereyken, M1/M3 tetik grubu ana yöne uyum sağladı. Yapı yukarı yönlü genişlemeyi destekliyor.";
              }
            else
              {
               decision = "❌ YAPISAL UYUMSUZLUK: Kısa Süreli Tepki";
               detail = "M15 Yukarı ancak M5 şu an fiyatı aşağı çekiyor. M1 yukarı kırmış olsa da M3 yapısı henüz onay vermedi. Bu hareket kalıcı bir dönüş değil, iç yapı düzeltmesidir.";
              }
           }
         else // M15 UP, M5 UP
           {
            if (p_m15 <= 10.0 && p_m5 <= 10.0 && mp_m15 <= 10.0)
              {
               decision = "⚠️ RİSKLİ YAPI: Aşırı Şişkin (Overextended)";
               detail = "Ana zaman dilimlerinde (M15 ve M5) fiyat son kırılımdan bu yana hiç geri çekilme (pullback) yapmadı. Bu seviyelerden trend yönlü beklentiye girmek yapısal olarak mantıksızdır. Fiyatın dengelenmesi beklenmeli.";
              }
            else if (p_m15 <= 10.0 && p_m5 <= 10.0 && mp_m15 > 10.0)
              {
               decision = "✅ YAPISAL UYUM: Kırılım Gerçekleşiyor (Breakout)";
               detail = "M15 daha önce düzeltmesini (pullback) tamamlamış ve şu an yapısal direnci kırmak üzere ivmeleniyor. Makro ve mikro trendler tamamen aynı yönde.";
              }
            else if (t_m1 == 1 && t_m3 == 1)
              {
               decision = "✅ YAPISAL UYUM: Ara Düzeltme Devamı";
               detail = "Makro ve M15 uyumlu. Fiyat M15'te sığ bir düzeltme yaptıktan sonra tekrar yukarı kırılım sinyali veriyor. Trend ivmesi oldukça güçlü.";
              }
            else
              {
               decision = "❌ YAPISAL UYUMSUZLUK: Düzensiz Fiyat Hareketi (Gürültü)";
               detail = "Ana yön Yukarı ancak M1 ve M3 kendi içlerinde uyumsuz dalgalanıyor. Net bir yapı onayı gelene kadar işlem yapmak riskli.";
              }
           }
        }
     }
   else if (macro_bear)
     {
      if (t_m15 == 1) // M15 is in a Pullback (Up) against Macro
        {
         if (p_m15 >= InpGoodPullbackPct && t_m1 == -1 && t_m3 == -1)
           {
            decision = "✅ YAPISAL UYUM: İdeal Düzeltme Tamamlandı";
            detail = "Makro trend AŞAĞI. M15 yapısı yeterli pahalılık bölgesine (premium) ulaştı. Alt zaman dilimi tetikleyicileri (M1/M3) ana trend yönüne dönüş sinyali üretiyor. Trendin devam etme ihtimali yüksek.";
           }
         else if (t_m1 == 1 && t_m3 == 1 && p_m15 < 30.0)
           {
            decision = "⚡ YAPISAL UYUM: Derin Düzeltme Başlangıcı";
            detail = "Makro trend AŞAĞI olmasına rağmen, M15 yapısı yukarı yönlü kırıldı ve henüz pahalılık bölgesine ulaşmadı. Kısa vadeli yukarı yönlü (Counter-Trend) momentum güçlü, ancak bu makro trende terstir.";
           }
         else
           {
            decision = "❌ YAPISAL UYUMSUZLUK: Düzensiz Fiyat Hareketi (Gürültü)";
            detail = "M15 yukarı çıkıyor (düzeltme). Ancak M1 ve M3 kendi aralarında uyumsuz. Bu bir trend başlangıcı değil, fiyatın denge arayışıdır.";
           }
        }
      else if (t_m15 == -1) // M15 is DOWN (Aligned with Macro)
        {
         if (t_m5 == 1) // M5 is pulling back up
           {
            if (p_m15 >= InpGoodPullbackPct && t_m1 == -1 && t_m3 == -1)
              {
               decision = "✅ YAPISAL UYUM: Güçlü Trend Devamı";
               detail = "M15 Aşağı yönde ve pahalılık bölgesinde. M5 düzeltmesini bitirirken Tetik Grubu (M1/M3) asıl yöne uyum sağladı. Aşağı yönlü genişleme devam edebilir.";
              }
            else
              {
               decision = "❌ YAPISAL UYUMSUZLUK: Kısa Süreli Tepki";
               detail = "M15 Aşağı iniyor ancak M5 şu an fiyatı yukarı çekiyor. M1 ve M3 yapısı dönüş için yeterli onayı vermedi. Henüz asıl trende girilmiş değil.";
              }
           }
         else // M15 DOWN, M5 DOWN
           {
            if (p_m15 <= 10.0 && p_m5 <= 10.0 && mp_m15 <= 10.0)
              {
               decision = "⚠️ RİSKLİ YAPI: Aşırı Şişkin (Overextended)";
               detail = "Ana zaman dilimlerinde (M15 ve M5) fiyat son kırılımdan bu yana hiç geri çekilme (pullback) yapmadı. Bu seviyelerden ana trend yönlü beklentiye girmek yapısal olarak mantıksızdır, düzeltme beklenmeli.";
              }
            else if (p_m15 <= 10.0 && p_m5 <= 10.0 && mp_m15 > 10.0)
              {
               decision = "✅ YAPISAL UYUM: Kırılım Gerçekleşiyor (Breakout)";
               detail = "M15 daha önce düzeltmesini (pullback) tamamlamış ve şu an yapısal desteği kırmak üzere ivmeleniyor. Makro ve mikro trendler tamamen aynı yönde.";
              }
            else if (t_m1 == -1 && t_m3 == -1)
              {
               decision = "✅ YAPISAL UYUM: Ara Düzeltme Devamı";
               detail = "Makro ve M15 uyumlu. Fiyat M15'te sığ bir tepki verdikten sonra tekrar aşağı kırılım sinyali veriyor. Ayı momentumu devam ediyor.";
              }
            else
              {
               decision = "❌ YAPISAL UYUMSUZLUK: Düzensiz Fiyat Hareketi (Gürültü)";
               detail = "Ana yön Aşağı ancak M1 ve M3 kendi içlerinde uyumsuz dalgalanıyor. Piyasanın yön bulması beklenmeli.";
              }
           }
        }
     }
   else
     {
      decision = "⚠️ YAPISAL KARARSIZLIK (Range / Testere)";
      detail = "Makro trendler (H1 ve M30) birbiriyle uyumsuz durumda. Piyasa konsolidasyon (yatay) sürecinde, büyük zaman diliminde net bir yön tayini yok.";
     }

   // --- MOMENTUM REJECTION NOTU ---
   string momentum_note = "";

   if (mp_h1 >= InpMomentumMinPeak && (mp_h1 - p_h1) >= InpMomentumMinBounce) momentum_note += "  └ [H1] Zirveden %" + DoubleToString(mp_h1 - p_h1, 0) + " döndü. " + (t_h1 == 1 ? "YUKARI" : "AŞAĞI") + " ivme kazandı!\n";
   if (mp_m30 >= InpMomentumMinPeak && (mp_m30 - p_m30) >= InpMomentumMinBounce) momentum_note += "  └ [M30] Zirveden %" + DoubleToString(mp_m30 - p_m30, 0) + " döndü. " + (t_m30 == 1 ? "YUKARI" : "AŞAĞI") + " ivme kazandı!\n";
   if (mp_m15 >= InpMomentumMinPeak && (mp_m15 - p_m15) >= InpMomentumMinBounce) momentum_note += "  └ [M15] Zirveden %" + DoubleToString(mp_m15 - p_m15, 0) + " döndü. " + (t_m15 == 1 ? "YUKARI" : "AŞAĞI") + " ivme kazandı!\n";
   if (mp_m5 >= InpMomentumMinPeak && (mp_m5 - p_m5) >= InpMomentumMinBounce) momentum_note += "  └ [M5] Zirveden %" + DoubleToString(mp_m5 - p_m5, 0) + " döndü. " + (t_m5 == 1 ? "YUKARI" : "AŞAĞI") + " ivme kazandı!\n";
   if (mp_m3 >= InpMomentumMinPeak && (mp_m3 - p_m3) >= InpMomentumMinBounce) momentum_note += "  └ [M3] Zirveden %" + DoubleToString(mp_m3 - p_m3, 0) + " döndü. " + (t_m3 == 1 ? "YUKARI" : "AŞAĞI") + " ivme kazandı!\n";

   string final_momentum_str = "";
   if (momentum_note != "")
     {
      final_momentum_str = "🚀 İVME (MOMENTUM):\n" + momentum_note + "  * Fiyat düzeltmeyi sert reddetti, ana trend yönünde tepki güçlü!\n\n";
     }

   string risk_advice = "";
   if (StringFind(decision, "Aşırı Şişkin") != -1)
     {
      risk_advice = "🔴 RİSKLİ BÖLGE: Mevcut seviyeden trend yönünde beklentiye girmek yapısal olarak yanlıştır. Fiyatın sağlıklı bir düzeltme (pullback) yapması beklenmelidir.";
     }
   else if (StringFind(decision, "İdeal Düzeltme") != -1 || StringFind(decision, "Güçlü Trend") != -1)
     {
      risk_advice = "🟢 OPTİMAL BÖLGE: Zaman dilimleri tam uyum içinde. Fiyat ideal iskontoda ve trendin devam etme olasılığı çok yüksek.";
     }
   else if (StringFind(decision, "Kırılım Gerçekleşiyor") != -1 || StringFind(decision, "Ara Düzeltme") != -1)
     {
      risk_advice = "🟡 KABUL EDİLEBİLİR RİSK: Fiyat halihazırda düzeltmesini yapmış ve yapıyı kırmak üzere. Momentum yönlü hareket izlenebilir.";
     }
   else if (StringFind(decision, "Derin Düzeltme") != -1)
     {
      risk_advice = "🟠 YÜKSEK RİSK (Counter-Trend): Kısa zaman diliminde oluşan momentuma karşı işlem almak (Scalp) mümkündür ancak ana trende terstir. Düşük lot tavsiye edilir.";
     }
   else if (StringFind(decision, "Düzensiz Fiyat Hareketi") != -1 || StringFind(decision, "Kısa Süreli Tepki") != -1)
     {
      risk_advice = "🔴 UYUMSUZLUK: Yapılar birbiriyle çelişiyor. Trend henüz olgunlaşmadı veya fake-out (sahte kırılım) riski var. İzlemede kalın.";
     }
   else
     {
      risk_advice = "🔴 BEKLEME ZAMANI: Piyasa yapısında netlik yok. Yeni bir impulsif hareketin oluşumu beklenmelidir.";
     }

   string msg2 = "🚨 [" + Symbol() + "] BÖLÜM 2/2\n\n";
   if(InpTestMode) msg2 = "🧪 [TEST MODU - " + Symbol() + "] BÖLÜM 2/2\n\n";

   msg2 += final_momentum_str;
   msg2 += "🤖 PİYASA DURUMU:\n  " + decision + "\n\n";
   msg2 += "📝 YAPI ANALİZİ:\n  " + detail + "\n\n";
   msg2 += "⚠️ ALGORİTMİK SONUÇ:\n  " + risk_advice;

   if(InpAlertPopup)
     {
      Alert(msg1);
      Alert(msg2);
     }
   if(InpAlertPush)
     {
      SendNotification(msg1);
      SendNotification(msg2);
     }

   g_alert_bar_index = current_bar_i;
   return true;
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME, "Structure");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "Structure_");
   ObjectsDeleteAll(0, "Minor_");
   ObjectsDeleteAll(0, "Major_");
   ObjectsDeleteAll(0, "HLine_");
   ObjectsDeleteAll(0, "LiveLeg_");
   ObjectsDeleteAll(0, "ChochLine_");
   ObjectsDeleteAll(0, "ChochEntry_");
  }

//+------------------------------------------------------------------+
//| Main Logic Execution                                             |
//+------------------------------------------------------------------+
void ProcessBar(int i, const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], SState &state, bool is_history)
  {
   double val_h = high[i];
   double val_l = low[i];
   double val_c = close[i];

   string prefix = is_history ? "" : "Live_";

   // Current Pullback Percentage Calculation
   double pullback_pct = 0;
   if (state.maj_h != EMPTY_VALUE && state.maj_l != EMPTY_VALUE && state.maj_h != state.maj_l)
     {
      double range = state.maj_h - state.maj_l;
      if (state.maj_tr == 1) // Uptrend
        {
         if (val_c < state.maj_h && val_c > state.maj_l)
            pullback_pct = ((state.maj_h - val_c) / range) * 100.0;
         else if (val_c <= state.maj_l)
            pullback_pct = 100.0;
         else
            pullback_pct = 0.0;
        }
      else if (state.maj_tr == -1) // Downtrend
        {
         if (val_c > state.maj_l && val_c < state.maj_h)
            pullback_pct = ((val_c - state.maj_l) / range) * 100.0;
         else if (val_c >= state.maj_h)
            pullback_pct = 100.0;
         else
            pullback_pct = 0.0;
        }
     }

   bool in_zone = (pullback_pct >= InpOnayIslemYuzdeMin && pullback_pct <= InpOnayIslemYuzdeMax);
   if(!in_zone) {
      // If outside zone, reset CHoCH tracking
      state.choch_active = false;
      state.choch_last_dir = 0;
   }

   // Detect Break for CHoCH
   if (in_zone && state.st_h.Size() >= 2 && state.st_l.Size() >= 2)
     {
      if (state.maj_tr == -1) // Downtrend -> Look for Short Entry
        {
         // We need the sequence: T1, D1, T2. And then price breaking D1.
         // Since min_tr tracks current swing, let's look at history stacks.
         // st_h has tops, st_l has bottoms.
         int s_h = state.st_h.Size();
         int s_l = state.st_l.Size();

         double T2 = state.st_h.GetVal(s_h - 1);
         int T2_i = state.st_h.GetIdx(s_h - 1);
         double T1 = state.st_h.GetVal(s_h - 2);
         int T1_i = state.st_h.GetIdx(s_h - 2);

         double D1 = state.st_l.GetVal(s_l - 1);
         int D1_i = state.st_l.GetIdx(s_l - 1);

         // Sequence must be T1 -> D1 -> T2
         if (T1_i < D1_i && D1_i < T2_i)
           {
            // Price goes below D1
            if (val_l < D1 && state.choch_last_dir != -1 && state.min_tr == -1 && state.lp_i == T2_i)
              {
               bool is_strong = (T2 > T1); // T2 breaks T1 (liquidity grab)
               // Weak is T2 <= T1

               state.choch_active = true;
               state.choch_last_dir = -1;
               state.choch_t1_time = time[T1_i];
               state.choch_t1_val = T1;
               state.choch_d1_time = time[D1_i];
               state.choch_d1_val = D1;
               state.choch_t2_time = time[T2_i];
               state.choch_t2_val = T2;
               state.choch_break_time = time[i];
               state.choch_break_val = D1;
               state.choch_is_strong = is_strong;

               string c_name = GetUniqueName(prefix + "ChochLine_");
               DrawLine(c_name + "_1", state.choch_t1_time, state.choch_t1_val, state.choch_d1_time, state.choch_d1_val, clrMagenta, 2, STYLE_SOLID);
               DrawLine(c_name + "_2", state.choch_d1_time, state.choch_d1_val, state.choch_t2_time, state.choch_t2_val, clrMagenta, 2, STYLE_SOLID);
               DrawLine(c_name + "_3", state.choch_t2_time, state.choch_t2_val, state.choch_break_time, state.choch_break_val, clrMagenta, 2, STYLE_SOLID);

               string e_name = GetUniqueName(prefix + "ChochEntry_");
               DrawLine(e_name, time[D1_i], D1, time[i] + PeriodSeconds()*5, D1, clrMagenta, 2, STYLE_SOLID, false);
              }
           }
        }
      else if (state.maj_tr == 1) // Uptrend -> Look for Long Entry
        {
         int s_h = state.st_h.Size();
         int s_l = state.st_l.Size();

         double D2 = state.st_l.GetVal(s_l - 1);
         int D2_i = state.st_l.GetIdx(s_l - 1);
         double D1 = state.st_l.GetVal(s_l - 2);
         int D1_i = state.st_l.GetIdx(s_l - 2);

         double T1 = state.st_h.GetVal(s_h - 1);
         int T1_i = state.st_h.GetIdx(s_h - 1);

         // Sequence must be D1 -> T1 -> D2
         if (D1_i < T1_i && T1_i < D2_i)
           {
            // Price goes above T1
            if (val_h > T1 && state.choch_last_dir != 1 && state.min_tr == 1 && state.lp_i == D2_i)
              {
               bool is_strong = (D2 < D1); // D2 breaks D1 (liquidity grab)
               // Weak is D2 >= D1

               state.choch_active = true;
               state.choch_last_dir = 1;
               state.choch_t1_time = time[D1_i]; // Mapping D1 to t1
               state.choch_t1_val = D1;
               state.choch_d1_time = time[T1_i]; // Mapping T1 to d1
               state.choch_d1_val = T1;
               state.choch_t2_time = time[D2_i]; // Mapping D2 to t2
               state.choch_t2_val = D2;
               state.choch_break_time = time[i];
               state.choch_break_val = T1;
               state.choch_is_strong = is_strong;

               string c_name = GetUniqueName(prefix + "ChochLine_");
               DrawLine(c_name + "_1", state.choch_t1_time, state.choch_t1_val, state.choch_d1_time, state.choch_d1_val, clrMagenta, 2, STYLE_SOLID);
               DrawLine(c_name + "_2", state.choch_d1_time, state.choch_d1_val, state.choch_t2_time, state.choch_t2_val, clrMagenta, 2, STYLE_SOLID);
               DrawLine(c_name + "_3", state.choch_t2_time, state.choch_t2_val, state.choch_break_time, state.choch_break_val, clrMagenta, 2, STYLE_SOLID);

               string e_name = GetUniqueName(prefix + "ChochEntry_");
               DrawLine(e_name, time[T1_i], T1, time[i] + PeriodSeconds()*5, T1, clrMagenta, 2, STYLE_SOLID, false);
              }
           }
        }
     }

   // MINOR STRUCTURE
   if(state.min_tr == 1)
     {
      double old_trig = state.trig_l;
      if(val_h > state.min_h)
        {
         state.min_h = val_h;
         state.min_h_i = i;
         state.trig_l = val_l;
        }

      if(val_l < old_trig)
        {
         if(InpShowMin)
           {
            string name = GetUniqueName(prefix + "Minor_");
            DrawLine(name, time[state.lp_i], state.lp_p, time[state.min_h_i], state.min_h, InpColorMin, 1, STYLE_SOLID);
           }
         state.st_h.Push(state.min_h, state.min_h_i);

         if(state.maj_tr == 1 && state.maj_st == 0 && state.min_h < state.tmp_h && state.st_l.Size() > 0)
           {
            if(state.st_l.GetIdx(state.st_l.Size() - 1) > state.bos_i)
              {
               state.st_l.Pop();
              }
           }
         state.min_tr = -1;
         state.lp_i = state.min_h_i;
         state.lp_p = state.min_h;
         state.min_l = val_l;
         state.min_l_i = i;
         state.trig_h = val_h;
        }
     }
   else
     {
      double old_trig = state.trig_h;
      if(val_l < state.min_l)
        {
         state.min_l = val_l;
         state.min_l_i = i;
         state.trig_h = val_h;
        }

      if(val_h > old_trig)
        {
         if(InpShowMin)
           {
            string name = GetUniqueName(prefix + "Minor_");
            DrawLine(name, time[state.lp_i], state.lp_p, time[state.min_l_i], state.min_l, InpColorMin, 1, STYLE_SOLID);
           }
         state.st_l.Push(state.min_l, state.min_l_i);

         if(state.maj_tr == -1 && state.maj_st == 0 && state.min_l > state.tmp_l && state.st_h.Size() > 0)
           {
            if(state.st_h.GetIdx(state.st_h.Size() - 1) > state.bos_i)
              {
               state.st_h.Pop();
              }
           }
         state.min_tr = 1;
         state.lp_i = state.min_l_i;
         state.lp_p = state.min_l;
         state.min_h = val_h;
         state.min_h_i = i;
         state.trig_l = val_l;
        }
     }

   // MAJOR STRUCTURE
   if(state.maj_tr == 0)
     {
      state.maj_tr = 1;
      state.anc_i = state.min_l_i;
      state.anc_v = state.min_l;
      state.maj_l_i = state.min_l_i;
     }

   if(state.maj_tr == 1)
     {
      if(val_h > state.tmp_h)
        {
         state.tmp_h = val_h;
         state.tmp_h_i = i;
        }

      if(state.maj_st == 0)
        {
         double act = state.st_l.Size() > 0 ? state.st_l.GetVal(state.st_l.Size() - 1) : EMPTY_VALUE;
         if(act != EMPTY_VALUE && val_l < act)
           {
            state.maj_h = state.tmp_h;
            state.maj_h_i = state.tmp_h_i;
            if(InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, time[state.anc_i], state.anc_v, time[state.tmp_h_i], state.maj_h, InpColorBull, 2, STYLE_SOLID);
              }

            state.st_l.Clear();
            state.st_h.Clear();
            state.maj_st = 1;
            state.anc_i = state.tmp_h_i;
            state.anc_v = state.maj_h;
            state.tmp_l = val_l;
            state.tmp_l_i = i;

            CutLine(state.cur_top_line, time[i]);
            CutLine(state.cur_bot_line, time[i]);

            if(InpShowMaj)
              {
               state.cur_top_line = GetUniqueName(prefix + "HLine_Top_");
               DrawLine(state.cur_top_line, time[state.maj_h_i], state.maj_h, time[i] + PeriodSeconds(), state.maj_h, InpColorBull, 1, STYLE_DASH, true);

               if(state.maj_l != EMPTY_VALUE && state.maj_l != 0)
                 {
                  state.cur_bot_line = GetUniqueName(prefix + "HLine_Bot_");
                  DrawLine(state.cur_bot_line, time[state.maj_l_i], state.maj_l, time[i] + PeriodSeconds(), state.maj_l, InpColorBull, 1, STYLE_DASH, true);
                 }
              }
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l)
           {
            state.maj_l = val_l;
            if(InpShowMaj)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1;
            state.maj_st = 0;
            state.bos_i = i;
            if(InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, time[state.anc_i], state.anc_v, time[state.tmp_h_i], state.tmp_h, InpColorBull, 2, STYLE_SOLID);
              }

            state.st_l.Clear();
            state.anc_i = state.tmp_h_i;
            state.anc_v = state.tmp_h;
            state.tmp_l = val_l;
            state.tmp_l_i = i;
            state.maj_h = state.tmp_h;
            state.maj_h_i = state.tmp_h_i;

            CutLine(state.cur_top_line, time[i]);
            CutLine(state.cur_bot_line, time[i]);
            state.cur_top_line = "";
            state.cur_bot_line = "";
           }
        }
      else if(state.maj_st == 1)
        {
         if(val_l < state.tmp_l)
           {
            state.tmp_l = val_l;
            state.tmp_l_i = i;
           }

         if(val_h > state.maj_h && val_c <= state.maj_h)
           {
            state.maj_h = val_h;
            if(InpShowMaj)
               UpdateLineLevel(state.cur_top_line, state.maj_h);
           }

         if(val_c > state.maj_h)
           {
            state.bos_i = i;
            state.maj_l = state.tmp_l;
            state.maj_l_i = state.tmp_l_i;
            if(InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, time[state.anc_i], state.anc_v, time[state.tmp_l_i], state.maj_l, InpColorBull, 2, STYLE_SOLID);
              }

            state.st_h.Clear();
            state.maj_st = 0;
            state.anc_i = state.tmp_l_i;
            state.anc_v = state.maj_l;
            state.tmp_h = val_h;
            state.tmp_h_i = i;

            CutLine(state.cur_top_line, time[i]);
            CutLine(state.cur_bot_line, time[i]);
            state.cur_top_line = "";
            state.cur_bot_line = "";
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l)
           {
            state.maj_l = val_l;
            if(InpShowMaj)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1;
            state.maj_st = 0;
            state.bos_i = i;
            if(InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, time[state.anc_i], state.anc_v, time[state.tmp_h_i], state.tmp_h, InpColorBull, 2, STYLE_SOLID);
              }

            state.st_l.Clear();
            state.anc_i = state.tmp_h_i;
            state.anc_v = state.tmp_h;
            state.tmp_l = val_l;
            state.tmp_l_i = i;
            state.maj_h = state.tmp_h;
            state.maj_h_i = state.tmp_h_i;

            CutLine(state.cur_top_line, time[i]);
            CutLine(state.cur_bot_line, time[i]);
            state.cur_top_line = "";
            state.cur_bot_line = "";
           }
        }
     }
   else // maj_tr == -1
     {
      if(val_l < state.tmp_l)
        {
         state.tmp_l = val_l;
         state.tmp_l_i = i;
        }

      if(state.maj_st == 0)
        {
         double act = state.st_h.Size() > 0 ? state.st_h.GetVal(state.st_h.Size() - 1) : EMPTY_VALUE;
         if(act != EMPTY_VALUE && val_h > act)
           {
            state.maj_l = state.tmp_l;
            state.maj_l_i = state.tmp_l_i;
            if(InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, time[state.anc_i], state.anc_v, time[state.tmp_l_i], state.maj_l, InpColorBear, 2, STYLE_SOLID);
              }

            state.st_l.Clear();
            state.st_h.Clear();
            state.maj_st = 1;
            state.anc_i = state.tmp_l_i;
            state.anc_v = state.maj_l;
            state.tmp_h = val_h;
            state.tmp_h_i = i;

            CutLine(state.cur_top_line, time[i]);
            CutLine(state.cur_bot_line, time[i]);

            if(InpShowMaj)
              {
               state.cur_bot_line = GetUniqueName(prefix + "HLine_Bot_");
               DrawLine(state.cur_bot_line, time[state.maj_l_i], state.maj_l, time[i] + PeriodSeconds(), state.maj_l, InpColorBear, 1, STYLE_DASH, true);

               if(state.maj_h != EMPTY_VALUE && state.maj_h != 0)
                 {
                  state.cur_top_line = GetUniqueName(prefix + "HLine_Top_");
                  DrawLine(state.cur_top_line, time[state.maj_h_i], state.maj_h, time[i] + PeriodSeconds(), state.maj_h, InpColorBear, 1, STYLE_DASH, true);
                 }
              }
           }

         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h)
           {
            state.maj_h = val_h;
            if(InpShowMaj)
               UpdateLineLevel(state.cur_top_line, state.maj_h);
           }

         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.maj_tr = 1;
            state.maj_st = 0;
            state.bos_i = i;
            if(InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, time[state.anc_i], state.anc_v, time[state.tmp_l_i], state.tmp_l, InpColorBear, 2, STYLE_SOLID);
              }

            state.st_h.Clear();
            state.anc_i = state.tmp_l_i;
            state.anc_v = state.tmp_l;
            state.tmp_h = val_h;
            state.tmp_h_i = i;
            state.maj_l = state.tmp_l;
            state.maj_l_i = state.tmp_l_i;

            CutLine(state.cur_top_line, time[i]);
            CutLine(state.cur_bot_line, time[i]);
            state.cur_top_line = "";
            state.cur_bot_line = "";
           }
        }
      else if(state.maj_st == 1)
        {
         if(val_h > state.tmp_h)
           {
            state.tmp_h = val_h;
            state.tmp_h_i = i;
           }

         if(val_l < state.maj_l && val_c >= state.maj_l)
           {
            state.maj_l = val_l;
            if(InpShowMaj)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(val_c < state.maj_l)
           {
            state.maj_h = state.tmp_h;
            state.bos_i = i;
            state.maj_h_i = state.tmp_h_i;
            if(InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, time[state.anc_i], state.anc_v, time[state.tmp_h_i], state.maj_h, InpColorBear, 2, STYLE_SOLID);
              }

            state.st_l.Clear();
            state.maj_st = 0;
            state.anc_i = state.tmp_h_i;
            state.anc_v = state.maj_h;
            state.tmp_l = val_l;
            state.tmp_l_i = i;

            CutLine(state.cur_top_line, time[i]);
            CutLine(state.cur_bot_line, time[i]);
            state.cur_top_line = "";
            state.cur_bot_line = "";
           }

         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h)
           {
            state.maj_h = val_h;
            if(InpShowMaj)
               UpdateLineLevel(state.cur_top_line, state.maj_h);
           }

         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.maj_tr = 1;
            state.maj_st = 0;
            state.bos_i = i;

            state.st_h.Clear();
            state.anc_i = state.tmp_l_i;
            state.anc_v = state.tmp_l;
            state.tmp_h = val_h;
            state.tmp_h_i = i;
            state.maj_l = state.tmp_l;
            state.maj_l_i = state.tmp_l_i;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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

   int limit;

   if(prev_calculated == 0)
     {
      double tf_days = GetDaysForTF(Period());
      g_anchor_time = TimeCurrent() - (datetime)(tf_days * 24.0 * 60.0 * 60.0);

      g_counter = 0;
      g_last_alert_maj_h = 0;
      g_last_alert_maj_l = 0;
      g_last_alert_trend = 0;
      g_level1_triggered = false;
      g_level2_triggered = false;
      g_level1_missed = false;
      g_level2_missed = false;

      ObjectsDeleteAll(0, "Structure_");
      ObjectsDeleteAll(0, "Minor_");
      ObjectsDeleteAll(0, "Major_");
      ObjectsDeleteAll(0, "HLine_");
      ObjectsDeleteAll(0, "LiveLeg_");
      ObjectsDeleteAll(0, "ChochLine_");
      ObjectsDeleteAll(0, "ChochEntry_");

      int start_idx = 0;
      for(int k=0; k<rates_total; k++) {
         if(time[k] >= g_anchor_time) {
            start_idx = k;
            break;
         }
      }

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
      g_state_hist.min_tr  = (close[start_idx] > open[start_idx]) ? 1 : -1;
      g_state_hist.anc_i   = start_idx;
      g_state_hist.anc_v   = close[start_idx];
      g_state_hist.lp_i    = start_idx;
      g_state_hist.lp_p    = close[start_idx];

      g_state_hist.choch_active = false;
      g_state_hist.choch_last_dir = 0;

      // Başlangıçta yapının (maj) boş kalmaması için ince bir ATR aralığında yapay swing oluşturuluyor.
      double initial_atr = 0;
      double atr_arr[];
      // Optimizasyon & Hata Engelleme: start_idx dizinin sonlarına doğruysa
      // iATR 0 noktasından (anlık bar) almak yerine rates_total-start_idx posizyonundan almalıdır
      // Daha güvenli çözüm: Başlangıç barının yüksekliği (veya bir önceki bar) ATR yerine kullanılır,
      // gereksiz Handle oluşturma engellenir.
      initial_atr = (high[start_idx] - low[start_idx]);
      if(initial_atr == 0) initial_atr = Point() * 10;

      double tiny_gap = initial_atr * 0.1; // "İnce kesilmiş tırnak" kadar boşluk

      g_state_hist.maj_h = high[start_idx] + tiny_gap;
      g_state_hist.maj_l = low[start_idx] - tiny_gap;
      g_state_hist.maj_tr = g_state_hist.min_tr; // Trendi minör yöne bağla
      g_state_hist.maj_st = 1;
      g_state_hist.bos_i = start_idx;

      g_state_hist.maj_h_i = start_idx;
      g_state_hist.maj_l_i = start_idx;

      limit = start_idx + 1;
     }
   else
     {
      limit = prev_calculated - 1;
     }

   for(int i = limit; i < rates_total - 1; i++)
     {
      bool inside = (high[i] <= high[i-1]) && (low[i] >= low[i-1]);
      if(!inside)
        {
         ProcessBar(i, open, high, low, close, time, g_state_hist, true);
        }
     }

   ObjectsDeleteAll(0, "Live_");
   DeleteLine("LiveLeg");

   g_state_curr.CopyFrom(g_state_hist);

   int last_idx = rates_total - 1;
   bool inside_last = false;
   if(last_idx > 0)
     {
      inside_last = (high[last_idx] <= high[last_idx-1]) && (low[last_idx] >= low[last_idx-1]);
     }

   if(!inside_last && last_idx > 0)
     {
      ProcessBar(last_idx, open, high, low, close, time, g_state_curr, false);
     }

   if(InpShowMin)
     {
      int leg_i;
      double leg_p;
      if(g_state_curr.min_tr == 1)
        {
         leg_i = g_state_curr.min_h_i;
         leg_p = g_state_curr.min_h;
        }
      else
        {
         leg_i = g_state_curr.min_l_i;
         leg_p = g_state_curr.min_l;
        }
      DrawLine("LiveLeg", time[g_state_curr.lp_i], g_state_curr.lp_p, time[leg_i], leg_p, InpColorMin, 1, STYLE_DOT);
     }

   if(last_idx > 0 && (Period() == PERIOD_M1 || InpTestMode))
     {
      int live_trend = 0;
      double live_pct = 0.0;
      double dmy_h, dmy_l; datetime dmy_th, dmy_tl;
      double dmy_mpct;
      if (GetMTFPullback(PERIOD_M1, live_trend, live_pct, dmy_mpct, time[last_idx], dmy_h, dmy_l, dmy_th, dmy_tl))
        {
         // Reset triggers if swing changed (only when fully confirmed by a bar close / definitive state update)
         // Kullanıcının Spam ve Kapanış talebi: "swing çizgisinin üstünde altında BİR KERE KAPANIŞ OLUR 1 kere atar"
         // Anlık iğnelerde (tick) spam atmasını engellemek için kapanışı bekliyoruz (inside_last == false) veya
         // sadece bar kapandığında state güncellendiği için geçmiş history tablosunu (g_state_hist) referans alıyoruz.

         if (g_state_hist.maj_h != g_last_alert_maj_h ||
             g_state_hist.maj_l != g_last_alert_maj_l ||
             g_state_hist.maj_tr != g_last_alert_trend)
           {
            // g_state_hist kapanışta işlendiği için burada kırılım onaylıdır. Oyalanma anındaki iğneler tetiklemez.
            if (g_last_alert_trend != 0 && g_state_hist.maj_tr != g_last_alert_trend)
              {
               string new_dir = (g_state_hist.maj_tr == 1) ? "YUKARI" : "AŞAĞI";
               string trend_msg = "🚨 [" + Symbol() + "] M1 Trend Döndü! Yeni Yön: " + new_dir;
               if(InpAlertPopup) Alert(trend_msg);
               if(InpAlertPush)  SendNotification(trend_msg);
              }
            g_level1_triggered = false;
            g_level2_triggered = false;
            g_level1_missed = false;
            g_level2_missed = false;
            g_last_alert_maj_h = g_state_hist.maj_h;
            g_last_alert_maj_l = g_state_hist.maj_l;
            g_last_alert_trend = g_state_hist.maj_tr;
           }

         bool trig1 = false;
         bool trig2 = false;
         bool is_revisit_1 = false;
         bool is_revisit_2 = false;

         // "100'e gelince bildirim atıyor onu kökten çöz"
         // live_pct >= 98.0 demek artık trendin sınırında olması demektir. Bu durumda %100 veya %99 pull back
         // spam bildirim atmamalı. Çünkü bu an kırılımdır ve "Trend Döndü!" mesajı atılmalıdır.
         if(live_pct < 98.0)
           {
            // Fiyatın hedeften (örn 40) çok uzakta (örn 88) olması durumunda sahte "40" bildirimini engellemek için,
            // tetiklenme şartını (live_pct) hedefe olan belli bir toleransla sınırlandırıyoruz.
            // Toleransı (örneğin hedef + 10 puan) yapıyoruz ki hem çok hızlı geçen/atlayan barlarda bildirimi yakalayabilsin
            // hem de sertçe 88'e çıkan bir fiyat, geri çekilip 40'a geldiğinde hakkı yanmadığı için (g_level_triggered=true yapmadık)
            // tekrar kesinlikle bildirim atabilsin.

            // Eğer fiyat tolerans bandını çoktan geçmişse (örn: 80'deyse) ve bildirim atmadıysa "missed" bayrağı kalkar.
            if(live_pct > InpTriggerLevel1 + 10.0 && !g_level1_triggered) g_level1_missed = true;
            if(live_pct > InpTriggerLevel2 + 10.0 && !g_level2_triggered) g_level2_missed = true;

            if (InpNotificationFilter)
              {
               trig1 = (live_pct >= InpTriggerLevel1 && live_pct < InpTriggerLevel2 && !g_level1_triggered);
               trig2 = (live_pct >= InpTriggerLevel2 && live_pct < 100.0 && !g_level2_triggered);
              }
            else
              {
               trig1 = (live_pct >= InpTriggerLevel1 && live_pct <= InpTriggerLevel1 + 10.0 && !g_level1_triggered);
               trig2 = (live_pct >= InpTriggerLevel2 && live_pct <= InpTriggerLevel2 + 10.0 && !g_level2_triggered);
              }

            if(trig1 && g_level1_missed) is_revisit_1 = true;
            if(trig2 && g_level2_missed) is_revisit_2 = true;
           }

         if(trig1 || trig2 || InpTestMode)
           {
            int trigger_lvl = trig2 ? 2 : 1;
            bool is_revisit = (trigger_lvl == 2) ? is_revisit_2 : is_revisit_1;
            bool success = TriggerMTFAlert(last_idx, time[last_idx], close[last_idx], trigger_lvl, is_revisit);
            if(success && !InpTestMode) {
               if(trig1) { g_level1_triggered = true; g_level1_missed = false; }
               if(trig2) { g_level2_triggered = true; g_level2_missed = false; }
            }
           }
        }
     }

   return(rates_total);
  }