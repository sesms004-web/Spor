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


datetime GetTimeSafe(const datetime &time_array[], int idx) {
    if (idx >= 0 && idx < ArraySize(time_array)) {
        return time_array[idx];
    }
    return 0; // Or handle as appropriate
}
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
input bool   InpTestMTFChochReport     = false;       // 🧪 Üst Zaman Dilimi (MTF) CHoCH Raporunu Tetikle
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
input bool   InpEnableAlertMTFLevels   = true;       // %40/%60 MTF Analiz Bildirimini Aç (Bölüm 1/2)
input bool   InpEnableAlertCHoCHBase   = true;       // Temel CHoCH (Kırılım) Bildirimini Aç
input bool   InpTestTradeExecution     = false;      // 🧪 [TEST] Anlık Puanları Hesapla ve Bildir
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


void BroadcastTradeSignal(string symbol, int direction, double entry, double sl, double tp, bool is_strong, int score, bool is_test) {
    if (!InpEnableTradeExecution) return;

    string filename = "SMC_SIGNAL_" + symbol + ".json";
    int handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
    if(handle == INVALID_HANDLE) {
        Print("Sinyal JSON dosyası oluşturulamadı! Hata: ", GetLastError());
        return;
    }

    string dir_str = (direction == 1) ? "BUY" : "SELL";
    string is_strong_str = is_strong ? "true" : "false";
    string is_test_str = is_test ? "true" : "false";

    string json = "{\n";
    json += "  \"symbol\": \"" + symbol + "\",\n";
    json += "  \"direction\": \"" + dir_str + "\",\n";
    json += "  \"entry\": " + DoubleToString(entry, _Digits) + ",\n";
    json += "  \"sl\": " + DoubleToString(sl, _Digits) + ",\n";
    json += "  \"tp\": " + DoubleToString(tp, _Digits) + ",\n";
    json += "  \"base_extreme\": " + DoubleToString(sl, _Digits) + ",\n"; // Keeping legacy format compatibility
    json += "  \"is_strong\": " + is_strong_str + ",\n";
    json += "  \"score\": " + IntegerToString(score) + ",\n";
    json += "  \"is_test\": " + is_test_str + ",\n";
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

void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, double minor_extreme_sl, int maj_extreme_i, bool is_test = false)
  {
   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double h_m1=0, l_m1=0, h_m3=0, l_m3=0, h_m5=0, l_m5=0, h_m15=0, l_m15=0, h_m30=0, l_m30=0, h_h1=0, l_h1=0;
   datetime dmy_th, dmy_tl, th_m15, tl_m15, th_m30, tl_m30;

   // We need MTF data to evaluate the matrix
   GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, h_m1, l_m1, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, h_m3, l_m3, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M5, t_m5, p_m5, mp_m5, t, h_m5, l_m5, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, h_m15, l_m15, th_m15, tl_m15);
   GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, h_m30, l_m30, th_m30, tl_m30);
   GetMTFPullback(PERIOD_H1, t_h1, p_h1, mp_h1, t, h_h1, l_h1, dmy_th, dmy_tl);

   int total_points = 0;
   string h1_text = "";
   string m30_text = "";
   string m15_text = "";
   string m5_text = "";
   string m1_text = "";

   // --- YENİ 100 PUANLIK MATRİS SİSTEMİ ---

   // --- M1 (Tetikleyici) - Maks 5 Puan ---
   int m1_points = is_strong ? 5 : 0;
   total_points += m1_points;
   m1_text = GenerateMTFString("M1", t_m1, h_m1, l_m1, p_m1, mp_m1);
   if(is_strong) m1_text += "🔥 Likidite Temizlendi -> [+5 Puan]\n";
   else          m1_text += "⚠️ Likidite Alınmadı -> [+0 Puan]\n";

   // --- H1 (Makro Trend) - Maks 35 Puan ---
   int h1_points = 0;
   double h1_mom = mp_h1 - p_h1;
   bool is_h1_aligned = (t_h1 == trigger_dir);

   if (h1_mom >= 15.0) {
       if (is_h1_aligned) {
           if (h1_mom >= 20.0) { h1_points = 35; h1_text = "🚀 Uyumlu, Çok Sert Momentum -> [+35 Puan]\n"; }
           else                { h1_points = 30; h1_text = "⚡ Uyumlu, Sert Momentum -> [+30 Puan]\n"; }
       } else {
           h1_points = 0; h1_text = "🛑 Ters Yönlü Sert Momentum -> [0 Puan]\n";
       }
   } else {
       if (is_h1_aligned) {
           if (p_h1 >= 50.0) { h1_points = 30; h1_text = "🎯 Uyumlu, Momentum Yok Ama %50 İdeal -> [+30 Puan]\n"; }
           else              { h1_points = 10; h1_text = "📉 Uyumlu, Momentum Yok Ve Şişkin -> [+10 Puan]\n"; }
       } else {
           if (p_h1 >= 50.0) { h1_points = 20; h1_text = "🔄 Ters Yönlü Ama %50 İdeal -> [+20 Puan]\n"; }
           else              { h1_points = 30; h1_text = "⏳ Ters Yönlü Ve Şişkin -> [+30 Puan]\n"; }
       }
   }
   h1_text = GenerateMTFString("H1", t_h1, h_h1, l_h1, p_h1, mp_h1) + h1_text;
   total_points += h1_points;

   // --- M30 (Makro Trend 2) - Maks 25 Puan ---
   int m30_points = 0;
   double m30_mom = mp_m30 - p_m30;
   bool is_m30_aligned = (t_m30 == trigger_dir);
   bool clone_m30_h1 = (MathAbs(h_m30 - h_h1) < Point() * 5 && MathAbs(l_m30 - l_h1) < Point() * 5);

   if (clone_m30_h1) {
       m30_points = 0; m30_text = "👯 H1 İle Aynı Yapı Es Geçildi -> [0 Puan]\n";
   } else {
       if (!is_m30_aligned) {
           if (m30_mom >= 15.0) { m30_points = 0;  m30_text = "🛑 Bize Karşı Sert Tepki -> [0 Puan]\n"; }
           else                 { m30_points = 10; m30_text = "😴 Ters Yönlü Ama Sakin -> [+10 Puan]\n"; }
       } else {
           if (m30_mom >= 20.0)      { m30_points = 25; m30_text = "🚀 Uyumlu, Çok Sert Dönüş -> [+25 Puan]\n"; }
           else if (m30_mom >= 15.0) { m30_points = 20; m30_text = "⚡ Uyumlu, Sert Dönüş -> [+20 Puan]\n"; }
           else if (p_m30 >= 50.0)   { m30_points = 15; m30_text = "🎯 Uyumlu, Tepki Yok Ama %50 İdeal -> [+15 Puan]\n"; }
           else                      { m30_points = 5;  m30_text = "📉 Uyumlu, Tepki Yok Ve Şişkin -> [+5 Puan]\n"; }
       }
   }
   m30_text = GenerateMTFString("M30", t_m30, h_m30, l_m30, p_m30, mp_m30) + m30_text;
   total_points += m30_points;

   // --- M15 (Makro Yapı) - Maks 20 Puan ---
   int m15_points = 0;
   double m15_mom = mp_m15 - p_m15;
   bool is_m15_aligned = (t_m15 == trigger_dir);
   bool clone_m15_m30 = (MathAbs(h_m15 - h_m30) < Point() * 5 && MathAbs(l_m15 - l_m30) < Point() * 5);

   if (clone_m15_m30) {
       m15_points = 0; m15_text = "👯 M30 İle Aynı Yapı Es Geçildi -> [0 Puan]\n";
   } else {
       if (!is_m15_aligned) {
           if (m15_mom >= 15.0) { m15_points = 0; m15_text = "🛑 Bize Karşı Sert Tepki -> [0 Puan]\n"; }
           else                 { m15_points = 5; m15_text = "😴 Ters Yönlü Ama Sakin -> [+5 Puan]\n"; }
       } else {
           if (m15_mom >= 20.0)      { m15_points = 20; m15_text = "🚀 Uyumlu, Çok Sert Dönüş -> [+20 Puan]\n"; }
           else if (m15_mom >= 15.0) { m15_points = 15; m15_text = "⚡ Uyumlu, Sert Dönüş -> [+15 Puan]\n"; }
           else if (p_m15 >= 50.0)   { m15_points = 15; m15_text = "🎯 Uyumlu, Tepki Yok Ama %50 İdeal -> [+15 Puan]\n"; }
           else                      { m15_points = 5;  m15_text = "📉 Uyumlu, Tepki Yok Ve Şişkin -> [+5 Puan]\n"; }
       }
   }
   m15_text = GenerateMTFString("M15", t_m15, h_m15, l_m15, p_m15, mp_m15) + m15_text;
   total_points += m15_points;

   // --- M5 (Mikro Filtre) - Maks 15 Puan ---
   int m5_points = 0;
   double m5_mom = mp_m5 - p_m5;
   bool is_m5_aligned = (t_m5 == trigger_dir);
   bool clone_m5_m15 = (MathAbs(h_m5 - h_m15) < Point() * 5 && MathAbs(l_m5 - l_m15) < Point() * 5);

   if (clone_m5_m15) {
       m5_points = 0; m5_text = "👯 M15 İle Aynı Yapı Es Geçildi -> [0 Puan]\n";
   } else {
       if (!is_m5_aligned) {
           if (m5_mom >= 15.0) { m5_points = 0; m5_text = "🛑 Bize Karşı Sert Tepki -> [0 Puan]\n"; }
           else                { m5_points = 5; m5_text = "😴 Ters Yönlü Ama Sakin -> [+5 Puan]\n"; }
       } else {
           if (m5_mom >= 20.0)      { m5_points = 15; m5_text = "🚀 Uyumlu, Çok Sert Dönüş -> [+15 Puan]\n"; }
           else if (m5_mom >= 15.0) { m5_points = 10; m5_text = "⚡ Uyumlu, Sert Dönüş -> [+10 Puan]\n"; }
           else if (p_m5 >= 50.0)   { m5_points = 10; m5_text = "🎯 Uyumlu, Tepki Yok Ama %50 İdeal -> [+10 Puan]\n"; }
           else                     { m5_points = 5;  m5_text = "📉 Uyumlu, Tepki Yok Ve Şişkin -> [+5 Puan]\n"; }
       }
   }
   m5_text = GenerateMTFString("M5 ", t_m5, h_m5, l_m5, p_m5, mp_m5) + m5_text;

   total_points += m5_points;

   // --- YENİ DESTEKLEYİCİ CHOCH FAKEOUT (TUZAK) MATRİS SİSTEMİ ---

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

   // TIME PENALTY LOGIC (4. Sırada H1 ise -15, değilse -10)
   SMTFReport treps[4];
   treps[0].time = c_t_h1; treps[0].tf = PERIOD_H1; treps[0].tf_name = "H1";
   treps[1].time = c_t_m30; treps[1].tf = PERIOD_M30; treps[1].tf_name = "M30";
   treps[2].time = c_t_m15; treps[2].tf = PERIOD_M15; treps[2].tf_name = "M15";
   treps[3].time = c_t_m5; treps[3].tf = PERIOD_M5; treps[3].tf_name = "M5";

   for(int i=0; i<3; i++) {
       for(int j=0; j<3-i; j++) {
           if(treps[j].time < treps[j+1].time) {
               SMTFReport temp = treps[j];
               treps[j] = treps[j+1];
               treps[j+1] = temp;
           }
       }
   }

   string penalty_text = "";
   int penalty = 0;

   // Sadece 4. En Eskiye Ceza Var (index 3)
   if (treps[3].time != 0) {
       int pen_4 = (treps[3].tf == PERIOD_H1) ? -15 : -10;
       penalty += pen_4;
       penalty_text += "4. En Eski (" + treps[3].tf_name + "): [" + IntegerToString(pen_4) + " Puan]\n";
   }

   total_points += penalty;

   string sup_text = "\n🛡️ DESTEKLEYİCİ YAPILAR & CEZALAR:\n";
   sup_text += h1_sup_text + m30_sup_text + m15_sup_text + m5_sup_text;
   if (penalty != 0) {
       sup_text += "⏱️ ZAMAN CEZALARI:\n" + penalty_text;
   }


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
       if (maj_extreme_i != last_broadcast_maj_extreme_i || is_test || maj_extreme_i == 0) {
           BroadcastTradeSignal(Symbol(), trigger_dir, entry_price, sl_price, tp_price, is_strong, total_points, is_test);
           last_broadcast_maj_extreme_i = maj_extreme_i;
       } else {
           order_details += "\n⚠️ UYARI: Bu dalgada zaten işleme girildi, tekrar girilmiyor! Sadece bildirim.";
       }
   }
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Puan Yetersiz)";


   string dir_str = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";

   string msg = "";
   if (is_test) msg = "🧪 [" + Symbol() + "] TEST ANALİZ RAPORU (Şu Anki Durum)\n";
   else msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\n";
   msg += "Yön: " + dir_str + " \n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\n" + m1_text + " ";
   msg += "📊 ZAMAN DİLİMİ ANALİZİ (Ana Yön H1: " + (t_h1==1?"⬆️":"⬇️") + "):\n";
   msg += "* " + h1_text;
   msg += "* " + m30_text;
   msg += "* " + m15_text;
   msg += "* " + m5_text + " ";
   msg += "🎯 İŞLEM MENZİLİ (M1 ve M3 Uyumu):\n" + range_text + " \n";
   msg += sup_text + "\n";
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
   msg1 += "- Yön: " + swing_dir + " ";
   msg1 += "- Başlangıç: " + swing_start_str + " ";
   msg1 += "  └ Süre: " + ago_str + " ";
   msg1 += "- Swing High: " + DoubleToString(h_m1, _Digits) + " ";
   msg1 += "- Swing Low: " + DoubleToString(l_m1, _Digits) + " ";
   msg1 += StringFormat("- Anlık Çekilme: %%%.2f\n", p_m1);
   msg1 += StringFormat("- Maks Çekilme: %%%.2f\n", mp_m1);
   if(p_m1 == 0 && mp_m1 == 0)
     {
      string temp_dir = (t_m1 == 1) ? "SELL" : "BUY";
      msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " ";
      msg1 += "⚠️ DİKKAT: Trend şişkin! M1 için kısa süreli düzeltme hareketi (" + temp_dir + ") fırsatı beklenebilir.\n\n";
     }
   else if(p_m1 <= 10.0 && mp_m1 <= 10.0)
     {
      msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Trend Şişkin, Düzeltme Bekleniyor)\n\n";
     }
   else
     {
      msg1 += "- Güncel Fiyat: " + DoubleToString(live_price, _Digits) + " (Çekilme: %" + DoubleToString(p_m1, 2) + " ↑↑%" + DoubleToString(mp_m1, 2) + ")\n\n";
     }

   msg1 += "🧭 MAKRO TREND (H1/M30)\n";
   msg1 += "Durum: " + (bull_pressure >= 50 ? "🟢 YÜKSELİŞ" : "🔴 DÜŞÜŞ") + " (%" + DoubleToString(bull_pressure, 0) + " Boğa Baskısı)\n";
   msg1 += "H1:  " + (t_h1 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_h1, mp_h1, (t_h1==1?tl_h1:th_h1), t) + " ";
   msg1 += "M30: " + (t_m30 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m30, mp_m30, (t_m30==1?tl_m30:th_m30), t) + " \n";

   msg1 += "🔬 DÜZELTME VE HEDEF (M15/M5)\n";
   msg1 += "M15: " + (t_m15 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m15, mp_m15, (t_m15==1?tl_m15:th_m15), t) + " ";
   msg1 += "M5:  " + (t_m5 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m5, mp_m5, (t_m5==1?tl_m5:th_m5), t) + " \n";

   msg1 += "🎯 TETİK VE ONAY GRUBU (M3/M1)\n";
   msg1 += "M3:  " + (t_m3 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m3, mp_m3, (t_m3==1?tl_m3:th_m3), t) + " ";
   msg1 += "M1:  " + (t_m1 == 1 ? "🟢 YUKARI " : "🔴 AŞAĞI  ") + PctToText(p_m1, mp_m1, (t_m1==1?tl_m1:th_m1), t) + " \n";

   msg1 += "📊 Baskınlık: Makro=↑%" + DoubleToString(macro_bull_pct, 0) + " ↓%" + DoubleToString(macro_bear_pct, 0) + " | Mikro=↑%" + DoubleToString(micro_bull_pct, 0) + " ↓%" + DoubleToString(micro_bear_pct, 0) + " ";
  bool macro_bull = (t_h1 == 1 && t_m30 == 1);
   bool macro_bear = (t_h1 == -1 && t_m30 == -1);

   string decision = "";
   string detail = "";
   string risk_advice = "";

   if (triggered_level == 1) { // %40-%60 Range (KIRILIM 1)
       if ((macro_bull && t_m1 == 1) || (!macro_bull && t_m1 == -1)) {
           decision = "🟡 ERKEN AŞAMA (KIRILIM 1)";
           detail = "Piyasa ana trend yönünde ilk yapısal kırılımı (CHoCH) gerçekleştirdi. Düzeltme henüz %60 sınırını geçmediği için taze bir momentum olabilir.";
           risk_advice = "🚨 İlk kırılımlar güçlü trend başlatabilir ancak scalp (kısa menzilli) kâr alma ihtimalini göz önünde bulundurun.";
       } else {
           decision = "🔴 TERS YÖNLÜ ERKEN KIRILIM";
           detail = "Fiyat ana trendin aksi yönünde ilk zayıf tepkisini verdi. Bu kırılım büyük ihtimalle bir düzeltme (pullback) başlatacak.";
           risk_advice = "🛑 Ana trende karşı olduğunuz için hacimli bir pozisyondan ziyade dar stoplu reaksiyon aranmalıdır.";
       }
   } else { // >= %60 Range (KIRILIM 2)
       if ((macro_bull && t_m1 == 1) || (!macro_bull && t_m1 == -1)) {
           decision = "🟢 GÜÇLÜ ONAY (KIRILIM 2)";
           detail = "Fiyat derin ve sağlıklı bir düzeltme (%60+) yaptıktan sonra tekrar ana trend yönüne oturdu. Uyum mükemmel.";
           risk_advice = "✅ En yüksek kazanma olasılığına sahip (High Probability) kurulumdur. Ana TP hedefine kadar takip edilebilir.";
       } else {
           decision = "🟡 DERİN DÜZELTME (Ters Yön)";
           detail = "Fiyat çok derin bir düzeltme (%60+) yapıyor. Ana trend henüz dönmese de ciddi bir geri çekilme yaşanıyor.";
           risk_advice = "⚠️ Tepki büyük. İşlem alınabilir ancak kâr hedefleri ana yapı dirençlerine göre (muhafazakar) belirlenmeli.";
       }
   }

   string msg2 = "";
   if(InpTestMode) msg2 = "🧪 [TEST MODU - " + Symbol() + "] BÖLÜM 2/2\n\n";
   else msg2 = "🚨 YAPI ONAYI BÖLÜM 2/2\n\n";

   msg2 += "🤖 PİYASA DURUMU:\n  " + decision + " \n";
   msg2 += "📝 YAPI ANALİZİ:\n  " + detail + " \n";
   msg2 += "⚠️ ALGORİTMİK SONUÇ:\n  " + risk_advice + " \n";


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

   // --- RETEST PUSU MOTORU (Sadece Canlı Piyasada) ---
   if (!is_history && g_pending_active && i > g_pending_bar_i) {
       // Zaman Aşımı (Max Bars)
       if (i - g_pending_bar_i > InpRetestMaxBars) {
           g_pending_active = false;
       } else {
           // Emir Tetiklendi mi?
           bool executed = false;
           if (g_pending_dir == 1 && val_l <= g_pending_entry) executed = true;
           if (g_pending_dir == -1 && val_h >= g_pending_entry) executed = true;

           if (executed) {
               EvaluateTradeSignal(i, time[i], g_pending_entry, g_pending_dir, g_pending_p_pct, g_pending_is_strong, g_pending_sl, g_pending_maj_extreme_i);
               g_pending_active = false; // Pusu tamamlandı, emir gönderildi.
           }
       }
   }

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
         if(draw_ui && InpShowMin)
           {
            string name = GetUniqueName(prefix + "Minor_");
            DrawLine(name, GetTimeSafe(time, state.lp_i), state.lp_p, GetTimeSafe(time, state.min_h_i), state.min_h, InpColorMin, 1, STYLE_SOLID);
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
         if(InpShowMin)
           {
            string name = GetUniqueName(prefix + "Minor_");
            DrawLine(name, GetTimeSafe(time, state.lp_i), state.lp_p, GetTimeSafe(time, state.min_l_i), state.min_l, InpColorMin, 1, STYLE_SOLID);
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
          bool is_strong = (state.t2_h > state.t1_h); // T2 sweeps T1's high

          if (!is_history) {
              string msg = "🔴 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\n";
              msg += "Yön: ⬇️ AŞAĞI\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.";
              }

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {
                  if (InpEnableAlertCHoCHBase) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, p_pct, is_strong);
                  }
                  last_alert_d1_i_bear = state.d1_i;
              }
          }

          if (InpShowChoch) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              // 1. Draw the minor structure path (T1 -> D1 -> T2 -> Signal Point)
              string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_h, GetTimeSafe(time, state.d1_i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

              string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_l, GetTimeSafe(time, state.t2_i), state.t2_h, InpColorChochPath, 1, STYLE_DOT, false);

              string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_h, GetTimeSafe(time, i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, GetTimeSafe(time, i), state.d1_l, GetTimeSafe(time, i) + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);
          }
          state.choch_dir = 0; // Reset after trigger
      }
   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h && in_pullback_zone) {
          // Bullish CHoCH confirmed!
          bool is_strong = (state.t2_l < state.t1_l); // T2 sweeps T1's low

          if (!is_history) {
              string msg = "🟢 [" + Symbol() + "] M1 Trend Döndü! (CHoCH)\n";
              msg += "Yön: ⬆️ YUKARI\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.";
              }

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {
                  if (InpEnableAlertCHoCHBase) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution) {
                      EvaluateTradeSignal(i, time[i], val_c, 1, p_pct, is_strong);
                  }
                  last_alert_d1_i_bull = state.d1_i;
              }
          }

          if (InpShowChoch) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              // 1. Draw the minor structure path (T1 -> D1 -> T2 -> Signal Point)
              string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_l, GetTimeSafe(time, state.d1_i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

              string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_h, GetTimeSafe(time, state.t2_i), state.t2_l, InpColorChochPath, 1, STYLE_DOT, false);

              string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_l, GetTimeSafe(time, i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, GetTimeSafe(time, i), state.d1_h, GetTimeSafe(time, i) + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);
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
            if(draw_ui && InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, GetTimeSafe(time, state.anc_i), state.anc_v, GetTimeSafe(time, state.tmp_h_i), state.maj_h, InpColorBull, 2, STYLE_SOLID);
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

            if(draw_ui && InpShowMaj)
              {
               state.cur_top_line = GetUniqueName(prefix + "HLine_Top_");
               DrawLine(state.cur_top_line, GetTimeSafe(time, state.maj_h_i), state.maj_h, GetTimeSafe(time, i) + PeriodSeconds(), state.maj_h, InpColorBull, 1, STYLE_DASH, true);

               if(state.maj_l != EMPTY_VALUE && state.maj_l != 0)
                 {
                  state.cur_bot_line = GetUniqueName(prefix + "HLine_Bot_");
                  DrawLine(state.cur_bot_line, GetTimeSafe(time, state.maj_l_i), state.maj_l, GetTimeSafe(time, i) + PeriodSeconds(), state.maj_l, InpColorBull, 1, STYLE_DASH, true);
                 }
              }
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l)
           {
            state.maj_l = val_l;
            if(draw_ui && InpShowMaj)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1;
            state.maj_st = 0;
            state.bos_i = i;
            if(draw_ui && InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, GetTimeSafe(time, state.anc_i), state.anc_v, GetTimeSafe(time, state.tmp_h_i), state.tmp_h, InpColorBull, 2, STYLE_SOLID);
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
            if(draw_ui && InpShowMaj)
               UpdateLineLevel(state.cur_top_line, state.maj_h);
           }

         if(val_c > state.maj_h)
           {
            state.bos_i = i;
            state.maj_l = state.tmp_l;
            state.maj_l_i = state.tmp_l_i;
            if(draw_ui && InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, GetTimeSafe(time, state.anc_i), state.anc_v, GetTimeSafe(time, state.tmp_l_i), state.maj_l, InpColorBull, 2, STYLE_SOLID);
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
            if(draw_ui && InpShowMaj)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1;
            state.maj_st = 0;
            state.bos_i = i;
            if(draw_ui && InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, GetTimeSafe(time, state.anc_i), state.anc_v, GetTimeSafe(time, state.tmp_h_i), state.tmp_h, InpColorBull, 2, STYLE_SOLID);
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
            if(draw_ui && InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, GetTimeSafe(time, state.anc_i), state.anc_v, GetTimeSafe(time, state.tmp_l_i), state.maj_l, InpColorBear, 2, STYLE_SOLID);
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

            if(draw_ui && InpShowMaj)
              {
               state.cur_bot_line = GetUniqueName(prefix + "HLine_Bot_");
               DrawLine(state.cur_bot_line, GetTimeSafe(time, state.maj_l_i), state.maj_l, GetTimeSafe(time, i) + PeriodSeconds(), state.maj_l, InpColorBear, 1, STYLE_DASH, true);

               if(state.maj_h != EMPTY_VALUE && state.maj_h != 0)
                 {
                  state.cur_top_line = GetUniqueName(prefix + "HLine_Top_");
                  DrawLine(state.cur_top_line, GetTimeSafe(time, state.maj_h_i), state.maj_h, GetTimeSafe(time, i) + PeriodSeconds(), state.maj_h, InpColorBear, 1, STYLE_DASH, true);
                 }
              }
           }

         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h)
           {
            state.maj_h = val_h;
            if(draw_ui && InpShowMaj)
               UpdateLineLevel(state.cur_top_line, state.maj_h);
           }

         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.maj_tr = 1;
            state.maj_st = 0;
            state.bos_i = i;
            if(draw_ui && InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, GetTimeSafe(time, state.anc_i), state.anc_v, GetTimeSafe(time, state.tmp_l_i), state.tmp_l, InpColorBear, 2, STYLE_SOLID);
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
            if(draw_ui && InpShowMaj)
               UpdateLineLevel(state.cur_bot_line, state.maj_l);
           }

         if(val_c < state.maj_l)
           {
            state.maj_h = state.tmp_h;
            state.bos_i = i;
            state.maj_h_i = state.tmp_h_i;
            if(draw_ui && InpShowMaj)
              {
               string name = GetUniqueName(prefix + "Major_");
               DrawLine(name, GetTimeSafe(time, state.anc_i), state.anc_v, GetTimeSafe(time, state.tmp_h_i), state.maj_h, InpColorBear, 2, STYLE_SOLID);
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
            if(draw_ui && InpShowMaj)
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

void UpdateLiveDashboard()
  {
   datetime t = TimeCurrent();
   double live_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double h_m1=0, l_m1=0, h_m3=0, l_m3=0, h_m5=0, l_m5=0, h_m15=0, l_m15=0, h_m30=0, l_m30=0, h_h1=0, l_h1=0;
   datetime dmy_th, dmy_tl, th_m15, tl_m15, th_m30, tl_m30;

   GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, h_m1, l_m1, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, h_m3, l_m3, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M5, t_m5, p_m5, mp_m5, t, h_m5, l_m5, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, h_m15, l_m15, th_m15, tl_m15);
   GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, h_m30, l_m30, th_m30, tl_m30);
   GetMTFPullback(PERIOD_H1, t_h1, p_h1, mp_h1, t, h_h1, l_h1, dmy_th, dmy_tl);

   if (h_h1 == 0 || h_m30 == 0 || h_m15 == 0) {
       Comment("⏳ Arka Plandaki Zaman Dilimleri (H1, M30, vb.) İndiriliyor... Lütfen Bekleyin.");
       return;
   }

   string txt = "--- CANLI MTF ÇEKİLME TAKİBİ ---\n";
   txt += GenerateMTFString("M1 ", t_m1, h_m1, l_m1, p_m1, mp_m1);
   txt += GenerateMTFString("M3 ", t_m3, h_m3, l_m3, p_m3, mp_m3);
   txt += GenerateMTFString("M5 ", t_m5, h_m5, l_m5, p_m5, mp_m5);
   txt += GenerateMTFString("M15", t_m15, h_m15, l_m15, p_m15, mp_m15);
   txt += GenerateMTFString("M30", t_m30, h_m30, l_m30, p_m30, mp_m30);
   txt += GenerateMTFString("H1 ", t_h1, h_h1, l_h1, p_h1, mp_h1);

   string range_text = (t_m1 == t_m3 && t_m1 != 0) ? "🚀 UZUN MENZİL (Trend Takibi)" : "⚠️ KISA SÜRECEK (Scalp/Tepki)";
   txt += " 🎯 İşlem Beklentisi: " + range_text;

   Comment(txt);
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

   int limit;





   static datetime last_calc_time = 0;
   int virtual_prev = prev_calculated;

   if (prev_calculated == 0 && last_calc_time == time[rates_total - 1]) {
       virtual_prev = rates_total - 1; // Hafıza Koruması (Wipe Bug Fix)
   }

   static bool last_test_state = false;
   if (InpTestMTFChochReport && !last_test_state) {
       GenerateMTFChochReport();
   }
   last_test_state = InpTestMTFChochReport;

   if(virtual_prev == 0)
     {
      last_calc_time = time[rates_total - 1];

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

      // TEST TRIGGER
      if (InpTestTradeExecution) {
          int live_tr = 0; double live_pct = 0; double mp_pct = 0;
          double dh, dl; datetime dth, dtl;
          GetMTFPullback(PERIOD_M1, live_tr, live_pct, mp_pct, TimeCurrent(), dh, dl, dth, dtl);

          // Test varsayımı: Ana yön H1'in trend yönüne (g_state_hist.maj_tr) göre bir kırılım (CHoCH) geldiğini farz ediyoruz.
          int test_dir = (live_tr != 0) ? live_tr : 1; // Default to buy if unknown


          // EvaluateTradeSignal param format: current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, bool is_test
          double dummy_ext = (test_dir == 1) ? SymbolInfoDouble(Symbol(), SYMBOL_BID) - 50*Point() : SymbolInfoDouble(Symbol(), SYMBOL_BID) + 50*Point();
          EvaluateTradeSignal(rates_total-1, TimeCurrent(), SymbolInfoDouble(Symbol(), SYMBOL_BID), test_dir, live_pct, true, dummy_ext, 0, true);
      }
     }
   else
     {
      limit = virtual_prev - 1;
     }

   if (virtual_prev == 0 && limit < rates_total) {
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

         if(InpEnableAlertMTFLevels && (trig1 || trig2 || InpTestMode))
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


   static uint last_dash_update = 0;
   uint now_tick = GetTickCount();
   if(now_tick - last_dash_update > 1000) {
       UpdateLiveDashboard();
       last_dash_update = now_tick;
   }

   return(rates_total);
}
