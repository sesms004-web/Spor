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
input group "--- TRADE EXECUTION & RISK ---"
input bool   InpEnableTradeExecution   = true;        // Master->Slave Sinyal Köprüsü Aktif
input bool   InpAlertRejectedTrades    = false;       // ❌ Reddedilen (Puanı Yetersiz) İşlemleri Bildir
input bool   InpWaitRetest             = false;       // 🎯 Gelişmiş Retest (Pusu) Modu Aktif
input int    InpRetestMaxBars          = 15;          // ⏳ Pusu Modunda Beklenecek Maksimum Mum
input double InpRetestDepthPct         = 0.0;         // 📉 Kırılım Çizgisine Göre Ucuzluk Beklentisi (%0=%100 Çizgisi)
input double InpRiskUSD                = 50.0;        // İşlem Başına Dolar Riski
input double InpStrongSLMultiplier     = 1.0;         // Güçlü Kırılım SL Genişletme Çarpanı
input double InpWeakSLMultiplier       = 1.5;         // Zayıf Kırılım SL Genişletme Çarpanı

input group "--- DİNAMİK SL MESAFE FİLTRESİ ---"
input bool   InpEnableSLPctLimit       = true;        // Ana Dalga Boyuna Göre SL Sınırlandırıcı (Aktif/Pasif)
input double InpMinSLPct               = 3.0;         // Min SL Uzaklığı (Ana Dalganın %'si)
input double InpMaxSLPct               = 15.0;        // Maks SL Uzaklığı (Ana Dalganın %'si)

input int    InpMinTradeScoreLimit = 40;       // İşlem İçin Min. Puan (100 Üzerinden)
input double InpMinPullbackPct = 40.0;           // CHoCH Min Çekilme % (Onay Yüzdeliği)
input double InpMaxPullbackPct = 100.0;          // CHoCH Max Çekilme % (İşlem Yüzdeliği)
input color  InpColorChochStrong = clrPurple;      // Güçlü CHoCH (Mor)
input color  InpColorChochWeak   = clrRed;         // Güçsuz CHoCH (Kırmızı)
input color  InpColorChochPath   = clrGray;        // Yapı İzi (Gri)
input bool   InpShowChoch      = true;           // CHoCH Çizgilerini Göster

//--- Visual Options ---
input bool   InpShowMin = true;
input bool   InpShowMaj = true;
input color  InpColorMin = clrRed;
input color  InpColorBull = clrGreen;
input color  InpColorBear = clrRed;

//--- Alert Settings ---
input bool   InpEnableAlertTrendChange = true;       // Ana Trend (Kapanış) Dönüş Bildirimini Aç
input bool   InpEnableAlertCHoCHBase   = true;       // Temel CHoCH (Kırılım) Bildirimini Aç
input bool   InpAlertPopup       = true;
input bool   InpAlertPush        = false;

//--- Globals ---
int g_counter = 0;
datetime g_last_alert_time = 0;
int g_alert_bar_index = -1;
datetime g_anchor_time = 0;

double g_last_alert_maj_h = 0;
double g_last_alert_maj_l = 0;
int g_last_alert_trend = 0;

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


// --- RETEST (PUSU) ENGINE GLOBALS ---
bool   g_pending_active = false;
int    g_pending_dir = 0;
int    g_pending_bar_i = 0;
double g_pending_entry = 0.0;
double g_pending_sl = 0.0;
bool   g_pending_is_strong = false;
double g_pending_p_pct = 0.0;
int    g_pending_maj_extreme_i = 0;

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

   // --- MTF CHoCH Tracking ---
   int               last_choch_dir;
   double            last_choch_level;
   int               last_choch_i;
   datetime          last_choch_time;


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

void ProcessBarMathOnly(int i, const double &high[], const double &low[], const double &close[], const datetime &time[], SState &state)
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
            state.last_choch_dir = -1;
            state.last_choch_level = state.maj_l;
            state.last_choch_time = time[i];

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
            state.last_choch_dir = 1;
            state.last_choch_level = state.maj_h;
            state.last_choch_time = time[i];
            state.last_choch_i = i;

            state.bos_i = i; state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
            state.st_h.Clear(); state.maj_st = 0; state.tmp_h = val_h; state.tmp_h_i = i;
           }
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l) state.maj_l = val_l;
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.last_choch_dir = -1;
            state.last_choch_level = state.maj_l;
            state.last_choch_time = time[i];

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
            state.last_choch_dir = 1;
            state.last_choch_level = state.maj_h;
            state.last_choch_time = time[i];

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
            state.last_choch_dir = -1;
            state.last_choch_level = state.maj_l;
            state.last_choch_time = time[i];
            state.last_choch_i = i;

            state.maj_h = state.tmp_h; state.bos_i = i; state.maj_h_i = state.tmp_h_i;
            state.st_l.Clear(); state.maj_st = 0; state.tmp_l = val_l; state.tmp_l_i = i;
           }
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h) state.maj_h = val_h;
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.last_choch_dir = 1;
            state.last_choch_level = state.maj_h;
            state.last_choch_time = time[i];

            state.maj_tr = 1; state.maj_st = 0; state.bos_i = i;
            state.st_h.Clear(); state.tmp_h = val_h; state.tmp_h_i = i;
            state.maj_l = state.tmp_l; state.maj_l_i = state.tmp_l_i;
           }
        }
     }
  }


void GetMTFChochDetails(ENUM_TIMEFRAMES tf, datetime current_time, int &c_dir, double &c_level, datetime &c_time) {
   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   double tf_days = GetDaysForTF(tf);
   datetime anchor_time = current_time - (datetime)(tf_days * 24.0 * 60.0 * 60.0);

   int copied = CopyRates(Symbol(), tf, anchor_time, current_time, rates);
   if(copied < 2) return;

   double _open[], _high[], _low[], _close[];
   datetime _time[];
   ArrayResize(_open, copied);
   ArrayResize(_high, copied);
   ArrayResize(_low, copied);
   ArrayResize(_close, copied);
   ArrayResize(_time, copied);

   for(int i=0; i<copied; i++) {
      _open[i]  = rates[i].open;
      _high[i]  = rates[i].high;
      _low[i]   = rates[i].low;
      _close[i] = rates[i].close;
      _time[i]  = rates[i].time;
   }

   SState st;
   st.min_h   = _high[0]; st.min_h_i = 0; st.min_l   = _low[0]; st.min_l_i = 0;
   st.trig_h  = _high[0]; st.trig_l  = _low[0];
   st.tmp_h   = _high[0]; st.tmp_h_i = 0; st.tmp_l   = _low[0]; st.tmp_l_i = 0;
   st.min_tr  = (_close[0] > rates[0].open) ? 1 : -1;

   double initial_gap = (_high[0] - _low[0]);
   if(initial_gap == 0) initial_gap = Point() * 10;
   double tiny_gap = initial_gap * 0.1;

   st.maj_h = _high[0] + tiny_gap;
   st.maj_l = _low[0] - tiny_gap;
   st.maj_tr = st.min_tr;
   st.maj_st = 1;
   st.bos_i = 0;
   st.maj_h_i = 0;
   st.maj_l_i = 0;
   st.mb_h = _high[0];
   st.mb_l = _low[0];
   st.mb_i = 0;

   st.last_choch_dir = 0;
   st.last_choch_level = 0;
   st.last_choch_time = 0;

   for(int i = 1; i < copied; i++) {
      bool inside = (_high[i] <= st.mb_h) && (_low[i] >= st.mb_l);
      if(!inside) {
         if (_high[i] > st.mb_h || _low[i] < st.mb_l) {
            st.mb_h = _high[i];
            st.mb_l = _low[i];
            st.mb_i = i;
         }
         if(i == copied - 1) {
            double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            _close[i] = bid;
            if(bid > _high[i]) _high[i] = bid;
            if(bid < _low[i]) _low[i] = bid;
         }
         ProcessBar(i, _open, _high, _low, _close, _time, st, true, false);
      }
   }

   c_dir = st.last_choch_dir;
   c_level = st.last_choch_level;
   c_time = st.last_choch_time;
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

   double _open[], _high[], _low[], _close[];
   datetime _time[];
   ArrayResize(_open, copied);
   ArrayResize(_high, copied);
   ArrayResize(_low, copied);
   ArrayResize(_close, copied);
   ArrayResize(_time, copied);

   for(int i=0; i<copied; i++)
     {
      _open[i]  = rates[i].open;
      _high[i] = rates[i].high;
      _low[i]  = rates[i].low;
      _close[i] = rates[i].close;
      _time[i] = rates[i].time;
     }

   SState st;
   st.min_h   = _high[0]; st.min_h_i = 0; st.min_l   = _low[0]; st.min_l_i = 0;
   st.trig_h  = _high[0]; st.trig_l  = _low[0];
   st.tmp_h   = _high[0]; st.tmp_h_i = 0; st.tmp_l   = _low[0]; st.tmp_l_i = 0;
   st.min_tr  = (_close[0] > rates[0].open) ? 1 : -1;

   double initial_gap = (_high[0] - _low[0]);
   if(initial_gap == 0) initial_gap = Point() * 10;
   double tiny_gap = initial_gap * 0.1;

   st.maj_h = _high[0] + tiny_gap;
   st.maj_l = _low[0] - tiny_gap;
   st.maj_tr = st.min_tr;
   st.maj_st = 1;
   st.bos_i = 0;
   st.maj_h_i = 0;
   st.maj_l_i = 0;

   st.mb_h = _high[0];
   st.mb_l = _low[0];
   st.mb_i = 0;

   for(int i = 1; i < copied; i++)
     {
      bool inside = (_high[i] <= st.mb_h) && (_low[i] >= st.mb_l);
      if(!inside)
        {
         // Dışarı çıktı, yeni mother bar olabilir
         if (_high[i] > st.mb_h || _low[i] < st.mb_l) {
            st.mb_h = _high[i];
            st.mb_l = _low[i];
            st.mb_i = i;
         }
         if(i == copied - 1)
           {
            double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            _close[i] = bid;
            if(bid > _high[i]) _high[i] = bid;
            if(bid < _low[i]) _low[i] = bid;
           }

         ProcessBar(i, _open, _high, _low, _close, _time, st, true, false);
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

      // M1 hassasiyetinde tmp_h ve tmp_l bulalım
      datetime start_time = (trend == 1) ? ref_t_h : ref_t_l;
      if (start_time == 0) start_time = current_time - (3600 * 24); // Fallback

      int m1_copied = CopyRates(Symbol(), PERIOD_M1, start_time, current_time, rates);
      double precise_tmp_l = st.tmp_l; // Fallback
      double precise_tmp_h = st.tmp_h; // Fallback

      if(m1_copied > 0) {
          int best_i = 0;
          double best_v = (trend == 1) ? 0.0 : 9999999.0;

          // 1. Önce bu periyottaki gerçek UÇ NOKTAYI (Tepeyi/Dibi) tam olarak hangi M1 mumunda yaptığını bul
          for(int k=0; k<m1_copied; k++) {
              if(trend == 1 && rates[k].high > best_v) { best_v = rates[k].high; best_i = k; }
              if(trend == -1 && rates[k].low < best_v) { best_v = rates[k].low; best_i = k; }
          }

          // 2. Fiyat o uç noktayı gördükten SONRAKİ en büyük düzeltme iğnesini bul
          double ext_val = live_p; // Varsayılan olarak anlık fiyattan başla
          for(int k=best_i; k<m1_copied; k++) {
              if(trend == 1 && rates[k].low < ext_val) ext_val = rates[k].low;
              if(trend == -1 && rates[k].high > ext_val) ext_val = rates[k].high;
          }

          if(trend == 1) precise_tmp_l = ext_val;
          if(trend == -1) precise_tmp_h = ext_val;
      }

      if(trend == 1)
        {
         if(live_p >= st.maj_h || st.maj_st == 0)
           {
            double dyn_range = precise_tmp_h - st.maj_l;
            if(dyn_range > 0) {
                pct = ((precise_tmp_h - live_p) / dyn_range) * 100.0;
                max_pct = ((precise_tmp_h - precise_tmp_l) / dyn_range) * 100.0;
            } else {
                pct = 0; max_pct = 0;
            }
           }
         else
           {
            pct = ((st.maj_h - live_p) / range) * 100.0;
            max_pct = ((st.maj_h - precise_tmp_l) / range) * 100.0;
           }
        }
      else if(trend == -1)
        {
         if(live_p <= st.maj_l || st.maj_st == 0)
           {
            double dyn_range = st.maj_h - precise_tmp_l;
            if(dyn_range > 0) {
                pct = ((live_p - precise_tmp_l) / dyn_range) * 100.0;
                max_pct = ((precise_tmp_h - precise_tmp_l) / dyn_range) * 100.0;
            } else {
                pct = 0; max_pct = 0;
            }
           }
         else
           {
            pct = ((live_p - st.maj_l) / range) * 100.0;
            max_pct = ((precise_tmp_h - st.maj_l) / range) * 100.0;
           }
        }
     }

   if(pct < 0) pct = 0;
   if(pct > 100) pct = 100;
   if(max_pct < 0) max_pct = 0;
   if(max_pct > 100) max_pct = 100;


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
   string age = "    └ Oluşum: " + GetTimeAgoString(swing_time, current_time);
   string base_str = "(Çekilme: %" + DoubleToString(pct, 2) + " ↑↑%" + DoubleToString(max_pct, 2);

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
//| 50-Point Execution Analysis Engine                               |
//+------------------------------------------------------------------+
string GenerateMTFString(string tf_name, int trend, double h, double l, double p, double mp) {
    string trend_str = (trend == 1) ? "🟢 YÜKSELİŞ" : ((trend == -1) ? "🔴 DÜŞÜŞ" : "⚪ YATAY");
    string str_h = DoubleToString(h, _Digits);
    string str_l = DoubleToString(l, _Digits);
    string res = StringFormat("%s: %s | Tepe: %s Dip: %s | Maks Çekilme: %%%.2f, Anlık: %%%.2f\n", tf_name, trend_str, str_h, str_l, mp, p);
    return res;
}


void BroadcastTradeSignal(string symbol, int direction, double entry, double sl, double tp, bool is_strong, int score) {
    if (!InpEnableTradeExecution) return;

    string filename = "SMC_SIGNAL_" + symbol + ".json";
    int handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
    if(handle == INVALID_HANDLE) {
        Print("Sinyal JSON dosyası oluşturulamadı! Hata: ", GetLastError());
        return;
    }

    string dir_str = (direction == 1) ? "BUY" : "SELL";
    string is_strong_str = is_strong ? "true" : "false";
        string json = "{\n";
    json += "  \"symbol\": \"" + symbol + "\",\n";
    json += "  \"direction\": \"" + dir_str + "\",\n";
    json += "  \"entry\": " + DoubleToString(entry, _Digits) + ",\n";
    json += "  \"sl\": " + DoubleToString(sl, _Digits) + ",\n";
    json += "  \"tp\": " + DoubleToString(tp, _Digits) + ",\n";
    json += "  \"base_extreme\": " + DoubleToString(sl, _Digits) + ",\n"; // Keeping legacy format compatibility
    json += "  \"is_strong\": " + is_strong_str + ",\n";
    json += "  \"score\": " + IntegerToString(score) + ",\n";
        json += "  \"risk_usd\": " + DoubleToString(InpRiskUSD, 2) + " ";
    json += "}";

    FileWrite(handle, json);
    FileClose(handle);
    Print("✅ Sinyal Master EA (smcvol01) tarafından Terminal Ortak Klasörüne Yazıldı -> ", filename);
}


struct SMTFReport {
    ENUM_TIMEFRAMES tf;
    string tf_name;
    int dir;
    double level;
    datetime time;
    string text;
};

void GenerateMTFChochReport() {
    SMTFReport reports[4];
    reports[0].tf_name = "M5 ";
    reports[1].tf_name = "M15";
    reports[2].tf_name = "M30";
    reports[3].tf_name = "H1 ";

    ENUM_TIMEFRAMES tfs[4] = {PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1};
    datetime t = TimeCurrent();

    for (int i=0; i<4; i++) {
        reports[i].tf = tfs[i];
        GetMTFChochDetails(tfs[i], t, reports[i].dir, reports[i].level, reports[i].time);
    }

    for(int i=0; i<3; i++) {
        for(int j=0; j<3-i; j++) {
            if(reports[j].time < reports[j+1].time) {
                SMTFReport temp = reports[j];
                reports[j] = reports[j+1];
                reports[j+1] = temp;
            }
        }
    }

    string msg = "\n⏱️ ÜST ZAMAN DİLİMİ KIRILIM (CHoCH) RAPORU:\n\n";
    double live_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    for(int i=0; i<4; i++) {
        if (reports[i].time == 0) continue;

        string dir_str = (reports[i].dir == 1) ? "🟢 YUKARI" : ((reports[i].dir == -1) ? "🔴 AŞAĞI " : "BİLİNMİYOR");
        string age_str = GetTimeAgoString(reports[i].time, t);
        int bars_ago = iBarShift(Symbol(), reports[i].tf, reports[i].time);
        age_str += ", " + IntegerToString(bars_ago) + " Mum Önce";

        bool is_valid = false;
        if (reports[i].dir == 1 && live_price > reports[i].level) is_valid = true;
        if (reports[i].dir == -1 && live_price < reports[i].level) is_valid = true;

        string valid_str = "";
        if (is_valid) valid_str = "✅ GEÇERLİ";
        else if (reports[i].dir == -1) valid_str = "❌ GEÇERSİZ (Fiyat Çizginin Üstünde)";
        else if (reports[i].dir == 1) valid_str = "❌ GEÇERSİZ (Fiyat Çizginin Altında)";

        msg += IntegerToString(i+1) + ". " + reports[i].tf_name + ": " + dir_str + " (" + age_str + ") | Çizgi: " + DoubleToString(reports[i].level, _Digits) + " -> " + valid_str + "\n";
    }

    if(InpAlertPopup) Alert(msg);
    if(InpAlertPush) SendNotification(msg);
}

void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, double minor_extreme_sl, int maj_extreme_i)
  {
   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double h_m1=0, l_m1=0, h_m3=0, l_m3=0, h_m5=0, l_m5=0, h_m15=0, l_m15=0, h_m30=0, l_m30=0, h_h1=0, l_h1=0;
   datetime dmy_th, dmy_tl, th_m15, tl_m15, th_m30, tl_m30;

   // We need MTF data to evaluate the matrix
   GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, h_m1, l_m1, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, h_m3, l_m3, dmy_th, dmy_tl);

   int total_points = 0;
   string h1_text = "";
   string m30_text = "";
   string m15_text = "";
   string m5_text = "";
   string m1_text = "";

   // --- MTF CHOCH ANALİZİ SİSTEMİ ---

   // --- M1 (Tetikleyici) ---
   m1_text = GenerateMTFString("M1", t_m1, h_m1, l_m1, p_m1, mp_m1);
   if(is_strong) m1_text += "🔥 Likidite Temizlendi
";
   else          m1_text += "⚠️ Likidite Alınmadı
";

   // --- MTF CHOCH ANALİZİ ---

   int c_dir_h1=0, c_dir_m30=0, c_dir_m15=0, c_dir_m5=0;
   double c_lvl_h1=0, c_lvl_m30=0, c_lvl_m15=0, c_lvl_m5=0;
   datetime c_t_h1=0, c_t_m30=0, c_t_m15=0, c_t_m5=0;

   GetMTFChochDetails(PERIOD_H1, TimeCurrent(), c_dir_h1, c_lvl_h1, c_t_h1);
   GetMTFChochDetails(PERIOD_M30, TimeCurrent(), c_dir_m30, c_lvl_m30, c_t_m30);
   GetMTFChochDetails(PERIOD_M15, TimeCurrent(), c_dir_m15, c_lvl_m15, c_t_m15);
   GetMTFChochDetails(PERIOD_M5, TimeCurrent(), c_dir_m5, c_lvl_m5, c_t_m5);

   int h1_sup_points=0, m30_sup_points=0, m15_sup_points=0, m5_sup_points=0;
   string h1_sup_text="", m30_sup_text="", m15_sup_text="", m5_sup_text="";

   bool valid_h1 = (c_dir_h1 == 1 && live_price > c_lvl_h1) || (c_dir_h1 == -1 && live_price < c_lvl_h1);
   bool valid_m30 = (c_dir_m30 == 1 && live_price > c_lvl_m30) || (c_dir_m30 == -1 && live_price < c_lvl_m30);
   bool valid_m15 = (c_dir_m15 == 1 && live_price > c_lvl_m15) || (c_dir_m15 == -1 && live_price < c_lvl_m15);
   bool valid_m5 = (c_dir_m5 == 1 && live_price > c_lvl_m5) || (c_dir_m5 == -1 && live_price < c_lvl_m5);

   if (trigger_dir == 1) { // M1 BUY
       if (c_dir_h1 == 1 && valid_h1) { h1_sup_points = 20; h1_sup_text = "🟢 H1 Yukarı + Geçerli -> [+20 Puan]\n"; }
       else if (c_dir_h1 == 1 && !valid_h1) { h1_sup_points = -20; h1_sup_text = "🔴 H1 Yukarı + Geçersiz (Tuzak) -> [-20 Puan]\n"; }
       else if (c_dir_h1 == -1 && valid_h1) { h1_sup_points = -20; h1_sup_text = "🔴 H1 Aşağı + Geçerli -> [-20 Puan]\n"; }
       else if (c_dir_h1 == -1 && !valid_h1) { h1_sup_points = 20; h1_sup_text = "🟢 H1 Aşağı + Geçersiz (Tuzak) -> [+20 Puan]\n"; }
       else { h1_sup_text = "⚪ H1 Veri Bekleniyor... -> [0 Puan]\n"; }

       if (c_dir_m30 == 1 && valid_m30) { m30_sup_points = 15; m30_sup_text = "🟢 M30 Yukarı + Geçerli -> [+15 Puan]\n"; }
       else if (c_dir_m30 == 1 && !valid_m30) { m30_sup_points = -15; m30_sup_text = "🔴 M30 Yukarı + Geçersiz (Tuzak) -> [-15 Puan]\n"; }
       else if (c_dir_m30 == -1 && valid_m30) { m30_sup_points = -15; m30_sup_text = "🔴 M30 Aşağı + Geçerli -> [-15 Puan]\n"; }
       else if (c_dir_m30 == -1 && !valid_m30) { m30_sup_points = 15; m30_sup_text = "🟢 M30 Aşağı + Geçersiz (Tuzak) -> [+15 Puan]\n"; }
       else { m30_sup_text = "⚪ M30 Veri Bekleniyor... -> [0 Puan]\n"; }

       if (c_dir_m15 == 1 && valid_m15) { m15_sup_points = 10; m15_sup_text = "🟢 M15 Yukarı + Geçerli -> [+10 Puan]\n"; }
       else if (c_dir_m15 == 1 && !valid_m15) { m15_sup_points = -10; m15_sup_text = "🔴 M15 Yukarı + Geçersiz (Tuzak) -> [-10 Puan]\n"; }
       else if (c_dir_m15 == -1 && valid_m15) { m15_sup_points = -10; m15_sup_text = "🔴 M15 Aşağı + Geçerli -> [-10 Puan]\n"; }
       else if (c_dir_m15 == -1 && !valid_m15) { m15_sup_points = 10; m15_sup_text = "🟢 M15 Aşağı + Geçersiz (Tuzak) -> [+10 Puan]\n"; }
       else { m15_sup_text = "⚪ M15 Veri Bekleniyor... -> [0 Puan]\n"; }

       if (c_dir_m5 == 1 && valid_m5) { m5_sup_points = 5; m5_sup_text = "🟢 M5 Yukarı + Geçerli -> [+5 Puan]\n"; }
       else if (c_dir_m5 == 1 && !valid_m5) { m5_sup_points = -5; m5_sup_text = "🔴 M5 Yukarı + Geçersiz (Tuzak) -> [-5 Puan]\n"; }
       else if (c_dir_m5 == -1 && valid_m5) { m5_sup_points = -5; m5_sup_text = "🔴 M5 Aşağı + Geçerli -> [-5 Puan]\n"; }
       else if (c_dir_m5 == -1 && !valid_m5) { m5_sup_points = 5; m5_sup_text = "🟢 M5 Aşağı + Geçersiz (Tuzak) -> [+5 Puan]\n"; }
       else { m5_sup_text = "⚪ M5 Veri Bekleniyor... -> [0 Puan]\n"; }
   } else { // M1 SELL
       if (c_dir_h1 == -1 && valid_h1) { h1_sup_points = 20; h1_sup_text = "🔴 H1 Aşağı + Geçerli -> [+20 Puan]\n"; }
       else if (c_dir_h1 == -1 && !valid_h1) { h1_sup_points = -20; h1_sup_text = "🟢 H1 Aşağı + Geçersiz (Tuzak) -> [-20 Puan]\n"; }
       else if (c_dir_h1 == 1 && valid_h1) { h1_sup_points = -20; h1_sup_text = "🟢 H1 Yukarı + Geçerli -> [-20 Puan]\n"; }
       else if (c_dir_h1 == 1 && !valid_h1) { h1_sup_points = 20; h1_sup_text = "🔴 H1 Yukarı + Geçersiz (Tuzak) -> [+20 Puan]\n"; }
       else { h1_sup_text = "⚪ H1 Veri Bekleniyor... -> [0 Puan]\n"; }

       if (c_dir_m30 == -1 && valid_m30) { m30_sup_points = 15; m30_sup_text = "🔴 M30 Aşağı + Geçerli -> [+15 Puan]\n"; }
       else if (c_dir_m30 == -1 && !valid_m30) { m30_sup_points = -15; m30_sup_text = "🟢 M30 Aşağı + Geçersiz (Tuzak) -> [-15 Puan]\n"; }
       else if (c_dir_m30 == 1 && valid_m30) { m30_sup_points = -15; m30_sup_text = "🟢 M30 Yukarı + Geçerli -> [-15 Puan]\n"; }
       else if (c_dir_m30 == 1 && !valid_m30) { m30_sup_points = 15; m30_sup_text = "🔴 M30 Yukarı + Geçersiz (Tuzak) -> [+15 Puan]\n"; }
       else { m30_sup_text = "⚪ M30 Veri Bekleniyor... -> [0 Puan]\n"; }

       if (c_dir_m15 == -1 && valid_m15) { m15_sup_points = 10; m15_sup_text = "🔴 M15 Aşağı + Geçerli -> [+10 Puan]\n"; }
       else if (c_dir_m15 == -1 && !valid_m15) { m15_sup_points = -10; m15_sup_text = "🟢 M15 Aşağı + Geçersiz (Tuzak) -> [-10 Puan]\n"; }
       else if (c_dir_m15 == 1 && valid_m15) { m15_sup_points = -10; m15_sup_text = "🟢 M15 Yukarı + Geçerli -> [-10 Puan]\n"; }
       else if (c_dir_m15 == 1 && !valid_m15) { m15_sup_points = 10; m15_sup_text = "🔴 M15 Yukarı + Geçersiz (Tuzak) -> [+10 Puan]\n"; }
       else { m15_sup_text = "⚪ M15 Veri Bekleniyor... -> [0 Puan]\n"; }

       if (c_dir_m5 == -1 && valid_m5) { m5_sup_points = 5; m5_sup_text = "🔴 M5 Aşağı + Geçerli -> [+5 Puan]\n"; }
       else if (c_dir_m5 == -1 && !valid_m5) { m5_sup_points = -5; m5_sup_text = "🟢 M5 Aşağı + Geçersiz (Tuzak) -> [-5 Puan]\n"; }
       else if (c_dir_m5 == 1 && valid_m5) { m5_sup_points = -5; m5_sup_text = "🟢 M5 Yukarı + Geçerli -> [-5 Puan]\n"; }
       else if (c_dir_m5 == 1 && !valid_m5) { m5_sup_points = 5; m5_sup_text = "🔴 M5 Yukarı + Geçersiz (Tuzak) -> [+5 Puan]\n"; }
       else { m5_sup_text = "⚪ M5 Veri Bekleniyor... -> [0 Puan]\n"; }
   }

   total_points += h1_sup_points + m30_sup_points + m15_sup_points + m5_sup_points;
   string sup_text = "\n🛡️ MTF CHOCH ANALİZİ:\n";
   sup_text += h1_sup_text + m30_sup_text + m15_sup_text + m5_sup_text;

   string order_details = "";
   // --- M1 vs M3 RANGE EXPECTATION ---
   string range_text = (t_m1 == t_m3) ? "🚀 BEKLENTİ: UZUN MENZİL (Trend Takibi)" : "⚠️ BEKLENTİ: KISA SÜRECEK (Scalp/Tepki)";

   // --- BREAKOUT LEVEL PHASING ---
   string lvl_text = "BİLİNMİYOR";
   if (p_pct >= 40.0 && p_pct < 60.0) lvl_text = "KIRILIM 1 (Erken Seviye)";
   if (p_pct >= 60.0) lvl_text = "KIRILIM 2 (Ana Seviye)";

   // --- FINAL VERDICT ---
   string verdict = "";


   if (total_points >= InpMinTradeScoreLimit) {
       verdict = "✅ İŞLEME GİRİLEBİLİR (Yüksek Olasılıklı Kurulum)";

       double sl_price = minor_extreme_sl;
       double entry_price = live_price;
       double sl_dist = MathAbs(entry_price - minor_extreme_sl);

       // Apply Weak/Strong SL multipliers
       if (is_strong) sl_dist *= InpStrongSLMultiplier;
       else           sl_dist *= InpWeakSLMultiplier;

       // YENİ KURAL: Ana Dalga Yüzdesine Göre Dinamik SL Kısıtlaması (Fren/Gaz)
       string sl_note = "";
       if (InpEnableSLPctLimit && h_m1 != 0 && l_m1 != 0) {
           double swing_range = MathAbs(h_m1 - l_m1);
           if (swing_range > 0) {
               double sl_pct = (sl_dist / swing_range) * 100.0;
               if (sl_pct > InpMaxSLPct) {
                   sl_dist = swing_range * (InpMaxSLPct / 100.0);
                   sl_note = " 🛑 (Çok Geniş SL Daraltıldı: %" + DoubleToString(InpMaxSLPct, 1) + ")";
               } else if (sl_pct < InpMinSLPct) {
                   sl_dist = swing_range * (InpMinSLPct / 100.0);
                   sl_note = " 🚀 (Çok Dar SL Genişletildi: %" + DoubleToString(InpMinSLPct, 1) + ")";
               }
           }
       }

       if (trigger_dir == 1) sl_price = entry_price - sl_dist;
       else                  sl_price = entry_price + sl_dist;

       // TP at 3R
       double tp_dist = sl_dist * 3.0;
       double tp_price = (trigger_dir == 1) ? (entry_price + tp_dist) : (entry_price - tp_dist);


       order_details = "   📊 HESAPLANAN HEDEFLER (Sinyal Köprüsü):\n";
       order_details += "Giriş: " + DoubleToString(entry_price, _Digits) + " ";
       order_details += "Zarar Durdur (SL): " + DoubleToString(sl_price, _Digits) + " (" + DoubleToString(sl_dist/_Point, 0) + " points)" + sl_note + " ";
       order_details += "Kâr Al (TP 3R): " + DoubleToString(tp_price, _Digits) + " (" + DoubleToString(tp_dist/_Point, 0) + " points)\n";

       static int last_broadcast_maj_extreme_i = -1;
       if (maj_extreme_i != last_broadcast_maj_extreme_i || maj_extreme_i == 0) {
           BroadcastTradeSignal(Symbol(), trigger_dir, entry_price, sl_price, tp_price, is_strong, total_points);
           last_broadcast_maj_extreme_i = maj_extreme_i;
       } else {
           order_details += "\n⚠️ UYARI: Bu dalgada zaten işleme girildi, tekrar girilmiyor! Sadece bildirim.";
       }
   }
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Puan Yetersiz)";


   string dir_str = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";

   string msg = "";
   msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\n";
   msg += "Yön: " + dir_str + " \n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\n" + m1_text + " ";
   msg += sup_text + "\n";
   msg += "🎯 İŞLEM MENZİLİ (M1 ve M3 Uyumu):\n" + range_text + " \n";
   msg += "📈 TOPLAM İŞLEM SKORU:\n";
   msg += "Hesaplanan: " + IntegerToString(total_points) + " Puan (Gerekli Baraj: " + IntegerToString(InpMinTradeScoreLimit) + " Puan)\n";
   msg += "KARAR: " + verdict;
   msg += order_details;

   if (total_points >= InpMinTradeScoreLimit || InpAlertRejectedTrades) {
       if(InpAlertPopup) Alert(msg);
       if(InpAlertPush) {
           string msg1 = "🚨 [" + Symbol() + "] YENİ İŞLEM (1/2)\n" + "🔍 M1 KIRILIM:\n" + m1_text + "\n📊 ZAMAN DİLİMİ ANALİZİ:\n" + h1_text + m30_text + m15_text + m5_text;
           string msg2 = "🚨 [" + Symbol() + "] (2/2)\n" + sup_text + "\n📈 SKOR: " + IntegerToString(total_points) + " Puan\n" + verdict;
           SendNotification(msg1);
           Sleep(100); // Prevent spam block
           SendNotification(msg2);
       }
   }
  }

//+------------------------------------------------------------------+
//| MTF Alert System (Smart Algorithmic Decision Engine)             |
//+------------------------------------------------------------------+
