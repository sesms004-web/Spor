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

//--- MTF Analiz Geçmişi (Gün Sayısı) ---
input int    InpDaysM1   = 2;            // M1 Analiz Geçmişi (Gün)

//--- CHoCH Settings ---
input double InpMinPullbackPct = 40.0;           // CHoCH Min Çekilme % (Onay Yüzdeliği)
input double InpMaxPullbackPct = 100.0;          // CHoCH Max Çekilme % (İşlem Yüzdeliği)

//--- Çekilme (Pullback) Hassasiyet Ayarları (%) ---
input double InpPullbackM5   = 50.0;     // M5 Mikro Filtre Çekilme %

//--- Visual Settings ---
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
input bool   InpEnableTradeExecution   = true;       // Özel Skorluk 'İşleme Gir' Analiz Sistemini Aç
input int    InpMinTradeScore          = 30;         // Minimum İşleme Giriş Skoru (Varsayılan 30)
input bool   InpEnableAutoTradeWriter  = true;       // MT5 Ortak Klasöre Sinyal Dosyası Gönder (Auto-Trade EA için)
input int    InpMaxTradesPerSwing      = 2;          // Aynı Majör Dalga İçinde Maksimum Sinyal Sayısı
input bool   InpTestTradeExecution     = false;      // 🧪 [TEST] Anlık Skorları Hesapla ve Bildir
input bool   InpForceTestSignal        = false;      // ⚠️ [TEST] Ayarı 'True' Yapıp Kapatınca Ortak Klasöre Deneme Sinyali Atar!
input bool   InpAlertPopup       = true;
input bool   InpAlertPush        = false;

//--- Globals ---
int g_counter = 0;
datetime g_last_alert_time = 0;
int g_alert_bar_index = -1;
datetime g_anchor_time = 0;

//--- Virtual Trade Tracking ---
bool g_virtual_trade_active = false;
int g_virtual_trade_dir = 0; // 1 = BUY, -1 = SELL
double g_virtual_sl = 0.0;
double g_virtual_tp = 0.0;

double g_last_alert_maj_h = 0;
double g_last_alert_maj_l = 0;
int g_last_alert_trend = 0;

void DrawLine(string name, datetime time1, double price1, datetime time2, double price2, color clr, int width, ENUM_LINE_STYLE style, bool ray_right=false)
  {
   if(name == "") return;
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
   if(name == "") return;
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
  }

void CutLine(string name, datetime time_cut)
  {
   if(name == "") return;
   if(ObjectFind(0, name) >= 0)
     {
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time_cut);
     }
  }

void UpdateLineLevel(string name, double level)
  {
   if(name == "") return;
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


int GetDaysForTF(ENUM_TIMEFRAMES tf)
  {
   if(tf == PERIOD_M1) return InpDaysM1;
   if(tf == PERIOD_M3) return 3;
   if(tf == PERIOD_M5) return 6;
   if(tf == PERIOD_M15) return 16;
   if(tf == PERIOD_M30) return 33;
   if(tf == PERIOD_H1) return 63;
   return 10;
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

bool GetMTFPullback(ENUM_TIMEFRAMES tf, int &trend, double &pct, double &max_pct, datetime current_time,
                    double live_price, double &ref_h, double &ref_l, datetime &ref_t_h, datetime &ref_t_l)
  {
      int days = GetDaysForTF(tf);
   if (days < 1) days = 1;

   datetime start_time = current_time - (days * 86400); // Geriye dönük gün hesaplama

   MqlRates rates[];
   ArraySetAsSeries(rates, false); // Eski bar 0, yeni bar en sonda (Simülasyon sırası)

   // Anlık zamandan (current_time), hesaplanan start_time'a kadar kopyala
   int copied = CopyRates(Symbol(), tf, start_time, current_time, rates);
   if(copied < 10) return false;

   // Arka planda çalışacak geçici State objesi (Çizim YAPMAYACAK)
   SState sim_state;

   // Başlangıç değerlerini ilk barlara göre ayarla
   sim_state.min_h   = rates[0].high;
   sim_state.min_h_i = 0;
   sim_state.min_l   = rates[0].low;
   sim_state.min_l_i = 0;
   sim_state.trig_h  = rates[0].high;
   sim_state.trig_l  = rates[0].low;
   sim_state.tmp_h   = rates[0].high;
   sim_state.tmp_h_i = 0;
   sim_state.tmp_l   = rates[0].low;
   sim_state.tmp_l_i = 0;
   sim_state.min_tr  = (rates[0].close > rates[0].open) ? 1 : -1;
   sim_state.anc_i   = 0;
   sim_state.anc_v   = rates[0].close;
   sim_state.lp_i    = 0;
   sim_state.lp_p    = rates[0].close;

   sim_state.mb_h = rates[0].high;
   sim_state.mb_l = rates[0].low;
   sim_state.mb_i = 0;

   sim_state.t1_h = 0; sim_state.t1_l = 0; sim_state.t1_i = 0;
   sim_state.d1_h = 0; sim_state.d1_l = 0; sim_state.d1_i = 0;
   sim_state.t2_h = 0; sim_state.t2_l = 0; sim_state.t2_i = 0;
   sim_state.choch_dir = 0;

   double initial_atr = (rates[0].high - rates[0].low);
   if(initial_atr == 0) initial_atr = Point() * 10;
   double tiny_gap = initial_atr * 0.1;

   sim_state.maj_h = rates[0].high + tiny_gap;
   sim_state.maj_l = rates[0].low - tiny_gap;
   sim_state.maj_tr = sim_state.min_tr;
   sim_state.maj_st = 1;
   sim_state.bos_i = 0;

   sim_state.maj_h_i = 0;
   sim_state.maj_l_i = 0;

   // ProcessBar fonksiyonunun imzasını karşılamak için geçici diziler
   double open_arr[], high_arr[], low_arr[], close_arr[];
   datetime time_arr[];
   ArrayResize(open_arr, copied);
   ArrayResize(high_arr, copied);
   ArrayResize(low_arr, copied);
   ArrayResize(close_arr, copied);
   ArrayResize(time_arr, copied);

   for(int i = 0; i < copied; i++) {
       open_arr[i]  = rates[i].open;
       high_arr[i]  = rates[i].high;
       low_arr[i]   = rates[i].low;
       close_arr[i] = rates[i].close;
       time_arr[i]  = rates[i].time;
   }

   // Barları baştan sona simüle et (Sadece Array'ler ve State üzerinden, grafik sıfır!)
   for(int i = 1; i < copied; i++)
     {
      bool inside = (high_arr[i] <= sim_state.mb_h) && (low_arr[i] >= sim_state.mb_l);
      if(!inside)
        {
         if (high_arr[i] > sim_state.mb_h || low_arr[i] < sim_state.mb_l) {
            sim_state.mb_h = high_arr[i];
            sim_state.mb_l = low_arr[i];
            sim_state.mb_i = i;
         }
         // draw_ui = false parametresi ile ProcessBar'ı çağırıyoruz. Hızlıdır ve obje çizmez.
         ProcessBar(i, open_arr, high_arr, low_arr, close_arr, time_arr, sim_state, true, false);
        }
     }

   // Simülasyon bitti, son durumu dışarı aktar
   trend = sim_state.maj_tr;

   // Eğer son dalga henüz onaylanmamışsa (maj_st == 0) yani fiyat kırılım yapmış ama
   // geri çekilip yeni bir minör tepe/dip oluşturarak zirveyi kilitlememişse,
   // hesaplamayı eski ve geride kalmış maj_h/maj_l yerine, o anki en uç noktalar (tmp_h/tmp_l) üzerinden yap!
   int m_h_i = sim_state.maj_h_i;
   int m_l_i = sim_state.maj_l_i;

   ref_h = sim_state.maj_h;
   ref_l = sim_state.maj_l;

   if (sim_state.maj_st == 0) {
       if (trend == 1) { // Up Trend: Yükselen trend devam ediyorsa, en uç nokta tmp_h'tir.
           ref_h = sim_state.tmp_h;
           m_h_i = sim_state.tmp_h_i;
       } else { // Down Trend: Düşen trend devam ediyorsa, en uç nokta tmp_l'dir.
           ref_l = sim_state.tmp_l;
           m_l_i = sim_state.tmp_l_i;
       }
   }

   // Zaman dizilerinde sınır aşımı kontrolü
   int maj_h_idx = m_h_i < copied ? m_h_i : copied - 1;
   int maj_l_idx = m_l_i < copied ? m_l_i : copied - 1;

   ref_t_h = time_arr[maj_h_idx];
   ref_t_l = time_arr[maj_l_idx];

   pct = 0.0;
   max_pct = 0.0;

   if (ref_h != EMPTY_VALUE && ref_l != EMPTY_VALUE && ref_h != ref_l) {
       double range = ref_h - ref_l;
       if (trend == 1) { // BUY Trend
           pct = ((ref_h - live_price) / range) * 100.0;
           double local_lowest = rates[copied-1].low;
           for(int i = maj_h_idx; i < copied; i++) {
               if(low_arr[i] < local_lowest) local_lowest = low_arr[i];
           }
           max_pct = ((ref_h - local_lowest) / range) * 100.0;

           // Kırılım (Breakout) Durumu SIFIRLAMA
           // Eğer canlı fiyat, güncel onaylı tepemizi (maj_h) çoktan aştıysa (kırdıysa),
           // ortada bir "çekilme" kalmamıştır, yeni bir dalga yapıyordur. Yüzdeleri tamamen SIFIRLA.
           if (live_price >= ref_h) { pct = 0; max_pct = 0; }
       } else { // SELL Trend
           pct = ((live_price - ref_l) / range) * 100.0;
           double local_highest = rates[copied-1].high;
           for(int i = maj_l_idx; i < copied; i++) {
               if(high_arr[i] > local_highest) local_highest = high_arr[i];
           }
           max_pct = ((local_highest - ref_l) / range) * 100.0;

           // Kırılım (Breakout) Durumu SIFIRLAMA
           if (live_price <= ref_l) { pct = 0; max_pct = 0; }
       }
   }

   if(pct < 0) pct = 0;
   if(max_pct < pct) max_pct = pct;

   return true;
  }


//+------------------------------------------------------------------+
//| 50-Point Execution Analysis Engine                               |
//+------------------------------------------------------------------+
void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, double ext_pt, bool is_test = false)
  {
   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double h_m5, l_m5, h_m15, l_m15, h_m30, l_m30, h_h1, l_h1;
   double temp_h_val, temp_l_val; datetime temp_th_val, temp_tl_val, th_m5, tl_m5, th_m15, tl_m15, th_m30, tl_m30, th_h1, tl_h1;

   // We need MTF data to evaluate the matrix
   GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, live_price, temp_h_val, temp_l_val, temp_th_val, temp_tl_val);
   GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, live_price, temp_h_val, temp_l_val, temp_th_val, temp_tl_val);
   GetMTFPullback(PERIOD_M5, t_m5, p_m5, mp_m5, t, live_price, h_m5, l_m5, th_m5, tl_m5);
   GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, live_price, h_m15, l_m15, th_m15, tl_m15);
   GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, live_price, h_m30, l_m30, th_m30, tl_m30);
   GetMTFPullback(PERIOD_H1, t_h1, p_h1, mp_h1, t, live_price, h_h1, l_h1, th_h1, tl_h1);

   double true_live_m1 = p_m1; // M1'in gerçek anlık çekilmesini (kırılım anındaki esnemeyi) koru

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
       if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "Ana Yön İle Uyumlu Sert İvme (Momentum) -> [+30 Skor]\n"; }
       else               { h1_points = 0;  h1_text = "H1: " + stats_h1 + "Ana Yöne Ters Sert İvme Var (Riskli) -> [0 Skor]\n"; }
   } else {
       if (p_h1 >= 50.0) { // Premium
           if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "Ana Yöne Uyumlu %50+ Mükemmel İndirim/Premium Bölgesi -> [+30 Skor]\n"; }
           else               { h1_points = 0;  h1_text = "H1: " + stats_h1 + "%50+ İndirim Bölgesinde Ancak Ana Yöne Ters! (Riskli) -> [0 Skor]\n"; }
       } else if (p_h1 >= 10.0) { // 10% Pullback Trade Opportunity (Live Pullback)
           if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "Ana Yöne Uyumlu ve Anlık Çekilme Yeterli (Min %10 Şartı Sağlandı) -> [+30 Skor]\n"; }
           else               { h1_points = 0;  h1_text = "H1: " + stats_h1 + "Ana Yöne Ters! Fiyat Çoktan Düzeltmeye Başlamış, Her An Ana Trende Dönebilir! (Riskli) -> [0 Skor]\n"; }
       } else { // Shallow (p_h1 < 10.0)
           if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "H1 Trendi Çok Güçlü (Çekilme <%10), Ana Yöne Uyumlu Kırılım Geldi (Trende Katıl) -> [+30 Skor]\n"; }
           else               { h1_points = 30; h1_text = "H1: " + stats_h1 + "H1 Trendi Çok Uzadı (Çekilme <%10), Ana Yöne Ters Yeni Karşıt Düzeltme Fırsatı Başladı (Önü Açık!) -> [+30 Skor]\n"; }
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
       m30_points = 0; m30_text = "M30: " + stats_m30 + "Fiyat Yapısı Üst Zaman Dilimi (H1) İle Birebir Aynı, Çift Puan Önleme -> [0 Skor]\n";
   } else {
       if (m30_momentum) {
           if (is_m30_aligned) { m30_points = 15; m30_text = "M30: " + stats_m30 + "H1 Ana Yönüne Uyumlu Aşırı Sert İvme (Momentum Var) -> [+15 Skor]\n"; }
           else                { m30_points = 0;  m30_text = "M30: " + stats_m30 + "H1 Ana Yönüne Ters Sert İvme Var (Geri Çekebilir!) -> [0 Skor]\n"; }
       } else {
           if (p_m30 >= 50.0) {
               if (is_m30_aligned) { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Fiyat %50+ Şişkin Bölgede Ama Ana Yöne Uyumlu -> [+10 Skor]\n"; }
               else                { m30_points = 0;   m30_text = "M30: " + stats_m30 + "Fiyat %50+ Şişkin Bölgede Ve Ana Yöne Ters (Tuzak Riski!) -> [0 Skor]\n"; }
           } else if (p_m30 >= 20.0) {
               if (is_m30_aligned) { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Ana Yöne Uyumlu Çekilme Devam Ediyor -> [+10 Skor]\n"; }
               else                { m30_points = 0;   m30_text = "M30: " + stats_m30 + "Ana Yöne Ters! Fiyat Çoktan Düzeltmeye Başlamış (%20+), Her An Ana Trende Dönebilir! (Riskli) -> [0 Skor]\n"; }
           } else { // Shallow (p_m30 < 20.0)
               if (is_m30_aligned) { m30_points = 10;  m30_text = "M30: " + stats_m30 + "M30 Trendi Güçlü (Çekilme <%20), Ana Yöne Uyumlu -> [+10 Skor]\n"; }
               else                { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Karşıt Düzeltme Henüz Yeni Başlıyor (Çekilme <%20), Önü Açık! -> [+10 Skor]\n"; }
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
       m15_points = 0; m15_text = "M15: " + stats_m15 + "Fiyat Yapısı Üst Zaman Dilimi (M30) İle Birebir Aynı, Çift Puan Önleme -> [0 Skor]\n";
   } else {
       if (m15_momentum) {
           if (is_m15_aligned) { m15_points = 10; m15_text = "M15: " + stats_m15 + "Ana Yöne Uyumlu Net Ara Momentum Var -> [+10 Skor]\n"; }
           else                { m15_points = 0;  m15_text = "M15: " + stats_m15 + "Ana Yöne Ters Yönde Ara Momentum (Etkisiz) -> [0 Skor]\n"; }
       } else {
           if (p_m15 >= 50.0) {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15: " + stats_m15 + "%50+ Dinlenmiş Uyumlu Bölge -> [+5 Skor]\n"; }
               else                { m15_points = 0;  m15_text = "M15: " + stats_m15 + "%50+ Şişkin ve Ana Yöne Ters (Tuzak Riski) -> [0 Skor]\n"; }
           } else if (p_m15 >= 20.0) {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Ana Yöne Uyumlu Çekilme Devam Ediyor -> [+5 Skor]\n"; }
               else                { m15_points = 0;  m15_text = "M15: " + stats_m15 + "Ana Yöne Ters! Düzeltme İlerledi (%20+), Tehlikeli Bölge -> [0 Skor]\n"; }
           } else { // Shallow (p_m15 < 20.0)
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Düzeltme Yolu Açık, Uyumlu Yön (Çekilme <%20) -> [+5 Skor]\n"; }
               else                { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Erken Karşıt Minör Düzeltme İşlemi (Çekilme <%20) -> [+5 Skor]\n"; }
           }
       }
   }
   total_points += m15_points;

   // --- M5 MODIFIER LOGIC (De-duplication) ---
   int m5_points = 0;
   bool m5_momentum = ((mp_m5 - p_m5) >= 20.0);
   bool is_m5_aligned = (t_m5 == trigger_dir);
   bool is_m5_deep = (mp_m5 >= InpPullbackM5);
   bool is_m5_duplicate = (MathAbs(h_m5 - h_m15) < Point() * 5 && MathAbs(l_m5 - l_m15) < Point() * 5);

   string stats_m5 = "[Maks Çekilme: %" + DoubleToString(mp_m5, 2) + " | Anlık: %" + DoubleToString(p_m5, 2) + "] ";

   if (is_m5_duplicate) {
       m5_points = 0; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Fiyat Yapısı Üst Zaman Dilimi (M15) İle Birebir Aynı, Çift Puan Önleme -> [0 Skor]\n";
   } else {
       if (m5_momentum) {
           if (is_m5_aligned) {
               if (is_m5_deep) {
                   m5_points = 15; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Geçmişte İstenen Maksimum Derin Çekilme (%" + DoubleToString(InpPullbackM5, 1) + "+) Tamamlanmış ve Ana Yöne Sert İvme Var -> [+15 Skor]\n";
               } else {
                   m5_points = 10; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Derin Çekilme Şartı Sağlanmamış, Sadece Ana Yöne Sert İvme Var -> [+10 Skor]\n";
               }
           }
           else {
               m5_points = 0; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Ana Yöne Ters Yönde Anlık İvme (Mikro Düzeltme İçi) -> [0 Skor]\n";
           }
       } else {
           if (p_m5 >= 20.0) {
               if (is_m5_aligned) {
                   if (is_m5_deep) {
                       m5_points = 5; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Geçmişte İstenen Maksimum Derin Çekilme (%" + DoubleToString(InpPullbackM5, 1) + "+) Şartı Başarıyla Tamamlanmış, Yön Uyumlu -> [+5 Skor]\n";
                   } else {
                       m5_points = 0; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Maksimum Çekilme Yetersiz (Fiyat Yeterince Dinlenmedi) -> [0 Skor]\n";
                   }
               } else {
                   m5_points = 0; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Ana Yöne Ters! Düzeltme İlerledi (%20+), Tehlikeli Bölge -> [0 Skor]\n";
               }
           } else { // Shallow (p_m5 < 20.0)
               if (is_m5_aligned) {
                   if (is_m5_deep) {
                       m5_points = 5; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Geçmişte İstenen Maksimum Derin Çekilme (%" + DoubleToString(InpPullbackM5, 1) + "+) Şartı Başarıyla Tamamlanmış, Yön Uyumlu -> [+5 Skor]\n";
                   } else {
                       m5_points = 0; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Maksimum Çekilme Yetersiz (Fiyat Yeterince Dinlenmedi) -> [0 Skor]\n";
                   }
               } else {
                   m5_points = 5; m5_text = "M5 (Mikro Filtre): " + stats_m5 + "Erken Karşıt Minör Düzeltme İşlemi (Çekilme <%20) -> [+5 Skor]\n";
               }
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
   if (total_points >= InpMinTradeScore) verdict = "✅ İŞLEME GİRİLEBİLİR (Skor Yeterli)";
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Skor Yetersiz)";

   string dir_str = (trigger_dir == 1) ? "BUY" : "SELL";
   string dir_emoji = (trigger_dir == 1) ? "⬆️ YUKARI (BUY)" : "⬇️ AŞAĞI (SELL)";

   string msg = "";
   if (is_test) msg = "🧪 [" + Symbol() + "] TEST ANALİZ RAPORU (Şu Anki Durum)\n";
   else msg = "🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI [" + lvl_text + "] 🚨\n";
   msg += "Yön: " + dir_emoji + "\n\n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\n" + m1_text + "\n";
   msg += "📊 ZAMAN DİLİMİ ANALİZİ (Ana Yön H1: " + (t_h1==1?"⬆️":"⬇️") + "):\n";
   msg += "* " + h1_text;
   msg += "* " + m30_text;
   msg += "* " + m15_text;
   msg += "* " + m5_text + "\n";
   msg += "🎯 İŞLEM MENZİLİ (M1 ve M3 Uyumu):\n" + range_text + "\n\n";
   msg += "📈 TOPLAM İŞLEM SKORU:\n";
   msg += "Hesaplanan: " + IntegerToString(total_points) + " Skor (Gerekli Baraj: " + IntegerToString(InpMinTradeScore) + " Skor)\n";
   msg += "KARAR: " + verdict;

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush) SendNotification(msg);

   // --- AUTO-TRADE FILE WRITER LOGIC ---
   static int last_maj_i = -1;
   static int current_swing_trades = 0;

   // Yeni bir ana dalga (swing) oluştuğunda sayaçları sıfırla
   if (g_state_curr.maj_h_i != last_maj_i && g_state_curr.maj_l_i != last_maj_i) {
       current_swing_trades = 0;
       last_maj_i = (trigger_dir == 1) ? g_state_curr.maj_l_i : g_state_curr.maj_h_i;
   }

   if (total_points >= InpMinTradeScore && InpEnableAutoTradeWriter) {

       // Eğer halihazırda takip ettiğimiz sanal bir işlem varsa, yeni sinyali çöpe at!
       if (g_virtual_trade_active) {
           Print("⚠️ [VIRTUAL TRADE] İçeride aktif bir sanal işlem var (SL/TP bekleniyor). Yeni sinyal reddedildi.");
           return;
       }

       // --- DİNAMİK M1 ÇEKİLME İŞLEM LİMİTİ ---
       bool is_deep_elastic = (mp_m1 >= 40.0);
       int allowed_trades = is_deep_elastic ? InpMaxTradesPerSwing : 1;

       if (current_swing_trades < allowed_trades) {

           double sl = 0.0;
           double tp = 0.0;
           double entry = live_price;

           if (trigger_dir == 1) { // BUY
               if (is_strong) { // Likidite alındı (Güçlü)
                   sl = ext_pt; // SL direkt en dibe konur
                   double dist = entry - sl;
                   tp = entry + (dist * 3.0); // 1:3 RR
               } else { // Likidite alınmadı (Zayıf)
                   double raw_sl = ext_pt;
                   double dist = entry - raw_sl;
                   sl = raw_sl - (dist * 0.5); // Zayıf dibin 0.5 boy daha altına (toplam 1.5 boy SL mesafesi)
                   double new_dist = entry - sl;
                   tp = entry + (new_dist * 3.0); // 1:3 RR
               }
           } else { // SELL
               if (is_strong) {
                   sl = ext_pt; // SL direkt en tepeye konur
                   double dist = sl - entry;
                   tp = entry - (dist * 3.0); // 1:3 RR
               } else {
                   double raw_sl = ext_pt;
                   double dist = raw_sl - entry;
                   sl = raw_sl + (dist * 0.5); // Zayıf tepenin 0.5 boy daha üstüne (toplam 1.5 boy SL mesafesi)
                   double new_dist = sl - entry;
                   tp = entry - (new_dist * 3.0); // 1:3 RR
               }
           }

           // Dosyayı Common klasörüne yaz (Her iki MT5 terminalinin okuyabilmesi için)
           string filename = "vol100_signal_" + Symbol() + ".txt";
           int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
           if (file_handle != INVALID_HANDLE) {
               string trade_cmd = Symbol() + "," + dir_str + "," + DoubleToString(entry, 5) + "," + DoubleToString(sl, 5) + "," + DoubleToString(tp, 5);
               FileWrite(file_handle, trade_cmd);
               FileClose(file_handle);
               Print("✅ [AUTO-TRADE] Sinyal Gönderildi: ", trade_cmd);
               current_swing_trades++; // Aynı dalgadaki işlem sayısını artır

               // Sanal İşlemi Başlat
               g_virtual_trade_active = true;
               g_virtual_trade_dir = trigger_dir;
               g_virtual_sl = sl;
               g_virtual_tp = tp;
               Print("🟢 [VIRTUAL TRADE] Sanal İşlem Takipli Başladı! Yön: ", dir_str, " SL: ", sl, " TP: ", tp);

           } else {
               Print("❌ [AUTO-TRADE] Sinyal Dosyası Oluşturulamadı! Hata Kodu: ", GetLastError());
           }
       } else {
           string reason = (!is_deep_elastic) ? " (M1 Çekilmesi %40 seviyesine ulaşmadığı için sadece 1 işleme izin verildi)" : "";
           Print("⚠️ [AUTO-TRADE] Bu majör dalga için maksimum işlem limitine (" + IntegerToString(allowed_trades) + ") ulaşıldı" + reason + ". Yeni sinyal gönderilmedi.");
       }
   }
  }

//+------------------------------------------------------------------+
//| MTF Alert System (Smart Algorithmic Decision Engine)             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME, "Structure");

   // --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---
   if (InpForceTestSignal) {
       Print("🧪 [TEST SİNYALİ] Gönderiliyor...");
       string filename = "vol100_signal_" + Symbol() + ".txt";
       int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
       if (file_handle != INVALID_HANDLE) {
           double entry = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
           double point_size = Point();

           // Sahte bir BUY işlemi simüle edelim: 100 Point (10 Pip) SL, 300 Point (30 Pip) TP
           double sl = entry - (100 * point_size);
           double tp = entry + (300 * point_size);

           string trade_cmd = Symbol() + ",BUY," + DoubleToString(entry, 5) + "," + DoubleToString(sl, 5) + "," + DoubleToString(tp, 5);
           FileWrite(file_handle, trade_cmd);
           FileClose(file_handle);
           Print("✅ [TEST BAŞARILI] Ortak Klasöre (Common) Sahte Sinyal Bırakıldı: ", trade_cmd);
           Print("⚠️ Lütfen bir sonraki gerçek işlem için gösterge ayarlarından 'InpForceTestSignal' ayarını tekrar FALSE yapmayı unutmayın!");
       } else {
           Print("❌ [TEST HATASI] Ortak klasöre dosya yazılamadı! Kod: ", GetLastError());
       }
   }
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
          double extreme_pt = (state.t2_h > state.t1_h) ? MathMax(state.t1_h, state.t2_h) : state.t1_h;
          double trade_sl_anchor = state.t2_h; // İşlem SL'si sadece ufak kırılımı başlatan minör tepeye (T2) konur!

          if (state.maj_h != EMPTY_VALUE && state.maj_l != EMPTY_VALUE && state.maj_h != state.maj_l) {
              double range = state.maj_h - state.maj_l;
              double true_h = FindTrueHigh(high, state.maj_h_i < state.maj_l_i ? state.maj_l_i : state.maj_h_i, i);
              if(true_h != EMPTY_VALUE) extreme_pt = true_h;

              if (state.maj_tr == 1) { // Up Trend Top Reversal
                  ext_pct = ((extreme_pt - state.maj_l) / range) * 100.0;
                  break_pct = ((state.maj_h - val_c) / range) * 100.0;
              } else { // Down Trend Pullback Continuation
                  ext_pct = ((extreme_pt - state.maj_l) / range) * 100.0;
                  break_pct = ((val_c - state.maj_l) / range) * 100.0;
              }
          }

          bool is_strong = (state.t2_h > state.t1_h); // T2 sweeps T1's high

          if (InpShowChoch && draw_ui) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;
              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_l, time[i] + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);

              ChartRedraw(); // Force UI update before MTF scan
          }

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
                      EvaluateTradeSignal(i, time[i], val_c, -1, ext_pct, is_strong, trade_sl_anchor);
                  }
                  last_alert_d1_i_bear = state.d1_i;
              }
          }
          state.choch_dir = 0; // Reset after trigger
      }
   } else if (state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0) {
      if (val_c > state.d1_h && in_pullback_zone) {
          // Bullish CHoCH confirmed!
          double ext_pct = 0;
          double break_pct = 0;
          double extreme_pt = (state.t2_l < state.t1_l) ? MathMin(state.t1_l, state.t2_l) : state.t1_l;
          double trade_sl_anchor = state.t2_l; // İşlem SL'si sadece ufak kırılımı başlatan minör dibe (T2) konur!

          if (state.maj_h != EMPTY_VALUE && state.maj_l != EMPTY_VALUE && state.maj_h != state.maj_l) {
              double range = state.maj_h - state.maj_l;
              double true_l = FindTrueLow(low, state.maj_h_i < state.maj_l_i ? state.maj_l_i : state.maj_h_i, i);
              if(true_l != EMPTY_VALUE) extreme_pt = true_l;

              if (state.maj_tr == 1) { // Up Trend Pullback Continuation
                  ext_pct = ((state.maj_h - extreme_pt) / range) * 100.0;
                  break_pct = ((state.maj_h - val_c) / range) * 100.0;
              } else { // Down Trend Bottom Reversal
                  ext_pct = ((state.maj_h - extreme_pt) / range) * 100.0;
                  break_pct = ((val_c - state.maj_l) / range) * 100.0;
              }
          }

          bool is_strong = (state.t2_l < state.t1_l); // T2 sweeps T1's low

          if (InpShowChoch && draw_ui) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;
              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_h, time[i] + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);

              ChartRedraw(); // Force UI update before MTF scan
          }

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
                      EvaluateTradeSignal(i, time[i], val_c, 1, ext_pct, is_strong, trade_sl_anchor);
                  }
                  last_alert_d1_i_bull = state.d1_i;
              }
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
            int days_lookback = GetDaysForTF(Period());
      g_anchor_time = time[rates_total - 1] - (days_lookback * 86400);

      g_counter = 0;
      g_last_alert_maj_h = 0;
      g_last_alert_maj_l = 0;
      g_last_alert_trend = 0;

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

   // --- 🕵️‍♂️ VIRTUAL TRADE TRACKER (Sanal SL/TP Kontrolü) ---
   if (g_virtual_trade_active) {
       double live_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
       double live_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

       if (g_virtual_trade_dir == 1) { // BUY Trade
           if (live_bid <= g_virtual_sl) {
               Print("🔴 [VIRTUAL TRADE] BUY İşlemi Sanal SL Oldu! Yeni işlem hakkı açıldı.");
               g_virtual_trade_active = false;
           } else if (live_bid >= g_virtual_tp) {
               Print("🟢 [VIRTUAL TRADE] BUY İşlemi Sanal TP Oldu! Yeni işlem hakkı açıldı.");
               g_virtual_trade_active = false;
           }
       } else if (g_virtual_trade_dir == -1) { // SELL Trade
           if (live_ask >= g_virtual_sl) {
               Print("🔴 [VIRTUAL TRADE] SELL İşlemi Sanal SL Oldu! Yeni işlem hakkı açıldı.");
               g_virtual_trade_active = false;
           } else if (live_ask <= g_virtual_tp) {
               Print("🟢 [VIRTUAL TRADE] SELL İşlemi Sanal TP Oldu! Yeni işlem hakkı açıldı.");
               g_virtual_trade_active = false;
           }
       }
   }

   if(last_idx > 0 && (Period() == PERIOD_M1))
     {
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
            g_last_alert_maj_h = g_state_hist.maj_h;
            g_last_alert_maj_l = g_state_hist.maj_l;
            g_last_alert_trend = g_state_hist.maj_tr;
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

           EvaluateTradeSignal(last_idx, TimeCurrent(), bid, test_choch_dir, live_pct, true, bid, true);
           is_test_run = true;
       }

       if(!InpTestTradeExecution) is_test_run = true; // prevent infinite false state if both are off
   }

   return(rates_total);
  }
