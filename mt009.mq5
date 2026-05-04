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


//--- Hafıza Değişkenleri (Çoklu İşlem Takibi 1-5) ---
// Düşüş (Bearish) işlemleri için
double g_trade_t1_h[5];
double g_trade_t2_h[5];
int    g_trade_count_h = 0;
int    g_current_maj_h_i = 0;

// Yükseliş (Bullish) işlemleri için
double g_trade_t1_l[5];
double g_trade_t2_l[5];
int    g_trade_count_l = 0;
int    g_current_maj_l_i = 0;

void ResetBearishMemory() {
    g_trade_count_h = 0;
    for(int i=0; i<5; i++) { g_trade_t1_h[i] = 0; g_trade_t2_h[i] = 0; }
}

void ResetBullishMemory() {
    g_trade_count_l = 0;
    for(int i=0; i<5; i++) { g_trade_t1_l[i] = 0; g_trade_t2_l[i] = 0; }
}

//--- CHoCH Settings ---
input group "--- TRADE EXECUTION & RISK ---"
input bool   InpEnableTradeExecution   = true;        // Master->Slave Sinyal Köprüsü Aktif
input bool   InpFirstTradeEnable       = true;        // 1. İşlem Aktif
input bool   InpSecondTradeEnable      = true;        // 2. İşlem Aktif
input bool   InpThirdTradeEnable       = false;       // 3. İşlem Aktif
input bool   InpFourthTradeEnable      = false;       // 4. İşlem Aktif
input bool   InpFifthTradeEnable       = false;       // 5. İşlem Aktif
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
input double InpMinPullbackPct = 40.0;         // CHoCH Min Çekilme % (Onay Yüzdeliği)
input double InpMaxPullbackPct = 100.0;        // CHoCH Max Çekilme % (İşlem Yüzdeliği)
input color  InpColorChochStrong = clrPurple;  // Güçlü CHoCH (Mor)
input color  InpColorChochWeak   = clrRed;     // Güçsuz CHoCH (Kırmızı)
input color  InpColorChochPath   = clrGray;    // Yapı İzi (Gri)
input bool   InpShowChoch      = true;         // CHoCH Çizgilerini Göster

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
bool g_is_full_reload = true;

// --- BASTIRILAN CHoCH SİGNALİ KAYIT STRUCT ---
struct SLastChoch {
    bool   drawn;
    int    dir;
    double d1_level;
    double sl;
    int    maj_i;
    double ppct;
    bool   is_strong;
    bool   is_subsequent;
    int    trade_num;
};
SLastChoch g_last_drawn_choch;

datetime GetTimeSafe(const datetime &time_array[], int idx)
  {
   if(idx >= 0 && idx < ArraySize(time_array))
     {
      return time_array[idx];
     }
   return 0;
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
bool   g_pending_is_second_trade = false;
int    g_pending_maj_extreme_i = 0;
int    g_pending_trade_num = 1;
double g_pending_choch_level = 0.0;

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

      datetime start_time = (trend == 1) ? ref_t_h : ref_t_l;
      if (start_time == 0) start_time = current_time - (3600 * 24);

      int m1_copied = CopyRates(Symbol(), PERIOD_M1, start_time, current_time, rates);
      double precise_tmp_l = st.tmp_l;
      double precise_tmp_h = st.tmp_h;

      if(m1_copied > 0) {
          int best_i = 0;
          double best_v = (trend == 1) ? 0.0 : 9999999.0;

          for(int k=0; k<m1_copied; k++) {
              if(trend == 1 && rates[k].high > best_v) { best_v = rates[k].high; best_i = k; }
              if(trend == -1 && rates[k].low < best_v) { best_v = rates[k].low; best_i = k; }
          }

          double ext_val = live_p;
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



//+------------------------------------------------------------------+
//| CHoCH Test - EvaluateTradeSignal ile birebir aynı tek bildirim  |
//+------------------------------------------------------------------+
void TestCHoCHSignal()
  {
   double live_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   datetime t = TimeCurrent();

   int test_dir = (g_state_hist.last_choch_dir != 0) ? g_state_hist.last_choch_dir : g_state_hist.maj_tr;
   if(test_dir == 0) test_dir = 1;

   bool   is_strong   = false;
   double sl_level    = 0;
   double choch_level = 0;
   int    trade_num   = 1;

   if(test_dir == -1)
     {
      sl_level    = (g_state_hist.t2_h != 0) ? g_state_hist.t2_h : g_state_hist.maj_h;
      choch_level = (g_state_hist.d1_l != 0) ? g_state_hist.d1_l : live_price;
      is_strong   = (g_state_hist.t2_h > g_state_hist.t1_h);
      trade_num   = (g_trade_count_h > 0) ? g_trade_count_h : 1;
     }
   else
     {
      sl_level    = (g_state_hist.t2_l != 0) ? g_state_hist.t2_l : g_state_hist.maj_l;
      choch_level = (g_state_hist.d1_h != 0) ? g_state_hist.d1_h : live_price;
      is_strong   = (g_state_hist.t2_l < g_state_hist.t1_l);
      trade_num   = (g_trade_count_l > 0) ? g_trade_count_l : 1;
     }

   if(sl_level == 0)
      sl_level = (test_dir == 1) ? live_price - 50*_Point : live_price + 50*_Point;

   int maj_extreme_i = (test_dir == -1) ? g_state_hist.maj_h_i : g_state_hist.maj_l_i;

   double p_pct = 0;
   if(g_state_hist.maj_h != 0 && g_state_hist.maj_l != 0 && g_state_hist.maj_h != g_state_hist.maj_l)
     {
      double range = g_state_hist.maj_h - g_state_hist.maj_l;
      if(test_dir == -1) p_pct = ((g_state_hist.maj_h - live_price) / range) * 100.0;
      else               p_pct = ((live_price - g_state_hist.maj_l) / range) * 100.0;
      if(p_pct < 0)   p_pct = 0;
      if(p_pct > 100) p_pct = 100;
     }

   EvaluateTradeSignal(0, t, live_price, test_dir, p_pct, is_strong,
                       sl_level, maj_extreme_i, false, true, trade_num, choch_level);
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
    json += "  \"base_extreme\": " + DoubleToString(sl, _Digits) + ",\n";
    json += "  \"is_strong\": " + is_strong_str + ",\n";
    json += "  \"score\": " + IntegerToString(score) + ",\n";
    json += "  \"is_test\": " + is_test_str + ",\n";
    json += "  \"risk_usd\": " + DoubleToString(InpRiskUSD, 2) + "\n";
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

void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, double minor_extreme_sl, int maj_extreme_i, bool is_second_trade = false, bool is_test = false, int trade_number = 1, double choch_level = 0)
  {
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

   int total_points = 0;
   string h1_text = "";
   string m30_text = "";
   string m15_text = "";
   string m5_text = "";
   string m1_text = "";

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

   // ── MTF CHoCH geçerlilik ikonları ──
   string choch_icon_m1, choch_icon_h1, choch_icon_m30, choch_icon_m15, choch_icon_m5;
   {
    double live_p = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    datetime _ct; int _cd; double _cl;

    _cd=0; _cl=0; _ct=0;
    GetMTFChochDetails(PERIOD_M1, t, _cd, _cl, _ct);
    if(_ct==0)                          choch_icon_m1="❄️";
    else if(_cd==-1 && live_p<_cl)     choch_icon_m1="⬇️";
    else if(_cd== 1 && live_p>_cl)     choch_icon_m1="⬆️";
    else                                choch_icon_m1="❌";

    _cd=0; _cl=0; _ct=0;
    GetMTFChochDetails(PERIOD_H1, t, _cd, _cl, _ct);
    if(_ct==0)                          choch_icon_h1="❄️";
    else if(_cd==-1 && live_p<_cl)     choch_icon_h1="⬇️";
    else if(_cd== 1 && live_p>_cl)     choch_icon_h1="⬆️";
    else                                choch_icon_h1="❌";

    _cd=0; _cl=0; _ct=0;
    GetMTFChochDetails(PERIOD_M30, t, _cd, _cl, _ct);
    if(_ct==0)                          choch_icon_m30="❄️";
    else if(_cd==-1 && live_p<_cl)     choch_icon_m30="⬇️";
    else if(_cd== 1 && live_p>_cl)     choch_icon_m30="⬆️";
    else                                choch_icon_m30="❌";

    _cd=0; _cl=0; _ct=0;
    GetMTFChochDetails(PERIOD_M15, t, _cd, _cl, _ct);
    if(_ct==0)                          choch_icon_m15="❄️";
    else if(_cd==-1 && live_p<_cl)     choch_icon_m15="⬇️";
    else if(_cd== 1 && live_p>_cl)     choch_icon_m15="⬆️";
    else                                choch_icon_m15="❌";

    _cd=0; _cl=0; _ct=0;
    GetMTFChochDetails(PERIOD_M5, t, _cd, _cl, _ct);
    if(_ct==0)                          choch_icon_m5="❄️";
    else if(_cd==-1 && live_p<_cl)     choch_icon_m5="⬇️";
    else if(_cd== 1 && live_p>_cl)     choch_icon_m5="⬆️";
    else                                choch_icon_m5="❌";
   }

   // ── Push bildirimi için kısa açıklama satırları ──
   string push_m1, push_h1, push_m30, push_m15, push_m5;
   {
    string d; double mom;
    d = (t_m1==1)?"🟢":"🔴";
    push_m1  = d + " Çek:%" + DoubleToString(p_m1,1) + " Mom:%" + DoubleToString(mp_m1,1)
             + "\n  → " + (is_strong?"Likidite✅":"Likidite❌") + " [+" + IntegerToString(m1_points) + "]";
    d = (t_h1==1)?"🟢":"🔴"; mom = mp_h1 - p_h1;
    string h1_tag;
    if(mom>=20 && t_h1==trigger_dir)       h1_tag="Uyumlu+ÇokSert";
    else if(mom>=15 && t_h1==trigger_dir)  h1_tag="Uyumlu+Sert";
    else if(mom>=15)                        h1_tag="Karşı+Sert";
    else if(t_h1==trigger_dir && p_h1>=50) h1_tag="Uyumlu+İdeal";
    else if(t_h1==trigger_dir)             h1_tag="Uyumlu+Şişkin";
    else if(p_h1>=50)                      h1_tag="Karşı+İdeal";
    else                                    h1_tag="Karşı+Şişkin";
    push_h1  = d + " Çek:%" + DoubleToString(p_h1,1) + " Mom:%" + DoubleToString(mom,1)
             + "\n  → " + h1_tag + " [+" + IntegerToString(h1_points) + "]";
    d = (t_m30==1)?"🟢":"🔴"; mom = mp_m30 - p_m30;
    string m30_tag;
    bool clone30 = (MathAbs(h_m30-h_h1)<Point()*5 && MathAbs(l_m30-l_h1)<Point()*5);
    if(clone30)                               m30_tag="H1 Klonu";
    else if(mom>=20 && t_m30==trigger_dir)    m30_tag="Uyumlu+ÇokSert";
    else if(mom>=15 && t_m30==trigger_dir)    m30_tag="Uyumlu+Sert";
    else if(mom>=15)                           m30_tag="Karşı+Sert";
    else if(t_m30==trigger_dir && p_m30>=50)  m30_tag="Uyumlu+İdeal";
    else if(t_m30==trigger_dir)               m30_tag="Uyumlu+Şişkin";
    else                                       m30_tag="Karşı+Sakin";
    push_m30 = d + " Çek:%" + DoubleToString(p_m30,1) + " Mom:%" + DoubleToString(mom,1)
             + "\n  → " + m30_tag + " [+" + IntegerToString(m30_points) + "]";
    d = (t_m15==1)?"🟢":"🔴"; mom = mp_m15 - p_m15;
    string m15_tag;
    bool clone15 = (MathAbs(h_m15-h_m30)<Point()*5 && MathAbs(l_m15-l_m30)<Point()*5);
    if(clone15)                               m15_tag="M30 Klonu";
    else if(mom>=20 && t_m15==trigger_dir)    m15_tag="Uyumlu+ÇokSert";
    else if(mom>=15 && t_m15==trigger_dir)    m15_tag="Uyumlu+Sert";
    else if(mom>=15)                           m15_tag="Karşı+Sert";
    else if(t_m15==trigger_dir && p_m15>=50)  m15_tag="Uyumlu+İdeal";
    else if(t_m15==trigger_dir)               m15_tag="Uyumlu+Şişkin";
    else                                       m15_tag="Karşı+Sakin";
    push_m15 = d + " Çek:%" + DoubleToString(p_m15,1) + " Mom:%" + DoubleToString(mom,1)
             + "\n  → " + m15_tag + " [+" + IntegerToString(m15_points) + "]";
    d = (t_m5==1)?"🟢":"🔴"; mom = mp_m5 - p_m5;
    string m5_tag;
    bool clone5 = (MathAbs(h_m5-h_m15)<Point()*5 && MathAbs(l_m5-l_m15)<Point()*5);
    if(clone5)                               m5_tag="M15 Klonu";
    else if(mom>=20 && t_m5==trigger_dir)    m5_tag="Uyumlu+ÇokSert";
    else if(mom>=15 && t_m5==trigger_dir)    m5_tag="Uyumlu+Sert";
    else if(mom>=15)                          m5_tag="Karşı+Sert";
    else if(t_m5==trigger_dir && p_m5>=50)   m5_tag="Uyumlu+İdeal";
    else if(t_m5==trigger_dir)               m5_tag="Uyumlu+Şişkin";
    else                                      m5_tag="Karşı+Sakin";
    push_m5  = d + " Çek:%" + DoubleToString(p_m5,1) + " Mom:%" + DoubleToString(mom,1)
             + "\n  → " + m5_tag + " [+" + IntegerToString(m5_points) + "]";
   }


   string order_details = "";
   string range_text = (t_m1 == t_m3) ? "🚀 BEKLENTİ: UZUN MENZİL (Trend Takibi)" : "⚠️ BEKLENTİ: KISA SÜRECEK (Scalp/Tepki)";

   string lvl_text = "BİLİNMİYOR";
   if (p_pct >= 40.0 && p_pct < 60.0) lvl_text = "KIRILIM 1 (Erken Seviye)";
   if (p_pct >= 60.0) lvl_text = "KIRILIM 2 (Ana Seviye)";

   string verdict = "";

   if (total_points >= InpMinTradeScoreLimit) {
       verdict = "✅ İŞLEME GİRİLEBİLİR (Yüksek Olasılıklı Kurulum)";

       double sl_price = minor_extreme_sl;
       double entry_price = live_price;
       double sl_dist = MathAbs(entry_price - minor_extreme_sl);

       if (is_strong) sl_dist *= InpStrongSLMultiplier;
       else           sl_dist *= InpWeakSLMultiplier;

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

       double tp_dist = sl_dist * 3.0;
       double tp_price = (trigger_dir == 1) ? (entry_price + tp_dist) : (entry_price - tp_dist);

       order_details = "   📊 HESAPLANAN HEDEFLER (Sinyal Köprüsü):\n";
       order_details += "Giriş: " + DoubleToString(entry_price, _Digits) + " ";
       order_details += "Zarar Durdur (SL): " + DoubleToString(sl_price, _Digits) + " (" + DoubleToString(sl_dist/_Point, 0) + " points)" + sl_note + " ";
       order_details += "Kâr Al (TP 3R): " + DoubleToString(tp_price, _Digits) + " (" + DoubleToString(tp_dist/_Point, 0) + " points)\n";

       static int last_broadcast_maj_extreme_i = -1;
       static int last_broadcast_trade_num     = -1;
       bool allow_broadcast = (maj_extreme_i != last_broadcast_maj_extreme_i)
                           || (trade_number != last_broadcast_trade_num)
                           || (is_test)
                           || (maj_extreme_i == 0);

       if (allow_broadcast) {
           BroadcastTradeSignal(Symbol(), trigger_dir, entry_price, sl_price, tp_price, is_strong, total_points, is_test);
           last_broadcast_maj_extreme_i = maj_extreme_i;
           last_broadcast_trade_num     = trade_number;
       } else {
           order_details += "\n⚠️ UYARI: Bu dalgada zaten işleme girildi, tekrar girilmiyor! Sadece bildirim.";
       }
   }
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Puan Yetersiz)";


   string dir_str  = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";
   string dir_emoji = (trigger_dir == 1) ? "🟢" : "🔴";
   string dir_side  = (trigger_dir == 1) ? "ALIŞ" : "SATIŞ";
   string str_tag   = is_strong ? "💪 GÜÇLÜ" : "⚠️ ZAYIF";
   string choch_header = dir_emoji + " [" + Symbol() + "] CHoCH " + dir_side
                       + " #" + IntegerToString(trade_number)
                       + " | " + str_tag
                       + " | Seviye: " + (choch_level != 0 ? DoubleToString(choch_level, _Digits) : DoubleToString(live_price, _Digits));
   if(is_test) choch_header = "🧪 [TEST] " + choch_header;

   string msg = choch_header + "\n";
   msg += "Yön: " + dir_str + " \n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\n" + m1_text + " ";
   msg += "📊 ZAMAN DİLİMİ ANALİZİ (Ana Yön H1: " + (t_h1==1?"⬆️":"⬇️") + "):\n";
   msg += "* " + h1_text;
   msg += "* " + m30_text;
   msg += "* " + m15_text;
   msg += "* " + m5_text + " ";
   msg += "🎯 İŞLEM MENZİLİ (M1 ve M3 Uyumu):\n" + range_text + " \n";

   msg += "📈 TOPLAM İŞLEM SKORU:\n";
   msg += "Hesaplanan: " + IntegerToString(total_points) + " Puan (Gerekli Baraj: " + IntegerToString(InpMinTradeScoreLimit) + " Puan)\n";
   msg += "KARAR: " + verdict;
   msg += order_details;

   if (total_points >= InpMinTradeScoreLimit || InpAlertRejectedTrades) {
       if(InpAlertPopup) Alert(msg);
       if(InpAlertPush) {
           string push_msg = choch_header + "\n\n"
               + "M5"  + choch_icon_m5  + ": " + push_m5  + "\n\n"
               + "M15" + choch_icon_m15 + ": " + push_m15 + "\n\n"
               + "📈 " + IntegerToString(total_points) + "/" + IntegerToString(InpMinTradeScoreLimit) + " | " + verdict;
           if(total_points >= InpMinTradeScoreLimit && choch_level != 0) {
               double sl_dist  = MathAbs(live_price - minor_extreme_sl);
               if(is_strong) sl_dist *= InpStrongSLMultiplier; else sl_dist *= InpWeakSLMultiplier;
               double sl_final = (trigger_dir == 1) ? live_price - sl_dist : live_price + sl_dist;
               double tp_final = (trigger_dir == 1) ? live_price + sl_dist*3 : live_price - sl_dist*3;
               push_msg += "\nGiriş:" + DoubleToString(live_price, _Digits)
                         + " SL:" + DoubleToString(sl_final, _Digits)
                         + " TP:" + DoubleToString(tp_final, _Digits);
           }
           SendNotification(push_msg);
       }
   }
  }

//+------------------------------------------------------------------+
//| MTF Alert System                                                 |
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

   int macro_score = 0;
   if(t_h1 == 1) macro_score += 5; else macro_score -= 5;
   if(t_m30 == 1) macro_score += 4; else macro_score -= 4;
   if(t_m15 == 1) macro_score += 3; else macro_score -= 3;

   double macro_bull_pct = ((macro_score + 12.0) / 24.0) * 100.0;
   double macro_bear_pct = 100.0 - macro_bull_pct;

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

   if (triggered_level == 1) {
       if ((macro_bull && t_m1 == 1) || (!macro_bull && t_m1 == -1)) {
           decision = "🟡 ERKEN AŞAMA (KIRILIM 1)";
           detail = "Piyasa ana trend yönünde ilk yapısal kırılımı (CHoCH) gerçekleştirdi. Düzeltme henüz %60 sınırını geçmediği için taze bir momentum olabilir.";
           risk_advice = "🚨 İlk kırılımlar güçlü trend başlatabilir ancak scalp (kısa menzilli) kâr alma ihtimalini göz önünde bulundurun.";
       } else {
           decision = "🔴 TERS YÖNLÜ ERKEN KIRILIM";
           detail = "Fiyat ana trendin aksi yönünde ilk zayıf tepkisini verdi. Bu kırılım büyük ihtimalle bir düzeltme (pullback) başlatacak.";
           risk_advice = "🛑 Ana trende karşı olduğunuz için hacimli bir pozisyondan ziyade dar stoplu reaksiyon aranmalıdır.";
       }
   } else {
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
   ObjectsDeleteAll(0, "CHoCH_Text_");
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
       if (i - g_pending_bar_i > InpRetestMaxBars) {
           g_pending_active = false;
       } else {
           bool executed = false;
           if (g_pending_dir == 1 && val_l <= g_pending_entry) executed = true;
           if (g_pending_dir == -1 && val_h >= g_pending_entry) executed = true;

           if (executed) {
               EvaluateTradeSignal(i, time[i], g_pending_entry, g_pending_dir, g_pending_p_pct, g_pending_is_strong, g_pending_sl, g_pending_maj_extreme_i, g_pending_is_second_trade, false, g_pending_trade_num, g_pending_choch_level);
               g_pending_active = false;
           }
       }
   }

   // CHoCH & T1-D1-T2 TRACKING LOGIC
   double cur_maj_h = state.maj_h;
   double cur_maj_l = state.maj_l;
   double p_pct = 0;

   if (cur_maj_h != EMPTY_VALUE && cur_maj_l != EMPTY_VALUE && cur_maj_h != cur_maj_l) {
      double range = cur_maj_h - cur_maj_l;
      if (state.maj_tr == 1) {
         if (state.min_l >= cur_maj_l) {
             p_pct = ((cur_maj_h - state.min_l) / range) * 100.0;
         }
      } else if (state.maj_tr == -1) {
         if (state.min_h <= cur_maj_h) {
             p_pct = ((state.min_h - cur_maj_l) / range) * 100.0;
         }
      }
   }

   bool in_pullback_zone = (p_pct >= InpMinPullbackPct);

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
             state.choch_dir = 0;
         }
         if (state.choch_dir == 1 && state.t2_l != 0 && state.min_h <= state.d1_h) {
             state.choch_dir = 0;
         }

         // CHoCH Bearish sequence tracking
         if (state.maj_tr == -1 && in_pullback_zone) {
             if (state.choch_dir == 0 || state.choch_dir == 1) {
                 state.t1_h = state.min_h;
                 state.t1_l = state.min_l;
                 state.t1_i = state.min_h_i;
                 state.d1_h = 0; state.d1_l = 0; state.d1_i = 0;
                 state.t2_h = 0; state.t2_l = 0; state.t2_i = 0;
                 state.choch_dir = -1;
             } else if (state.choch_dir == -1) {
                 if (state.d1_l == 0) {
                     state.d1_l = state.min_l;
                     state.d1_i = state.min_l_i;
                 }
                 if (state.d1_l != 0 && state.t2_h == 0) {
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
         if(draw_ui && InpShowMin)
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
             state.choch_dir = 0;
         }
         if (state.choch_dir == -1 && state.t2_h != 0 && state.min_l >= state.d1_l) {
             state.choch_dir = 0;
         }

         // CHoCH Bullish sequence tracking
         if (state.maj_tr == 1 && in_pullback_zone) {
             if (state.choch_dir == 0 || state.choch_dir == -1) {
                 state.t1_l = state.min_l;
                 state.t1_h = state.min_h;
                 state.t1_i = state.min_l_i;
                 state.d1_l = 0; state.d1_h = 0; state.d1_i = 0;
                 state.t2_l = 0; state.t2_h = 0; state.t2_i = 0;
                 state.choch_dir = 1;
             } else if (state.choch_dir == 1) {
                 if (state.d1_h == 0) {
                     state.d1_h = state.min_h;
                     state.d1_i = state.min_h_i;
                 }
                 if (state.d1_h != 0 && state.t2_l == 0) {
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

   // ================================================================
   // CHoCH Trigger & Drawing Logic
   // ================================================================

   // --- BEARISH CHoCH ---
   if (state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0) {

      double range = state.maj_h - state.maj_l;
      double level_40_bear = state.maj_l + range * (InpMinPullbackPct / 100.0);
      bool t2_valid = (range > 0 && state.d1_l >= level_40_bear && state.t2_h >= level_40_bear);

      int r_total = ArraySize(close);
      bool is_just_closed = (i == r_total - 2);
      bool should_eval_bear = (val_c < state.d1_l);

      if (should_eval_bear) {
          if (!t2_valid) {
              state.choch_dir = 0;
              state.d1_l = 0;
              state.t2_h = 0;
          } else {
          state.last_choch_dir = -1;
          state.last_choch_level = state.d1_l;
          state.last_choch_time = time[i];

          bool is_strong = (state.t2_h > state.t1_h);

          int current_trade_index = -1;

          if (draw_ui) {
              static int last_alert_d1_i_bear = 0;
              static int last_alert_maj_i_bear = 0;

              if (state.maj_h_i != g_current_maj_h_i) {
                  ResetBearishMemory();
                  g_current_maj_h_i = state.maj_h_i;
              }

              bool is_new_signal = (state.d1_i != last_alert_d1_i_bear);
              bool valid_sequence = false;

              if (g_trade_count_h == 0) {
                  valid_sequence = true;
              } else if (g_trade_count_h > 0 && g_trade_count_h < 5) {
                  int prev_i = g_trade_count_h - 1;
                  double prev_peak = MathMax(g_trade_t1_h[prev_i], g_trade_t2_h[prev_i]);
                  if (state.t2_h > prev_peak) {
                      valid_sequence = true;
                  }
              }

              if (is_new_signal) {
                  if (valid_sequence && g_trade_count_h < 5) {
                      current_trade_index = g_trade_count_h;
                      g_trade_t1_h[current_trade_index] = state.t1_h;
                      g_trade_t2_h[current_trade_index] = state.t2_h;
                      g_trade_count_h++;
                  } else {
                      current_trade_index = -1;
                  }
              } else {
                  current_trade_index = -1;
                  for(int idx = 0; idx < g_trade_count_h; idx++) {
                      if (g_trade_t1_h[idx] == state.t1_h && g_trade_t2_h[idx] == state.t2_h) {
                          current_trade_index = idx;
                          break;
                      }
                  }
              }

              if (current_trade_index >= 0) {

                  if (!is_history || (is_just_closed && !g_is_full_reload)) {
                      if (is_new_signal) {
                      bool should_execute = false;
                      if (current_trade_index == 0 && InpFirstTradeEnable)  should_execute = true;
                      if (current_trade_index == 1 && InpSecondTradeEnable) should_execute = true;
                      if (current_trade_index == 2 && InpThirdTradeEnable)  should_execute = true;
                      if (current_trade_index == 3 && InpFourthTradeEnable) should_execute = true;
                      if (current_trade_index == 4 && InpFifthTradeEnable)  should_execute = true;

                      if (should_execute) {
                          if (current_trade_index > 0) Alert(IntegerToString(current_trade_index + 1) + ". İşlem Onaylandı");

                          bool is_subsequent = (current_trade_index > 0);

                          if (!InpWaitRetest) {
                              EvaluateTradeSignal(i, time[i], val_c, -1, p_pct, is_strong, state.t2_h, state.maj_h_i, is_subsequent, false, current_trade_index+1, state.d1_l);
                          } else {
                              g_pending_active = true;
                              g_pending_dir = -1;
                              g_pending_bar_i = i;
                              g_pending_sl = state.t2_h;
                              g_pending_is_strong = is_strong;
                              g_pending_p_pct = p_pct;
                              g_pending_maj_extreme_i = state.maj_h_i;
                              g_pending_is_second_trade = is_subsequent;
                              g_pending_trade_num = current_trade_index + 1;
                              g_pending_choch_level = state.d1_l;
                              double dist = state.t2_h - state.d1_l;
                              g_pending_entry = state.d1_l + (dist * (InpRetestDepthPct / 100.0));
                          }
                      }
                  }
                  }
                  // --- BASTIRILAN SİGNAL KAYDI (BEARISH) ---
                  else if (is_history && g_is_full_reload && is_new_signal) {
                      bool should_exec = false;
                      if (current_trade_index == 0 && InpFirstTradeEnable)  should_exec = true;
                      if (current_trade_index == 1 && InpSecondTradeEnable) should_exec = true;
                      if (current_trade_index == 2 && InpThirdTradeEnable)  should_exec = true;
                      if (current_trade_index == 3 && InpFourthTradeEnable) should_exec = true;
                      if (current_trade_index == 4 && InpFifthTradeEnable)  should_exec = true;
                      if (should_exec) {
                          g_last_drawn_choch.drawn         = true;
                          g_last_drawn_choch.dir           = -1;
                          g_last_drawn_choch.d1_level      = state.d1_l;
                          g_last_drawn_choch.sl            = state.t2_h;
                          g_last_drawn_choch.maj_i         = state.maj_h_i;
                          g_last_drawn_choch.ppct          = p_pct;
                          g_last_drawn_choch.is_strong     = is_strong;
                          g_last_drawn_choch.is_subsequent = (current_trade_index > 0);
                          g_last_drawn_choch.trade_num     = current_trade_index + 1;
                      }
                  }

                  if (is_new_signal && InpShowChoch) {
                  color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

                  string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_h, GetTimeSafe(time, state.d1_i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_l, GetTimeSafe(time, state.t2_i), state.t2_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_h, GetTimeSafe(time, i), state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
                  DrawLine(choch_name, GetTimeSafe(time, i), state.d1_l, GetTimeSafe(time, i) + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);

                  string label_text = (current_trade_index >= 0) ? IntegerToString(current_trade_index + 1) : "-";
                  string text_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, text_name, OBJ_TEXT, 0, GetTimeSafe(time, i), state.d1_l);
                  ObjectSetString(0, text_name, OBJPROP_TEXT, label_text);
                  ObjectSetInteger(0, text_name, OBJPROP_COLOR, sig_color);
                  ObjectSetInteger(0, text_name, OBJPROP_FONTSIZE, 10);
                  ObjectSetInteger(0, text_name, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
                  }
              }

              if (is_new_signal) {
                  last_alert_d1_i_bear = state.d1_i;
                  last_alert_maj_i_bear = state.maj_h_i;
              }
          }
          state.choch_dir = 0;
          }
      }
   }

   // --- BULLISH CHoCH ---
   else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {

      double range = state.maj_h - state.maj_l;
      double level_60_bull = state.maj_l + range * (1.0 - InpMinPullbackPct / 100.0);
      bool t2_valid = (range > 0 && state.d1_h <= level_60_bull && state.t2_l <= level_60_bull);

      int r_total = ArraySize(close);
      bool is_just_closed = (i == r_total - 2);
      bool should_eval_bull = (val_c > state.d1_h);

      if (should_eval_bull) {
          if (!t2_valid) {
              state.choch_dir = 0;
              state.d1_h = 0;
              state.t2_l = 0;
          } else {
          state.last_choch_dir = 1;
          state.last_choch_level = state.d1_h;
          state.last_choch_time = time[i];

          bool is_strong = (state.t2_l < state.t1_l);

          int current_trade_index = -1;

          if (draw_ui) {
              static int last_alert_d1_i_bull = 0;
              static int last_alert_maj_i_bull = 0;

              if (state.maj_l_i != g_current_maj_l_i) {
                  ResetBullishMemory();
                  g_current_maj_l_i = state.maj_l_i;
              }

              bool is_new_signal = (state.d1_i != last_alert_d1_i_bull);
              bool valid_sequence = false;

              if (g_trade_count_l == 0) {
                  valid_sequence = true;
              } else if (g_trade_count_l > 0 && g_trade_count_l < 5) {
                  int prev_i = g_trade_count_l - 1;
                  double prev_dip = MathMin(g_trade_t1_l[prev_i], g_trade_t2_l[prev_i]);
                  if (state.t2_l < prev_dip) {
                      valid_sequence = true;
                  }
              }

              if (is_new_signal) {
                  if (valid_sequence && g_trade_count_l < 5) {
                      current_trade_index = g_trade_count_l;
                      g_trade_t1_l[current_trade_index] = state.t1_l;
                      g_trade_t2_l[current_trade_index] = state.t2_l;
                      g_trade_count_l++;
                  } else {
                      current_trade_index = -1;
                  }
              } else {
                  current_trade_index = -1;
                  for(int idx = 0; idx < g_trade_count_l; idx++) {
                      if (g_trade_t1_l[idx] == state.t1_l && g_trade_t2_l[idx] == state.t2_l) {
                          current_trade_index = idx;
                          break;
                      }
                  }
              }

              if (current_trade_index >= 0) {

                  if (!is_history || (is_just_closed && !g_is_full_reload)) {
                      if (is_new_signal) {
                      bool should_execute = false;
                      if (current_trade_index == 0 && InpFirstTradeEnable)  should_execute = true;
                      if (current_trade_index == 1 && InpSecondTradeEnable) should_execute = true;
                      if (current_trade_index == 2 && InpThirdTradeEnable)  should_execute = true;
                      if (current_trade_index == 3 && InpFourthTradeEnable) should_execute = true;
                      if (current_trade_index == 4 && InpFifthTradeEnable)  should_execute = true;

                      if (should_execute) {
                          if (current_trade_index > 0) Alert(IntegerToString(current_trade_index + 1) + ". İşlem Onaylandı");

                          bool is_subsequent = (current_trade_index > 0);

                          if (!InpWaitRetest) {
                              EvaluateTradeSignal(i, time[i], val_c, 1, p_pct, is_strong, state.t2_l, state.maj_l_i, is_subsequent, false, current_trade_index+1, state.d1_h);
                          } else {
                              g_pending_active = true;
                              g_pending_dir = 1;
                              g_pending_bar_i = i;
                              g_pending_sl = state.t2_l;
                              g_pending_is_strong = is_strong;
                              g_pending_p_pct = p_pct;
                              g_pending_maj_extreme_i = state.maj_l_i;
                              g_pending_is_second_trade = is_subsequent;
                              g_pending_trade_num = current_trade_index + 1;
                              g_pending_choch_level = state.d1_h;
                              double dist = state.d1_h - state.t2_l;
                              g_pending_entry = state.d1_h - (dist * (InpRetestDepthPct / 100.0));
                          }
                      }
                  }
                  }
                  // --- BASTIRILAN SİGNAL KAYDI (BULLISH) ---
                  else if (is_history && g_is_full_reload && is_new_signal) {
                      bool should_exec = false;
                      if (current_trade_index == 0 && InpFirstTradeEnable)  should_exec = true;
                      if (current_trade_index == 1 && InpSecondTradeEnable) should_exec = true;
                      if (current_trade_index == 2 && InpThirdTradeEnable)  should_exec = true;
                      if (current_trade_index == 3 && InpFourthTradeEnable) should_exec = true;
                      if (current_trade_index == 4 && InpFifthTradeEnable)  should_exec = true;
                      if (should_exec) {
                          g_last_drawn_choch.drawn         = true;
                          g_last_drawn_choch.dir           = 1;
                          g_last_drawn_choch.d1_level      = state.d1_h;
                          g_last_drawn_choch.sl            = state.t2_l;
                          g_last_drawn_choch.maj_i         = state.maj_l_i;
                          g_last_drawn_choch.ppct          = p_pct;
                          g_last_drawn_choch.is_strong     = is_strong;
                          g_last_drawn_choch.is_subsequent = (current_trade_index > 0);
                          g_last_drawn_choch.trade_num     = current_trade_index + 1;
                      }
                  }

                  if (is_new_signal && InpShowChoch) {
                  color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

                  string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_1, GetTimeSafe(time, state.t1_i), state.t1_l, GetTimeSafe(time, state.d1_i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_2, GetTimeSafe(time, state.d1_i), state.d1_h, GetTimeSafe(time, state.t2_i), state.t2_l, InpColorChochPath, 1, STYLE_DOT, false);

                  string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
                  DrawLine(path_3, GetTimeSafe(time, state.t2_i), state.t2_l, GetTimeSafe(time, i), state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

                  string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
                  DrawLine(choch_name, GetTimeSafe(time, i), state.d1_h, GetTimeSafe(time, i) + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);

                  string label_text = (current_trade_index >= 0) ? IntegerToString(current_trade_index + 1) : "-";
                  string text_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, text_name, OBJ_TEXT, 0, GetTimeSafe(time, i), state.d1_h);
                  ObjectSetString(0, text_name, OBJPROP_TEXT, label_text);
                  ObjectSetInteger(0, text_name, OBJPROP_COLOR, sig_color);
                  ObjectSetInteger(0, text_name, OBJPROP_FONTSIZE, 10);
                  ObjectSetInteger(0, text_name, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
                  }
              }

              if (is_new_signal) {
                  last_alert_d1_i_bull = state.d1_i;
                  last_alert_maj_i_bull = state.maj_l_i;
              }
          }
          state.choch_dir = 0;
          }
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

            CutLine(state.cur_top_line, GetTimeSafe(time, i));
            CutLine(state.cur_bot_line, GetTimeSafe(time, i));

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

            CutLine(state.cur_top_line, GetTimeSafe(time, i));
            CutLine(state.cur_bot_line, GetTimeSafe(time, i));
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

            CutLine(state.cur_top_line, GetTimeSafe(time, i));
            CutLine(state.cur_bot_line, GetTimeSafe(time, i));
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

            CutLine(state.cur_top_line, GetTimeSafe(time, i));
            CutLine(state.cur_bot_line, GetTimeSafe(time, i));
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

            CutLine(state.cur_top_line, GetTimeSafe(time, i));
            CutLine(state.cur_bot_line, GetTimeSafe(time, i));

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

            CutLine(state.cur_top_line, GetTimeSafe(time, i));
            CutLine(state.cur_bot_line, GetTimeSafe(time, i));
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

            CutLine(state.cur_top_line, GetTimeSafe(time, i));
            CutLine(state.cur_bot_line, GetTimeSafe(time, i));
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
       virtual_prev = rates_total - 1;
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
      g_is_full_reload = true;   // Tam yeniden yükleme
      g_last_drawn_choch.drawn = false;  // Bastırılan sinyal kaydını temizle

      ObjectsDeleteAll(0, "Structure_");
      ObjectsDeleteAll(0, "Minor_");
      ObjectsDeleteAll(0, "Major_");
      ObjectsDeleteAll(0, "HLine_");
      ObjectsDeleteAll(0, "LiveLeg_");
      ObjectsDeleteAll(0, "CHoCH_Bear_");
      ObjectsDeleteAll(0, "CHoCH_Bull_");
      ObjectsDeleteAll(0, "CHoCH_Path_");
      ObjectsDeleteAll(0, "CHoCH_Signal_");
      ObjectsDeleteAll(0, "CHoCH_Text_");


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

      double initial_atr = 0;
      double atr_arr[];
      initial_atr = (high[start_idx] - low[start_idx]);
      if(initial_atr == 0) initial_atr = Point() * 10;

      double tiny_gap = initial_atr * 0.1;

      g_state_hist.maj_h = high[start_idx] + tiny_gap;
      g_state_hist.maj_l = low[start_idx] - tiny_gap;
      g_state_hist.maj_tr = g_state_hist.min_tr;
      g_state_hist.maj_st = 1;
      g_state_hist.bos_i = start_idx;

      g_state_hist.maj_h_i = start_idx;
      g_state_hist.maj_l_i = start_idx;

      limit = start_idx + 1;

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

   g_is_full_reload = false;  // History scan bitti, artık canlı mod

   // ─── BASTIRILAN CHoCH SİGNALİNİ ATEŞLE ───────────────────────────
   // Tam yükleme sırasında bastırılan ve ekrana çizilen son CHoCH
   // sinyali varsa, fiyat hâlâ geçerli taraftaysa bildirim at ve işlem aç.
   if (g_last_drawn_choch.drawn) {
       g_last_drawn_choch.drawn = false;
       double live_p = SymbolInfoDouble(Symbol(), SYMBOL_BID);

       bool still_valid = false;
       if (g_last_drawn_choch.dir == -1 && live_p < g_last_drawn_choch.d1_level) still_valid = true;
       if (g_last_drawn_choch.dir ==  1 && live_p > g_last_drawn_choch.d1_level) still_valid = true;

       if (still_valid) {
           EvaluateTradeSignal(
               rates_total - 1,
               TimeCurrent(),
               live_p,
               g_last_drawn_choch.dir,
               g_last_drawn_choch.ppct,
               g_last_drawn_choch.is_strong,
               g_last_drawn_choch.sl,
               g_last_drawn_choch.maj_i,
               g_last_drawn_choch.is_subsequent,
               false,
               g_last_drawn_choch.trade_num,
               g_last_drawn_choch.d1_level
           );
       } else {
           Print("⚠️ Bastırılan CHoCH sinyali geçersiz - fiyat CHoCH seviyesinin yanlış tarafında. Sinyal atlandı.");
       }
   }
   // ──────────────────────────────────────────────────────────────────

   if (virtual_prev == 0 && InpTestTradeExecution) {
       TestCHoCHSignal();
   }

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
      DrawLine("LiveLeg", GetTimeSafe(time, g_state_curr.lp_i), g_state_curr.lp_p, GetTimeSafe(time, leg_i), leg_p, InpColorMin, 1, STYLE_DOT);
     }

   if(last_idx > 0 && (Period() == PERIOD_M1 || InpTestMode))
     {
      int live_trend = 0;
      double live_pct = 0.0;
      double dmy_h, dmy_l; datetime dmy_th, dmy_tl;
      double dmy_mpct;
      if (GetMTFPullback(PERIOD_M1, live_trend, live_pct, dmy_mpct, time[last_idx], dmy_h, dmy_l, dmy_th, dmy_tl))
        {
         if (g_state_hist.maj_h != g_last_alert_maj_h ||
             g_state_hist.maj_l != g_last_alert_maj_l ||
             g_state_hist.maj_tr != g_last_alert_trend)
           {
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

         if(live_pct < 98.0)
           {
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