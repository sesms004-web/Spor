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

//--- CHoCH Settings ---
input double InpMinPullbackPct = 40.0;           // CHoCH Min Çekilme % (Onay Yüzdeliği)
input double InpMaxPullbackPct = 100.0;          // CHoCH Max Çekilme % (İşlem Yüzdeliği)
input color  InpColorChochStrong = clrPurple;      // Güçlü CHoCH (Mor)
input color  InpColorChochWeak   = clrRed;         // Güçsuz CHoCH (Kırmızı)
input color  InpColorChochPath   = clrGray;        // Yapı İzi (Gri)
input bool   InpShowChoch      = true;           // CHoCH Çizgilerini Göster

//--- İşlem Skoru & Filtre Ayarları ---
input double InpM5MinPullback    = 50.0;         // M5 Mikro Filtre Min Çekilme (%)

//--- Visual Options ---
input bool   InpShowMin = true;
input bool   InpShowMaj = true;
input color  InpColorMin = clrRed;
input color  InpColorBull = clrGreen;
input color  InpColorBear = clrRed;

//--- Alert Settings ---
input bool   InpEnableAlertTrendChange = true;       // Ana Trend (Kapanış) Dönüş Bildirimini Aç
input bool   InpEnableAlertMTFLevels   = true;       // %40/%60 MTF Analiz Bildirimini Aç (Bölüm 1/2)
input bool   InpEnableAlertCHoCHBase   = true;       // Temel CHoCH (Kırılım) Bildirimini Aç
input bool   InpEnableTradeExecution   = true;       // 50 Skorlık 'İşleme Gir' Analiz Sistemini Aç
input bool   InpTestTradeExecution     = false;      // 🧪 [TEST] Anlık Skorları Hesapla ve Bildir
input double InpTriggerLevel1    = 40.0;             // 1. Bildirim Çekilme % (örn. %40)
input double InpTriggerLevel2    = 60.0;             // 2. Bildirim Çekilme % (örn. %60)
input double InpGoodPullbackPct  = 40.0;
input double InpMomentumMinPeak  = 30.0;
input double InpMomentumMinBounce= 20.0;
input bool   InpAlertPopup       = true;
input bool   InpAlertPush        = false;
input bool   InpNotificationFilter = false;          // Bildirim Filtresi (True: Sadece Swing İçi, False: Kırılımdan İtibaren)
input bool   InpTestMode         = false;

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
      ArrayResize(m_vals, ArraySize(source.m_vals));
      ArrayResize(m_idx, ArraySize(source.m_idx));
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

   // Mother Bar Tracking
   double            mb_h;
   double            mb_l;
   int               mb_i;

   // CHoCH Tracking
   double            t1_h;
   double            t1_l;
   int               t1_i;
   double            d1_h;
   double            d1_l;
   int               d1_i;
   double            t2_h;
   double            t2_l;
   int               t2_i;
   int               choch_dir; // 1 = Bullish, -1 = Bearish, 0 = None

   CStack            st_h;
   CStack            st_l;

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

      st_h.CopyFrom(source.st_h);
      st_l.CopyFrom(source.st_l);
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

double FindTrueHigh(const double &high[], int start_idx, int end_idx)
  {
   if(start_idx < 0 || end_idx >= ArraySize(high) || start_idx > end_idx) return EMPTY_VALUE;
   double max_val = high[start_idx];
   for(int i = start_idx; i <= end_idx; i++)
     {
      if(high[i] > max_val) max_val = high[i];
     }
   return max_val;
  }

double FindTrueLow(const double &low[], int start_idx, int end_idx)
  {
   if(start_idx < 0 || end_idx >= ArraySize(low) || start_idx > end_idx) return EMPTY_VALUE;
   double min_val = low[start_idx];
   for(int i = start_idx; i <= end_idx; i++)
     {
      if(low[i] < min_val) min_val = low[i];
     }
   return min_val;
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

   // Fetch dynamic timeframe settings to individually align each timeframe with user inputs.
   double tf_days = GetDaysForTF(tf);
   datetime anchor_time = current_time - (datetime)(tf_days * 24.0 * 60.0 * 60.0);
   int copied = CopyRates(Symbol(), tf, anchor_time, current_time, rates);
   if(copied < 2) return false;

   double open[], high[], low[], close[];
   datetime time[];
   ArrayResize(open, copied);
   ArrayResize(high, copied);
   ArrayResize(low, copied);
   ArrayResize(close, copied);
   ArrayResize(time, copied);

   for(int i=0; i<copied; i++)
     {
      open[i] = rates[i].open;
      high[i] = rates[i].high;
      low[i]  = rates[i].low;
      close[i] = rates[i].close;
      time[i] = rates[i].time;
     }

   SState st;
   st.min_h   = high[0]; st.min_h_i = 0; st.min_l   = low[0]; st.min_l_i = 0;
   st.trig_h  = high[0]; st.trig_l  = low[0];
   st.tmp_h   = high[0]; st.tmp_h_i = 0; st.tmp_l   = low[0]; st.tmp_l_i = 0;
   st.min_tr  = (close[0] > open[0]) ? 1 : -1;

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

   st.mb_h = high[0];
   st.mb_l = low[0];
   st.mb_i = 0;

   for(int i = 1; i < copied; i++)
     {
      bool inside = (high[i] <= st.mb_h) && (low[i] >= st.mb_l);
      if(!inside)
        {
         // Dışarı çıktı, yeni mother bar olabilir
         if (high[i] > st.mb_h || low[i] < st.mb_l) {
            st.mb_h = high[i];
            st.mb_l = low[i];
            st.mb_i = i;
         }
         if(i == copied - 1)
           {
            double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            close[i] = bid;
            if(bid > high[i]) high[i] = bid;
            if(bid < low[i]) low[i] = bid;
           }

         ProcessBar(i, open, high, low, close, time, st, true, false); // false = do not draw UI
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
      if(trend == 1)
        {
         // Find the true peak since the origin (maj_l_i) to current bar
         double true_peak = FindTrueHigh(high, st.maj_l_i, copied - 1);
         // Find the deepest pullback from that true peak to current bar
         int peak_idx = copied - 1;
         for(int i = st.maj_l_i; i < copied; i++) { if(high[i] == true_peak) { peak_idx = i; break; } }
         double true_bottom = FindTrueLow(low, peak_idx, copied - 1);

         double range = true_peak - st.maj_l;
         if (range > 0)
           {
            pct = ((true_peak - live_p) / range) * 100.0;
            max_pct = ((true_peak - true_bottom) / range) * 100.0;
           }
         if(live_p >= true_peak) pct = 0;
        }
      else if(trend == -1)
        {
         // Find the true bottom since the origin (maj_h_i) to current bar
         double true_bottom = FindTrueLow(low, st.maj_h_i, copied - 1);
         // Find the highest pullback from that true bottom to current bar
         int bot_idx = copied - 1;
         for(int i = st.maj_h_i; i < copied; i++) { if(low[i] == true_bottom) { bot_idx = i; break; } }
         double true_peak = FindTrueHigh(high, bot_idx, copied - 1);

         double range = st.maj_h - true_bottom;
         if (range > 0)
           {
            pct = ((live_p - true_bottom) / range) * 100.0;
            max_pct = ((true_peak - true_bottom) / range) * 100.0;
           }
         if(live_p <= true_bottom) pct = 0;
        }
     }

   if(pct < 0) pct = 0;
   if(max_pct < pct) max_pct = pct;

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
   string base_str = "(Çekilme: %" + DoubleToString(pct, 2) + " ↑↑%" + DoubleToString(max_pct, 2);

   if(pct == 0.0) return base_str + " - Kırılım Gerçekleşti / Trend Devam)" + age;

   if(pct <= 10.0)
     {
      if(max_pct <= 10.0) return " (Trend Şişkin, Düzeltme Bekleniyor)" + age;
      else if(max_pct == pct) return base_str + " - Yeni Dalga Oluşuyor)" + age;
      else return base_str + " - Kırılıma Hazırlanıyor)" + age;
     }

   if(pct >= InpGoodPullbackPct && pct <= 75.0) return base_str + " - İdeal Düzeltme)" + age;
   if(pct > 85.0) return base_str + " - Dönüş Riski)" + age;

   return base_str + ")" + age;
  }

//+------------------------------------------------------------------+
//| 50-Point Execution Analysis Engine                               |
//+------------------------------------------------------------------+
void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, bool is_test = false)
  {
   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double h_m5, l_m5, h_m15, l_m15, h_m30, l_m30, h_h1, l_h1;
   double temp_h_val, temp_l_val; datetime temp_th_val, temp_tl_val, th_m5, tl_m5, th_m15, tl_m15, th_m30, tl_m30, th_h1, tl_h1;

   // We need MTF data to evaluate the matrix
   GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, temp_h_val, temp_l_val, temp_th_val, temp_tl_val);
   GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, temp_h_val, temp_l_val, temp_th_val, temp_tl_val);
   GetMTFPullback(PERIOD_M5, t_m5, p_m5, mp_m5, t, h_m5, l_m5, th_m5, tl_m5);
   GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, h_m15, l_m15, th_m15, tl_m15);
   GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, h_m30, l_m30, th_m30, tl_m30);
   GetMTFPullback(PERIOD_H1, t_h1, p_h1, mp_h1, t, h_h1, l_h1, th_h1, tl_h1);

   // Override the triggered timeframe's direction safely (because during a CHoCH bar,
   // the history scan might still read the old trend if the bar hasn't closed)
   if (trigger_dir != 0) {
       if(Period() == PERIOD_M1) { t_m1 = trigger_dir; p_m1 = p_pct; }
       if(Period() == PERIOD_M3) { t_m3 = trigger_dir; p_m3 = p_pct; }
       if(Period() == PERIOD_M5) { t_m5 = trigger_dir; p_m5 = p_pct; }
       if(Period() == PERIOD_M15) { t_m15 = trigger_dir; p_m15 = p_pct; }
       if(Period() == PERIOD_M30) { t_m30 = trigger_dir; p_m30 = p_pct; }
       if(Period() == PERIOD_H1) { t_h1 = trigger_dir; p_h1 = p_pct; }
   }

   int total_points = 0;
   string h1_text = "";
   string m30_text = "";
   string m15_text = "";
   string m5_text = "";
   string m1_text = "";

   // --- M1 BASE SETUP ---
   int m1_points = is_strong ? 5 : 0;
   total_points += m1_points;
   if(is_strong) m1_text = "Durum: 🔥 GÜÇLÜ (Likidite Alındı) -> [+5 Skor]\n";
   else          m1_text = "Durum: ⚠️ ZAYIF (Likidite Alınamadı) -> [+0 Skor]\n";

   // --- H1 MACRO LOGIC ---
   int h1_points = 0;
   bool h1_momentum = ((mp_h1 - p_h1) >= 20.0);
   bool is_h1_aligned = (t_h1 == trigger_dir);

   string stats_h1 = "[Maks Çekilme: %" + DoubleToString(mp_h1, 2) + " | Anlık: %" + DoubleToString(p_h1, 2) + "] ";

   if (h1_momentum) {
       if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "Sert Dönüş (İvme) -> [+30 Skor]\n"; }
       else               { h1_points = 0;  h1_text = "H1: " + stats_h1 + "Ters İvme (Tehlike) -> [0 Skor]\n"; }
   } else {
       if (p_h1 >= 50.0) { // Premium
           if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "İdeal Bölge (Altın Vuruş) -> [+30 Skor]\n"; }
           else               { h1_points = 0;  h1_text = "H1: " + stats_h1 + "İdeal Bölgede ama Ters Yön (Riskli!) -> [0 Skor]\n"; }
       } else if (mp_h1 >= 10.0) { // 10% Pullback Trade Opportunity
           if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "Erken Çekilme (%10) Onayı -> [+30 Skor]\n"; }
           else               { h1_points = 30; h1_text = "H1: " + stats_h1 + "Yeni Düzeltme (Önü Açık) -> [+30 Skor]\n"; }
       } else { // Shallow
           if (is_h1_aligned) { h1_points = 0;  h1_text = "H1: " + stats_h1 + "Yetersiz Çekilme (<%10) -> [0 Skor]\n"; }
           else               { h1_points = 0;  h1_text = "H1: " + stats_h1 + "Yetersiz Çekilme (<%10) -> [0 Skor]\n"; }
       }
   }
   total_points += h1_points;

   // --- M30 MODIFIER LOGIC (De-duplication) ---
   int m30_points = 0;
   bool m30_momentum = ((mp_m30 - p_m30) >= 20.0);
   bool is_m30_aligned = (t_m30 == trigger_dir);
   bool is_m30_duplicate = (MathAbs(h_m30 - h_h1) < Point() * 5 && MathAbs(l_m30 - l_h1) < Point() * 5);

   string stats_m30 = "[Maks Çekilme: %" + DoubleToString(mp_m30, 2) + " | Anlık: %" + DoubleToString(p_m30, 2) + "] ";

   if (is_m30_duplicate) {
       m30_points = 0; m30_text = "M30: " + stats_m30 + "H1 ile aynı dalga -> [0 Skor]\n";
   } else {
       if (m30_momentum) {
           if (is_m30_aligned) { m30_points = 15; m30_text = "M30: " + stats_m30 + "Sert İvme (Onay) -> [+15 Skor]\n"; }
           else                { m30_points = -5; m30_text = "M30: " + stats_m30 + "Ters İvme (Tehlike) -> [-5 Skor]\n"; }
       } else {
           if (p_m30 >= 50.0) {
               if (is_m30_aligned) { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Şişkin Bölgede Destek -> [+10 Skor]\n"; }
               else                { m30_points = -10; m30_text = "M30: " + stats_m30 + "Şişkin Bölgede Direnç -> [-10 Skor]\n"; }
           } else {
               if (is_m30_aligned) { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Yolun Başında Destek -> [+10 Skor]\n"; }
               else                { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Sağlıklı Düzeltme -> [+10 Skor]\n"; }
           }
       }
   }
   total_points += m30_points;

   // --- M15 MODIFIER LOGIC (De-duplication) ---
   int m15_points = 0;
   bool m15_momentum = ((mp_m15 - p_m15) >= 20.0);
   bool is_m15_aligned = (t_m15 == trigger_dir);
   bool is_m15_duplicate = (MathAbs(h_m15 - h_m30) < Point() * 5 && MathAbs(l_m15 - l_m30) < Point() * 5);

   string stats_m15 = "[Maks Çekilme: %" + DoubleToString(mp_m15, 2) + " | Anlık: %" + DoubleToString(p_m15, 2) + "] ";

   if (is_m15_duplicate) {
       m15_points = 0; m15_text = "M15: " + stats_m15 + "M30 ile aynı dalga -> [0 Skor]\n";
   } else {
       if (m15_momentum) {
           if (is_m15_aligned) { m15_points = 10; m15_text = "M15: " + stats_m15 + "Sert İvme (Onay) -> [+10 Skor]\n"; }
           else                { m15_points = 0;  m15_text = "M15: " + stats_m15 + "Ters İvme (Zayıf Etki) -> [0 Skor]\n"; }
       } else {
           if (p_m15 >= 50.0) {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Şişkin Bölgede Destek -> [+5 Skor]\n"; }
               else                { m15_points = -5; m15_text = "M15: " + stats_m15 + "Şişkin Bölgede Direnç -> [-5 Skor]\n"; }
           } else {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Yolun Başında Destek -> [+5 Skor]\n"; }
               else                { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Sağlıklı Düzeltme -> [+5 Skor]\n"; }
           }
       }
   }
   total_points += m15_points;

   // --- M5 MODIFIER LOGIC (De-duplication) ---
   int m5_points = 0;
   bool m5_momentum = ((mp_m5 - p_m5) >= 20.0);
   bool is_m5_aligned = (t_m5 == trigger_dir);
   bool is_m5_deep = (mp_m5 >= InpM5MinPullback);
   bool is_m5_duplicate = (MathAbs(h_m5 - h_m15) < Point() * 5 && MathAbs(l_m5 - l_m15) < Point() * 5);

   string stats_m5 = "[Maks Çekilme: %" + DoubleToString(mp_m5, 2) + " | Anlık: %" + DoubleToString(p_m5, 2) + "] ";

   if (is_m5_duplicate) {
       m5_points = 0; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "M15 ile aynı dalga -> [0 Skor]\n";
   } else {
       if (m5_momentum) {
           if (is_m5_aligned) {
               if (is_m5_deep) {
                   m5_points = 15; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Derin Çekilme + Sert İvme -> [+15 Skor]\n";
               } else {
                   m5_points = 10; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Sert İvme (Onay) -> [+10 Skor]\n";
               }
           }
           else {
               m5_points = 0; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Ters İvme (Zayıf Etki) -> [0 Skor]\n";
           }
       } else {
           if (is_m5_aligned && is_m5_deep) {
               m5_points = 5; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Derin Çekilme Onayı -> [+5 Skor]\n";
           } else {
               m5_points = 0; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Çekilme Onayı Yok -> [0 Skor]\n";
           }
       }
   }
   total_points += m5_points;

   // --- M1 vs M3 RANGE EXPECTATION ---
   string range_text = (t_m1 == t_m3) ? "🚀 BEKLENTİ: UZUN MENZİL (Trend Takibi)" : "⚠️ BEKLENTİ: KISA SÜRECEK (Scalp/Tepki)";

   // --- BREAKOUT LEVEL PHASING ---
   string lvl_text = "BİLİNMİYOR";
   if (p_pct >= 40.0 && p_pct < 60.0) lvl_text = "KIRILIM 1 (Erken Seviye)";
   if (p_pct >= 60.0) lvl_text = "KIRILIM 2 (Ana Seviye)";

   // --- FINAL VERDICT ---
   string verdict = "";
   if (total_points >= 50) verdict = "✅ İŞLEME GİRİLEBİLİR (Yüksek Olasılıklı Kurulum)";
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Skor Yetersiz)";

   string dir_str = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";

   string msg = "";
   if (is_test) msg = "🧪 [" + Symbol() + "] TEST ANALİZ RAPORU (Şu Anki Durum)\n";
   else msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\n";
   msg += "Yön: " + dir_str + "\n\n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\n" + m1_text + "\n";
   msg += "📊 ZAMAN DİLİMİ ANALİZİ (Ana Yön H1: " + (t_h1==1?"⬆️":"⬇️") + "):\n";
   msg += "* " + h1_text;
   msg += "* " + m30_text;
   msg += "* " + m15_text;
   msg += "* " + m5_text + "\n";
   msg += "🎯 İŞLEM MENZİLİ (M1 ve M3 Uyumu):\n" + range_text + "\n\n";
   msg += "📈 TOPLAM İŞLEM SKORU:\n";
   msg += "Hesaplanan: " + IntegerToString(total_points) + " Skor (Gerekli Baraj: 50 Skor)\n";
   msg += "KARAR: " + verdict;

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush) SendNotification(msg);
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
   double temp_h_val, temp_l_val; datetime th_m3, tl_m3, th_m5, tl_m5, th_m15, tl_m15, th_m30, tl_m30, th_h1, tl_h1;

   bool hm1 = GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, h_m1, l_m1, th_m1, tl_m1);
   bool hm3 = GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, temp_h_val, temp_l_val, th_m3, tl_m3);
   bool hm5  = GetMTFPullback(PERIOD_M5, t_m5, p_m5, mp_m5, t, temp_h_val, temp_l_val, th_m5, tl_m5);
   bool hm15 = GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, temp_h_val, temp_l_val, th_m15, tl_m15);
   bool hm30 = GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, temp_h_val, temp_l_val, th_m30, tl_m30);
   bool hh1  = GetMTFPullback(PERIOD_H1, t_h1, p_h1, mp_h1, t, temp_h_val, temp_l_val, th_h1, tl_h1);

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
   string msg1 = "🚨 [" + Symbol() + "] M1 Hedef (%" + lvl_text + ") Seviyesinde! (BÖLÜM 1/2)\n";
   if(InpTestMode) msg1 = "🧪 [TEST MODU - " + Symbol() + "] M1 Hedef (%" + lvl_text + ") Seviyesinde! (BÖLÜM 1/2)\n";

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
   if(p_m1 == 0.0)
     {
      msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Kırılım Gerçekleşti)\n\n";
     }
   else if(p_m1 <= 10.0)
     {
      if(mp_m1 <= 10.0) msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Trend Şişkin, Düzeltme Bekleniyor)\n\n";
      else if(mp_m1 == p_m1) msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Yeni Dalga Oluşuyor)\n\n";
      else msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Kırılıma Hazırlanıyor)\n\n";
     }
   else
     {
      msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Maks. Çekilme: %" + DoubleToString(mp_m1, 2) + " | Anlık Uzaklık: %" + DoubleToString(p_m1, 2) + ")\n\n";
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

   if (mp_h1 >= InpMomentumMinPeak && (mp_h1 - p_h1) >= InpMomentumMinBounce) momentum_note += "  └ [H1] Zirveden %" + DoubleToString(mp_h1 - p_h1, 1) + " döndü. " + (t_h1 == 1 ? "YUKARI" : "AŞAĞI") + " ivme kazandı!\n";
   if (mp_m30 >= InpMomentumMinPeak && (mp_m30 - p_m30) >= InpMomentumMinBounce) momentum_note += "  └ [M30] Zirveden %" + DoubleToString(mp_m30 - p_m30, 1) + " döndü. " + (t_m30 == 1 ? "YUKARI" : "AŞAĞI") + " ivme kazandı!\n";
   if (mp_m15 >= InpMomentumMinPeak && (mp_m15 - p_m15) >= InpMomentumMinBounce) momentum_note += "  └ [M15] Zirveden %" + DoubleToString(mp_m15 - p_m15, 1) + " döndü. " + (t_m15 == 1 ? "YUKARI" : "AŞAĞI") + " ivme kazandı!\n";
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
   ObjectsDeleteAll(0, "CHoCH_Bear_");
   ObjectsDeleteAll(0, "CHoCH_Bull_");
   ObjectsDeleteAll(0, "CHoCH_Path_");
   ObjectsDeleteAll(0, "CHoCH_Signal_");
  }

//+------------------------------------------------------------------+
//| Main Logic Execution                                             |
//+------------------------------------------------------------------+
void ProcessBar(int i, const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], SState &state, bool is_history, bool draw_ui = true)
  {
   double val_h = high[i];
   double val_l = low[i];
   double val_c = close[i];

   string prefix = is_history ? "" : "Live_";

   // CHoCH & T1-D1-T2 TRACKING LOGIC
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
         if(InpShowMin && draw_ui)
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

         // CHoCH Invalidation (Making a High)
         if (state.choch_dir == -1 && state.t2_h != 0) {
             // T1, D1, T2 formed. Making ANOTHER High means Leg 3 failed to break D1. Reset.
             state.choch_dir = 0;
         }
         if (state.choch_dir == 1 && state.t2_l != 0 && state.min_h <= state.d1_h) {
             // Bullish: T1, D1, T2 formed. Making a High that is <= D1 means failure to break. Reset.
             state.choch_dir = 0;
         }

         // CHoCH Sequence Abort Rule (Out of Pullback Zone)
         if (state.choch_dir != 0 && !in_pullback_zone) {
             state.choch_dir = 0; // Left the authorized zone entirely ([InpMinPullbackPct, InpMaxPullbackPct])
         }

         // CHoCH Bearish sequence tracking
         if (state.maj_tr == -1 && in_pullback_zone) {
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
         if(InpShowMin && draw_ui)
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

         // CHoCH Invalidation (Making a Low)
         if (state.choch_dir == 1 && state.t2_l != 0) {
             // T1, D1, T2 formed. Making ANOTHER Low means Leg 3 failed to break D1. Reset.
             state.choch_dir = 0;
         }
         if (state.choch_dir == -1 && state.t2_h != 0 && state.min_l >= state.d1_l) {
             // Bearish: T1, D1, T2 formed. Making a Low that is >= D1 means failure to break. Reset.
             state.choch_dir = 0;
         }

         // CHoCH Bullish sequence tracking
         if (state.maj_tr == 1 && in_pullback_zone) {
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
         }

         state.min_tr = 1;
         state.lp_i = state.min_l_i;
         state.lp_p = state.min_l;
         state.min_h = val_h;
         state.min_h_i = i;
         state.trig_l = val_l;
        }
     }

   // CHoCH Trigger & Drawing Logic
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {
      if (val_c < state.d1_l && in_pullback_zone) {
          // Bearish CHoCH confirmed!
          double ext_pct = 0;
          double break_pct = 0;
          if (state.maj_h != EMPTY_VALUE && state.maj_l != EMPTY_VALUE && state.maj_h != state.maj_l) {
              double range = state.maj_h - state.maj_l;
              double extreme_pt = FindTrueHigh(high, state.maj_h_i < state.maj_l_i ? state.maj_l_i : state.maj_h_i, i);
              if(extreme_pt == EMPTY_VALUE) extreme_pt = (state.t2_h > state.t1_h) ? MathMax(state.t1_h, state.t2_h) : state.t1_h;

              if (state.maj_tr == 1) { // Up Trend Top Reversal
                  ext_pct = ((extreme_pt - state.maj_l) / range) * 100.0;
                  break_pct = ((state.maj_h - val_c) / range) * 100.0;
              } else { // Down Trend Pullback Continuation
                  ext_pct = ((extreme_pt - state.maj_l) / range) * 100.0;
                  break_pct = ((val_c - state.maj_l) / range) * 100.0;
              }
          }

          bool is_strong = (state.t2_h > state.t1_h); // T2 sweeps T1's high

          if (!is_history) {
              string msg = "🔴 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)\n";
              msg += "Yön: ⬇️ AŞAĞI\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.\n";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.\n";
              }

              msg += "Çekilme: %" + DoubleToString(ext_pct, 2) + " (Kırılım: %" + DoubleToString(break_pct, 2) + ")\n";

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {
                  if (InpEnableAlertCHoCHBase && draw_ui) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution && draw_ui) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, ext_pct, is_strong);
                  }
                  last_alert_d1_i_bear = state.d1_i;
              }
          }

          if (InpShowChoch && draw_ui) {
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
      if (val_c > state.d1_h && in_pullback_zone) {
          // Bullish CHoCH confirmed!
          double ext_pct = 0;
          double break_pct = 0;
          if (state.maj_h != EMPTY_VALUE && state.maj_l != EMPTY_VALUE && state.maj_h != state.maj_l) {
              double range = state.maj_h - state.maj_l;
              double extreme_pt = FindTrueLow(low, state.maj_h_i < state.maj_l_i ? state.maj_l_i : state.maj_h_i, i);
              if(extreme_pt == EMPTY_VALUE) extreme_pt = (state.t2_l < state.t1_l) ? MathMin(state.t1_l, state.t2_l) : state.t1_l;

              if (state.maj_tr == 1) { // Up Trend Pullback Continuation
                  ext_pct = ((state.maj_h - extreme_pt) / range) * 100.0;
                  break_pct = ((state.maj_h - val_c) / range) * 100.0;
              } else { // Down Trend Bottom Reversal
                  ext_pct = ((state.maj_h - extreme_pt) / range) * 100.0;
                  break_pct = ((val_c - state.maj_l) / range) * 100.0;
              }
          }

          bool is_strong = (state.t2_l < state.t1_l); // T2 sweeps T1's low

          if (!is_history) {
              string msg = "🟢 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)\n";
              msg += "Yön: ⬆️ YUKARI\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.\n";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.\n";
              }

              msg += "Çekilme: %" + DoubleToString(ext_pct, 2) + " (Kırılım: %" + DoubleToString(break_pct, 2) + ")\n";

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {
                  if (InpEnableAlertCHoCHBase && draw_ui) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution && draw_ui) {
                      EvaluateTradeSignal(i, time[i], val_c, 1, ext_pct, is_strong);
                  }
                  last_alert_d1_i_bull = state.d1_i;
              }
          }

          if (InpShowChoch && draw_ui) {
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
            if(InpShowMaj && draw_ui)
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

            if(InpShowMaj && draw_ui)
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
            if(InpShowMaj && draw_ui)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1;
            state.maj_st = 0;
            state.bos_i = i;
            if(InpShowMaj && draw_ui)
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
            if(InpShowMaj && draw_ui)
               UpdateLineLevel(state.cur_top_line, state.maj_h);
           }

         if(val_c > state.maj_h)
           {
            state.bos_i = i;
            state.maj_l = state.tmp_l;
            state.maj_l_i = state.tmp_l_i;
            if(InpShowMaj && draw_ui)
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
            if(InpShowMaj && draw_ui)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1;
            state.maj_st = 0;
            state.bos_i = i;
            if(InpShowMaj && draw_ui)
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
            if(InpShowMaj && draw_ui)
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

            if(InpShowMaj && draw_ui)
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
            if(InpShowMaj && draw_ui)
               UpdateLineLevel(state.cur_top_line, state.maj_h);
           }

         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.maj_tr = 1;
            state.maj_st = 0;
            state.bos_i = i;
            if(InpShowMaj && draw_ui)
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
            if(InpShowMaj && draw_ui)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(val_c < state.maj_l)
           {
            state.maj_h = state.tmp_h;
            state.bos_i = i;
            state.maj_h_i = state.tmp_h_i;
            if(InpShowMaj && draw_ui)
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
            if(InpShowMaj && draw_ui)
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
      ObjectsDeleteAll(0, "CHoCH_Bear_");
      ObjectsDeleteAll(0, "CHoCH_Bull_");
      ObjectsDeleteAll(0, "CHoCH_Path_");
      ObjectsDeleteAll(0, "CHoCH_Signal_");

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

      g_state_hist.mb_h = high[start_idx];
      g_state_hist.mb_l = low[start_idx];
      g_state_hist.mb_i = start_idx;

      g_state_hist.t1_h = 0; g_state_hist.t1_l = 0; g_state_hist.t1_i = 0;
      g_state_hist.d1_h = 0; g_state_hist.d1_l = 0; g_state_hist.d1_i = 0;
      g_state_hist.t2_h = 0; g_state_hist.t2_l = 0; g_state_hist.t2_i = 0;
      g_state_hist.choch_dir = 0;

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

   if (prev_calculated == 0 && limit < rates_total) {
      g_state_hist.mb_h = high[limit-1];
      g_state_hist.mb_l = low[limit-1];
      g_state_hist.mb_i = limit-1;
   }

   for(int i = limit; i < rates_total - 1; i++)
     {
      bool inside = (high[i] <= g_state_hist.mb_h) && (low[i] >= g_state_hist.mb_l);

      // Outside bar handle: Eğer aynı barda hem high hem low kırıldıysa (çok nadir ama olur),
      // sadece trend yönündeki kırılımı baz almak için tam Mother Bar güncellemesini yap.
      if(!inside)
        {
         if (high[i] > g_state_hist.mb_h || low[i] < g_state_hist.mb_l) {
            g_state_hist.mb_h = high[i];
            g_state_hist.mb_l = low[i];
            g_state_hist.mb_i = i;
         }
         ProcessBar(i, open, high, low, close, time, g_state_hist, true, true);
        }
     }

   ObjectsDeleteAll(0, "Live_");
   DeleteLine("LiveLeg");

   g_state_curr.CopyFrom(g_state_hist);

   int last_idx = rates_total - 1;
   bool inside_last = false;
   if(last_idx > 0)
     {
      inside_last = (high[last_idx] <= g_state_curr.mb_h) && (low[last_idx] >= g_state_curr.mb_l);
     }

   if(!inside_last && last_idx > 0)
     {
      ProcessBar(last_idx, open, high, low, close, time, g_state_curr, false, true);
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

   if(last_idx > 0 && (Period() == PERIOD_M1))
     {
      int live_trend = 0;
      double live_pct = 0.0;
      double temp_h_val, temp_l_val; datetime temp_th_val, temp_tl_val;
      double temp_mpct_val;

      // Calculate live_pct directly from live M1 state
      double h_m1 = g_state_curr.maj_h;
      double l_m1 = g_state_curr.maj_l;
      live_trend = g_state_curr.maj_tr;

      if (h_m1 != EMPTY_VALUE && l_m1 != EMPTY_VALUE && h_m1 != l_m1) {
          double range = h_m1 - l_m1;
          double live_price = close[last_idx];
          if (live_trend == 1) {
              live_pct = ((h_m1 - live_price) / range) * 100.0;
              if (live_price >= h_m1) live_pct = 0;
          } else {
              live_pct = ((live_price - l_m1) / range) * 100.0;
              if (live_price <= l_m1) live_pct = 0;
          }
          if (live_pct < 0) live_pct = 0;
      }

      if (true)
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
               if (InpEnableAlertTrendChange) {
                   string new_dir = (g_state_hist.maj_tr == 1) ? "YUKARI" : "AŞAĞI";
                   string trend_msg = "🚨 [" + Symbol() + "] M1 Trend Döndü! Yeni Yön: " + new_dir;
                   if(InpAlertPopup) Alert(trend_msg);
                   if(InpAlertPush)  SendNotification(trend_msg);
               }
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

         if(InpEnableAlertMTFLevels && (trig1 || trig2))
           {
            int trigger_lvl = trig2 ? 2 : 1;
            bool is_revisit = (trigger_lvl == 2) ? is_revisit_2 : is_revisit_1;
            bool success = TriggerMTFAlert(last_idx, time[last_idx], close[last_idx], trigger_lvl, is_revisit);
            if(success) {
               if(trig1) { g_level1_triggered = true; g_level1_missed = false; }
               if(trig2) { g_level2_triggered = true; g_level2_missed = false; }
            }
           }
        }
     }

   // 🧪 TEST TRIGGER EXECUTION (Yalnızca bir kez ve en güncel veriler işlendikten sonra çalıştırılır)
   static bool is_test_run = false;
   if (prev_calculated == 0) is_test_run = false; // Reset on re-compile/re-attach

   if (!is_test_run && last_idx > 0) {
       // TEST TRIGGER FOR TRADE EXECUTION
       if (InpTestTradeExecution) {
           int live_tr = g_state_curr.maj_tr;
           double live_pct = 0.0;

           double h_m1 = g_state_curr.maj_h;
           double l_m1 = g_state_curr.maj_l;
           double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
           if (h_m1 != EMPTY_VALUE && l_m1 != EMPTY_VALUE && h_m1 != l_m1) {
               double range = h_m1 - l_m1;
               if (live_tr == 1) {
                   live_pct = ((h_m1 - bid) / range) * 100.0;
                   if (bid >= h_m1) live_pct = 0;
               } else {
                   live_pct = ((bid - l_m1) / range) * 100.0;
                   if (bid <= l_m1) live_pct = 0;
               }
               if (live_pct < 0) live_pct = 0;
           }

           // Test Analizi, kullanıcının "Pullback sonrası ana trend devamı (BOS/Continuation CHoCH)" mantığına göre simüle edilir.
           int test_choch_dir = live_tr; // Trend Yönü ile aynı olmalı

           EvaluateTradeSignal(last_idx, TimeCurrent(), bid, test_choch_dir, live_pct, true, true);
           is_test_run = true;
       }

       // TEST TRIGGER FOR MTF LEVELS
       if (InpTestMode && !is_test_run) {
           TriggerMTFAlert(last_idx, TimeCurrent(), close[last_idx], 1, false);
           is_test_run = true;
       }
       if(!InpTestMode && !InpTestTradeExecution) is_test_run = true; // prevent infinite false state if both are off
   }

   return(rates_total);
  }