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
input bool   InpShowDashboard = true;
input color  InpColorMin = clrRed;
input color  InpColorBull = clrGreen;
input color  InpColorBear = clrRed;

//--- Algoritma Ayarları (Puanlama) ---
input int    InpMinTradeScoreLimit     = 40;         // 🎯 İşleme Giriş İçin Gerekli Minimum Puan Barajı
input int    InpMaxTradesPerSwing      = 2;          // 🔄 Aynı Majör Dalgada Maksimum Sinyal Sayısı

//--- Trade Execution (Gerçek İşlem Açma) ---
input bool   InpEnableAutoTradeWriter  = false;      // ⚠️ DİKKAT: Ortak Klasöre İşlem (Sinyal Dosyası) Gönder
input bool   InpTestTradeExecution     = false;      // 🧪 [TEST] Tıklandığında Anında Sahte İşlem (Telefon Testi) Gönder

//--- Bildirim Ayarları ---
input bool   InpAlertPopup             = true;       // Ekrana Popup (Uyarı) Penceresi Çıkar
input bool   InpAlertPush              = true;       // Telefona MT5 Push Bildirimi Gönder

//--- Globals ---
int g_counter = 0;
datetime g_last_alert_time = 0;
int g_alert_bar_index = -1;
datetime g_anchor_time = 0;
uint g_last_dash_tick = 0;
bool g_prev_test_state = false; // Test butonunu takip etmek için

//--- Virtual Trade Tracking ---
bool g_virtual_trade_active = false;
int g_virtual_trade_dir = 0; // 1 = BUY, -1 = SELL
double g_virtual_sl = 0.0;
double g_virtual_tp = 0.0;
int g_virtual_last_outcome = 0; // 0 = Yok, -1 = SL Oldu, 1 = TP Oldu
double g_virtual_last_sl_price = 0.0; // SL olunan fiyat seviyesini hafızada tutar
double g_virtual_last_entry_price = 0.0; // İlk işlemin giriş (kırılım) seviyesi

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


//+------------------------------------------------------------------+
//| Read MTF Global Variable Data                                    |
//+------------------------------------------------------------------+
bool ReadGlobalVariableMTF(string s, string tf, int &tr, double &p, double &mp, double &h, double &l, int max_age = 300)
  {
   string base = "5parite_" + s + "_" + tf + "_";
   if(GlobalVariableCheck(base + "Trend") && GlobalVariableCheck(base + "Pct") &&
      GlobalVariableCheck(base + "MaxPct") && GlobalVariableCheck(base + "High") &&
      GlobalVariableCheck(base + "Low") && GlobalVariableCheck(base + "Time"))
     {
      datetime ref_time = (datetime)GlobalVariableGet(base + "Time");
      if (TimeCurrent() - ref_time > max_age) return false;

      tr = (int)GlobalVariableGet(base + "Trend");
      p = GlobalVariableGet(base + "Pct");
      mp = GlobalVariableGet(base + "MaxPct");
      h = GlobalVariableGet(base + "High");
      l = GlobalVariableGet(base + "Low");
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Helper for Localized Trend Text                                  |
//+------------------------------------------------------------------+
string FormatTrendStr(int t)
  {
   if (t == 1) return "🟢 YÜKSELİŞ (Boğa)";
   if (t == -1) return "🔴 DÜŞÜŞ (Ayı)";
   return "⚪ YATAY (Range)";
  }

//+------------------------------------------------------------------+
//| 50-Point Execution Analysis Engine                               |
//+------------------------------------------------------------------+
void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, double ext_pt, bool is_test = false)
  {
   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double h_m5=0, l_m5=0, h_m15=0, l_m15=0, h_m30=0, l_m30=0, h_h1=0, l_h1=0;
   double temp_h_val=0, temp_l_val=0;

   // Use Global Variables for higher timeframes instead of GetMTFPullback
   t_m1 = g_state_curr.maj_tr;
   p_m1 = p_pct; // M1 pullback is passed directly via choch_pct/p_pct
   mp_m1 = 0; // will be calculated below

   double m1_h = g_state_curr.maj_h;
   double m1_l = g_state_curr.maj_l;
   if (m1_h != EMPTY_VALUE && m1_l != EMPTY_VALUE && m1_h != m1_l) {
      double range = m1_h - m1_l;
      if (t_m1 == 1) mp_m1 = ((m1_h - g_state_curr.tmp_l) / range) * 100.0;
      else mp_m1 = ((g_state_curr.tmp_h - m1_l) / range) * 100.0;
   }

   string sym = Symbol();

   bool hm3 = ReadGlobalVariableMTF(sym, "PERIOD_M3", t_m3, p_m3, mp_m3, temp_h_val, temp_l_val);
   bool hm5 = ReadGlobalVariableMTF(sym, "PERIOD_M5", t_m5, p_m5, mp_m5, h_m5, l_m5);
   bool hm15 = ReadGlobalVariableMTF(sym, "PERIOD_M15", t_m15, p_m15, mp_m15, h_m15, l_m15);
   bool hm30 = ReadGlobalVariableMTF(sym, "PERIOD_M30", t_m30, p_m30, mp_m30, h_m30, l_m30);
   bool hh1 = ReadGlobalVariableMTF(sym, "PERIOD_H1", t_h1, p_h1, mp_h1, h_h1, l_h1);

   if(!hm3 || !hm5 || !hm15 || !hm30 || !hh1) {
       if(!is_test) {
           Print("MTF Verileri eksik veya eski. Lütfen tüm zaman aralıklarına(M3-H1) indikatörü ekleyin. İşlem iptal.");
           return;
       }
       // Eğer test ediyorsak geri dönme, sadece uyarı ver ki algoritmanın o kısımlarının neden sıfır puan verdiğini anlasın
       Print("TEST MODU: Bazı MTF verileri eksik ancak test devam ediyor...");
   }

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

   string stats_m1 = "   └ Çekilme -> [Maksimum: %" + DoubleToString(mp_m1, 2) + " | Anlık: %" + DoubleToString(p_m1, 2) + "]\n";

   if(is_strong) m1_text = stats_m1 + "   └ Durum: 🔥 GÜÇLÜ (Ana likiditeyi süpürerek kırdı) -> [+5 Skor]\n";
   else          m1_text = stats_m1 + "   └ Durum: ⚠️ ZAYIF (Süpürme yapmadan kırılım geldi) -> [+0 Skor]\n";

   // --- H1 MACRO LOGIC ---
   int h1_points = 0;
   bool h1_momentum = ((mp_h1 - p_h1) >= 15.0);
   bool h1_momentum_bonus = ((mp_h1 - p_h1) >= 20.0);
   bool is_h1_aligned = (t_h1 == trigger_dir);

   string stats_h1 = "   └ Çekilme -> [Maksimum: %" + DoubleToString(mp_h1, 2) + " | Anlık: %" + DoubleToString(p_h1, 2) + "]\n";
   string trend_h1 = "   └ Yön -> " + FormatTrendStr(t_h1) + "\n";

   if (h1_momentum) {
       if (is_h1_aligned) {
           if (h1_momentum_bonus) { h1_points = 35; h1_text = "🧭 [H1 Makro Zaman Aralığı]\n" + trend_h1 + stats_h1 + "   └ Açıklama: 🚀 Zirveden/Dipten %20'den fazla sert ivme bonusu var ve yön uyumlu! Harika momentum. -> [+35 Skor]\n\n"; }
           else                   { h1_points = 30; h1_text = "🧭 [H1 Makro Zaman Aralığı]\n" + trend_h1 + stats_h1 + "   └ Açıklama: 🚀 Zirveden/Dipten %15'ten fazla sert ivmeli bir dönüş var ve yön uyumlu! -> [+30 Skor]\n\n"; }
       }
       else { h1_points = 0; h1_text = "🧭 [H1 Makro Zaman Aralığı]\n" + trend_h1 + stats_h1 + "   └ Açıklama: 🛑 Sert bir dönüş ivmesi (Momentum %15+) var ANCAK açacağımız işleme ters! Tuzak olabilir. -> [+0 Skor]\n\n"; }
   } else {
       if (p_h1 >= 50.0) { // Premium
           if (is_h1_aligned) { h1_points = 30; h1_text = "🧭 [H1 Makro Zaman Aralığı]\n" + trend_h1 + stats_h1 + "   └ Açıklama: 💎 Fiyat %50'nin üstünde mükemmel bir indirim/pahalı (Premium) bölgesine girdi ve yönümüzle aynı. Çok güvenli. -> [+30 Skor]\n\n"; }
           else               { h1_points = 0;  h1_text = "🧭 [H1 Makro Zaman Aralığı]\n" + trend_h1 + stats_h1 + "   └ Açıklama: 📉 Fiyat %50 Premium bölgesinde fakat H1'in ana trendi işlemimize ters! Puan verilmedi. -> [+0 Skor]\n\n"; }
       } else { // %50 Altında Kalan Tüm Çekilmeler (Aşırı Şişkin Piyasa Fırsatları)
           if (is_h1_aligned) { h1_points = 30; h1_text = "🧭 [H1 Makro Zaman Aralığı]\n" + trend_h1 + stats_h1 + "   └ Açıklama: 🔥 H1 Trendi güçlü, henüz %50 Premium'a gelmedi. Şişkin piyasada trende katılıyoruz! -> [+30 Skor]\n\n"; }
           else               { h1_points = 30; h1_text = "🧭 [H1 Makro Zaman Aralığı]\n" + trend_h1 + stats_h1 + "   └ Açıklama: 🎯 H1 Trendi henüz %50 indirim bölgesine ulaşmadı (Aşırı Şişkin). Karşı trend yönünde (Düzeltme) yepyeni ve kârlı bir dalga fırsatı! -> [+30 Skor]\n\n"; }
       }
   }
   total_points += h1_points;

   // --- M30 MODIFIER LOGIC (De-duplication) ---
   int m30_points = 0;
   bool m30_momentum = ((mp_m30 - p_m30) >= 15.0);
   bool m30_momentum_bonus = ((mp_m30 - p_m30) >= 20.0);
   bool is_m30_aligned = (t_m30 == trigger_dir);
   bool is_m30_duplicate = (MathAbs(h_m30 - h_h1) < Point() * 5 && MathAbs(l_m30 - l_h1) < Point() * 5);

   string stats_m30 = "   └ Çekilme -> [Maksimum: %" + DoubleToString(mp_m30, 2) + " | Anlık: %" + DoubleToString(p_m30, 2) + "]\n";
   string trend_m30 = "   └ Yön -> " + FormatTrendStr(t_m30) + "\n";

   if (is_m30_duplicate) {
       m30_points = 0; m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: 🔄 Fiyat yapısı ve dalgası bir üst grafik olan H1 ile tamamen aynı görünüyor. Çift puan eklememek için SIFIRLANDI. -> [+0 Skor]\n\n";
   } else {
       if (!is_m30_aligned) { // YÖN TERS
           if (p_m30 >= 50.0) {
               if (m30_momentum) { m30_points = 0;  m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: 🛑 Premium bölgede TERS yönlü %15 momentum var. Düzeltme bitiyor olabilir, riskli! -> [+0 Skor]\n\n"; }
               else              { m30_points = 15; m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: 📈 Premium bölgede TERS yönlü işlem, henüz dönüş momentumu yok, gidecek yolu var. -> [+15 Skor]\n\n"; }
           } else {
               m30_points = 0; m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: 📉 M30 henüz şişkin bölgede ve YÖN TERS. Çok tehlikeli! -> [+0 Skor]\n\n";
           }
       } else { // YÖN UYUMLU
           if (p_m30 < 50.0) {
               if (m30_momentum_bonus) { m30_points = 25; m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: 🚀 Yön uyumlu, %50 altı ve %20+ Momentum ivmesi var! (Bonus Puan) -> [+25 Skor]\n\n"; }
               else if (m30_momentum)  { m30_points = 20; m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: 🚀 Yön uyumlu, %50 altı ve %15 Momentum ivmesi var! Harika giriş fırsatı. -> [+20 Skor]\n\n"; }
               else                    { m30_points = 15; m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: ✅ Yön uyumlu ve %50 altında. Yolu daha var ama henüz momentum oluşmamış. -> [+15 Skor]\n\n"; }
           } else { // Premium
               if (m30_momentum_bonus) { m30_points = 25; m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: 💎 Premium bölgede YÖN UYUMLU işlem + %20 İvme Bonusu! -> [+25 Skor]\n\n"; }
               else                    { m30_points = 20; m30_text = "🗺️ [M30 Zaman Aralığı]\n" + trend_m30 + stats_m30 + "   └ Açıklama: 💎 Premium bölgede YÖN UYUMLU işlem! En mükemmel makro kurulum. -> [+20 Skor]\n\n"; }
           }
       }
   }
   total_points += m30_points;

   // --- M15 MODIFIER LOGIC (De-duplication) ---
   int m15_points = 0;
   bool m15_momentum = ((mp_m15 - p_m15) >= 15.0);
   bool m15_momentum_bonus = ((mp_m15 - p_m15) >= 20.0);
   bool is_m15_aligned = (t_m15 == trigger_dir);
   bool is_m15_duplicate = (MathAbs(h_m15 - h_m30) < Point() * 5 && MathAbs(l_m15 - l_m30) < Point() * 5);

   string stats_m15 = "   └ Çekilme -> [Maksimum: %" + DoubleToString(mp_m15, 2) + " | Anlık: %" + DoubleToString(p_m15, 2) + "]\n";
   string trend_m15 = "   └ Yön -> " + FormatTrendStr(t_m15) + "\n";

   if (is_m15_duplicate) {
       m15_points = 0; m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: 🔄 Dalga boyu M30 grafiği ile birebir örtüşüyor. Haksız çift puanı önlemek için eklendi. -> [+0 Skor]\n\n";
   } else {
       if (!is_m15_aligned) { // YÖN TERS
           if (p_m15 >= 50.0) {
               if (m15_momentum) { m15_points = 0;  m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: 🛑 Premium bölgede TERS yönlü %15 momentum var. Düzeltme bitiyor olabilir, riskli! -> [+0 Skor]\n\n"; }
               else              { m15_points = 10; m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: 📈 Premium bölgede TERS yönlü işlem, henüz dönüş momentumu yok, gidecek yolu var. -> [+10 Skor]\n\n"; }
           } else {
               m15_points = 0; m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: 📉 M15 henüz şişkin bölgede ve YÖN TERS. Çok tehlikeli! -> [+0 Skor]\n\n";
           }
       } else { // YÖN UYUMLU
           if (p_m15 < 50.0) {
               if (m15_momentum_bonus) { m15_points = 20; m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: 🚀 Yön uyumlu, %50 altı ve %20+ Momentum ivmesi var! (Bonus Puan) -> [+20 Skor]\n\n"; }
               else if (m15_momentum)  { m15_points = 15; m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: 🚀 Yön uyumlu, %50 altı ve %15 Momentum ivmesi var! Harika giriş fırsatı. -> [+15 Skor]\n\n"; }
               else                    { m15_points = 10; m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: ✅ Yön uyumlu ve %50 altında. Yolu daha var ama henüz momentum oluşmamış. -> [+10 Skor]\n\n"; }
           } else { // Premium
               if (m15_momentum_bonus) { m15_points = 20; m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: 💎 Premium bölgede YÖN UYUMLU işlem + %20 İvme Bonusu! -> [+20 Skor]\n\n"; }
               else                    { m15_points = 15; m15_text = "📏 [M15 Zaman Aralığı]\n" + trend_m15 + stats_m15 + "   └ Açıklama: 💎 Premium bölgede YÖN UYUMLU işlem! En mükemmel makro kurulum. -> [+15 Skor]\n\n"; }
           }
       }
   }
   total_points += m15_points;

   // --- M5 MODIFIER LOGIC (De-duplication) ---
   int m5_points = 0;
   bool m5_momentum = ((mp_m5 - p_m5) >= 15.0);
   bool m5_momentum_bonus = ((mp_m5 - p_m5) >= 20.0);
   bool is_m5_aligned = (t_m5 == trigger_dir);
   bool is_m5_duplicate = (MathAbs(h_m5 - h_m15) < Point() * 5 && MathAbs(l_m5 - l_m15) < Point() * 5);

   string stats_m5 = "   └ Çekilme -> [Maksimum: %" + DoubleToString(mp_m5, 2) + " | Anlık: %" + DoubleToString(p_m5, 2) + "]\n";
   string trend_m5 = "   └ Yön -> " + FormatTrendStr(t_m5) + "\n";

   if (is_m5_duplicate) {
       m5_points = 0; m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: 🔄 Dalga M15 ile birebir aynı sınırlar içerisinde (Klon). Çift puan engellendi. -> [+0 Skor]\n\n";
   } else {
       if (!is_m5_aligned) { // YÖN TERS
           if (p_m5 >= 50.0) {
               if (m5_momentum) { m5_points = 0; m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: 🛑 Premium bölgede TERS yönlü %15 momentum var. Riskli! -> [+0 Skor]\n\n"; }
               else             { m5_points = 5; m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: 📈 Premium bölgede TERS yönlü işlem, gidecek yolu var. -> [+5 Skor]\n\n"; }
           } else {
               m5_points = 0; m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: 📉 M5 henüz şişkin bölgede ve YÖN TERS. -> [+0 Skor]\n\n";
           }
       } else { // YÖN UYUMLU
           if (p_m5 < 50.0) {
               if (m5_momentum_bonus) { m5_points = 15; m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: 🚀 Yön uyumlu, %50 altı ve %20+ Momentum ivmesi var! (Bonus Puan) -> [+15 Skor]\n\n"; }
               else if (m5_momentum)  { m5_points = 10; m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: 🚀 Yön uyumlu, %50 altı ve %15 Momentum ivmesi var! -> [+10 Skor]\n\n"; }
               else                   { m5_points = 5;  m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: ✅ Yön uyumlu ve %50 altında. Yolu daha var. -> [+5 Skor]\n\n"; }
           } else { // Premium
               if (m5_momentum_bonus) { m5_points = 15; m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: 💎 Premium bölgede YÖN UYUMLU işlem + %20 İvme Bonusu! -> [+15 Skor]\n\n"; }
               else                   { m5_points = 10; m5_text = "🔬 [M5 Mikro Filtre]\n" + trend_m5 + stats_m5 + "   └ Açıklama: 💎 Premium bölgede YÖN UYUMLU işlem! -> [+10 Skor]\n\n"; }
           }
       }
   }
   total_points += m5_points;

   // --- M1 vs M3 RANGE EXPECTATION ---
   string range_text = (t_m1 == t_m3) ? "🚀 BEKLENTİ: UZUN MENZİL (Trend Takibi - Karlı ve Güvenli)" : "⚠️ BEKLENTİ: KISA SÜRECEK (Scalp/Tepki - Karlı ama Hızlı Kapanmalı)";

   // --- BREAKOUT LEVEL PHASING ---
   string lvl_text = "BİLİNMİYOR";
   if (p_pct >= 40.0 && p_pct < 60.0) lvl_text = "KIRILIM 1 (Erken/Sığ Seviye)";
   if (p_pct >= 60.0) lvl_text = "KIRILIM 2 (Ana/Derin Seviye)";

   // --- FINAL VERDICT ---
   string verdict = "";
   if (total_points >= InpMinTradeScoreLimit) verdict = "✅ İŞLEME GİRİLEBİLİR (Skor Algoritmayı Geçti)";
   else verdict = "❌ RİSKLİ! İŞLEME GİRİLMEZ (Skor " + IntegerToString(InpMinTradeScoreLimit) + " Puanlık Barajın Altında Kaldı)";

   string dir_str = (trigger_dir == 1) ? "BUY" : "SELL";
   string dir_emoji = (trigger_dir == 1) ? "🟢 YUKARI (BUY Alımı)" : "🔴 AŞAĞI (SELL Satışı)";

   // ============================================
   // 📌 MESAJLARI 2 PARÇAYA BÖLÜYORUZ (PUSH BİLDİRİMİ KESİLMESİN DİYE)
   // ============================================

   string msg1 = "";
   if (is_test) msg1 = "🧪 [" + Symbol() + "] TEST (BÖLÜM 1/2)\n";
   else msg1 = "🚨 [" + Symbol() + "] YENİ İŞLEM [" + lvl_text + "] (BÖLÜM 1/2)\n";

   msg1 += "🎯 Yön: " + dir_emoji + "\n\n";
   msg1 += "🔍 M1 (Tetik) Kırılımı:\n" + m1_text + "\n";
   msg1 += "📊 MTF DETAYLI ANALİZ:\n";
   msg1 += "------------------\n";
   msg1 += h1_text;
   msg1 += m30_text;

   string msg2 = "";
   if (is_test) msg2 = "🧪 [" + Symbol() + "] TEST (BÖLÜM 2/2)\n";
   else msg2 = "🚨 [" + Symbol() + "] İŞLEM DEVAMI (BÖLÜM 2/2)\n";

   msg2 += m15_text;
   msg2 += m5_text;
   msg2 += "🎯 MENZİL: " + range_text + "\n\n";
   msg2 += "📈 TOPLAM SKOR: " + IntegerToString(total_points) + " / " + IntegerToString(InpMinTradeScoreLimit) + "\n";
   msg2 += "KARAR: " + verdict + "\n";

   // TEST bildirimiyse detaylı mesajı hemen bas ve çık
   if (is_test) {
       if(InpAlertPopup) { Alert(msg1); Alert(msg2); }
       if(InpAlertPush) { SendNotification(msg1); SendNotification(msg2); }
       Print(msg1); Print(msg2);
       return; // Test runs do not execute trades or track virtual setups.
   }

   // --- AUTO-TRADE / SIGNAL WRITER LOGIC ---
   static int last_maj_i = -1;
   static int current_swing_trades = 0;

   // Yeni bir ana dalga (swing) oluştuğunda sayaçları sıfırla
   if (g_state_curr.maj_h_i != last_maj_i && g_state_curr.maj_l_i != last_maj_i) {
       current_swing_trades = 0;
       g_virtual_last_outcome = 0; // Yeni dalgada eski SL hafızasını sıfırla
       g_virtual_last_sl_price = 0.0;
       g_virtual_last_entry_price = 0.0;
       last_maj_i = (trigger_dir == 1) ? g_state_curr.maj_l_i : g_state_curr.maj_h_i;
   }

   if (total_points >= InpMinTradeScoreLimit) {

       // Eğer halihazırda takip ettiğimiz sanal bir işlem varsa, yeni sinyali çöpe at!
       if (g_virtual_trade_active) {
           Print("⚠️ [VIRTUAL TRADE] İçeride aktif bir sanal işlem var (SL/TP bekleniyor). Yeni sinyal reddedildi.");
           return;
       }

       // --- DİNAMİK M1 ÇEKİLME İŞLEM LİMİTİ ---
       bool is_deep_elastic = (mp_m1 >= 40.0);
       int allowed_trades = is_deep_elastic ? InpMaxTradesPerSwing : 1;

       if (current_swing_trades < allowed_trades) {

           // --- Testere/Aynı Bölge Koruması (Sadece 1. işlem SL olduysa geçerli) ---
           if (current_swing_trades > 0 && g_virtual_last_outcome == -1) {
               // Kullanıcının Mantığı: 2. Sinyalin "live_price" (kırılım) seviyesi, 1. işlemin SL seviyesi ile Entry seviyesi arasında olmalı.
               // Eğer fiyat SL seviyesini tamamen aşağı kırmışsa (live_price <= SL) veya eski Entry'yi geçmişse (live_price >= Entry) işlem alınmaz.
               if (trigger_dir == 1) { // BUY
                   if (live_price <= g_virtual_last_sl_price || live_price >= g_virtual_last_entry_price) {
                       Print("⚠️ [TRADE REJECTED] 2. BUY Reddedildi: Kırılım seviyesi (", live_price, "), SL (", g_virtual_last_sl_price, ") ile Kırılım Kutusu (", g_virtual_last_entry_price, ") arasında değil!");
                       return;
                   }
               }
               if (trigger_dir == -1) { // SELL
                   if (live_price >= g_virtual_last_sl_price || live_price <= g_virtual_last_entry_price) {
                       Print("⚠️ [TRADE REJECTED] 2. SELL Reddedildi: Kırılım seviyesi (", live_price, "), SL (", g_virtual_last_sl_price, ") ile Kırılım Kutusu (", g_virtual_last_entry_price, ") arasında değil!");
                       return;
                   }
               }
           }

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

           // --- TP SINIRLANDIRMASI (SWING + %10 KURALI) ---
           double maj_h = g_state_curr.maj_h;
           double maj_l = g_state_curr.maj_l;
           if (maj_h != EMPTY_VALUE && maj_l != EMPTY_VALUE && maj_h > maj_l) {
               double swing_range = maj_h - maj_l;
               double buffer_10pct = swing_range * 0.10;

               if (trigger_dir == 1) { // BUY -> TP aşırı yukarıdaysa reddet
                   double max_allowed_tp = maj_h + buffer_10pct;
                   if (tp > max_allowed_tp) {
                       Print("⚠️ [TRADE REJECTED] BUY İptal: TP noktası (", tp, "), Swing Tepesi + %10 sınırını (", max_allowed_tp, ") aşıyor. Hedef ulaşılamaz.");
                       return;
                   }
               } else if (trigger_dir == -1) { // SELL -> TP aşırı aşağıdaysa reddet
                   double min_allowed_tp = maj_l - buffer_10pct;
                   if (tp < min_allowed_tp) {
                       Print("⚠️ [TRADE REJECTED] SELL İptal: TP noktası (", tp, "), Swing Dibi - %10 sınırını (", min_allowed_tp, ") aşıyor. Hedef ulaşılamaz.");
                       return;
                   }
               }
           }

           // --- BİLDİRİM (NOTIFICATION) - DETAYLI VE EMOJİLİ ---
           string trade_msg2 = msg2; // Bölüm 2'nin sonuna işlem sınırlarını ekle
           trade_msg2 += "💰 İŞLEM SEVİYELERİ:\n";
           trade_msg2 += "   └ Entry (Giriş): " + DoubleToString(entry, 5) + "\n";
           trade_msg2 += "   └ Stop Loss: " + DoubleToString(sl, 5) + "\n";
           trade_msg2 += "   └ Take Profit: " + DoubleToString(tp, 5) + "\n";
           trade_msg2 += "===================\n";

           if(InpAlertPopup) { Alert(msg1); Alert(trade_msg2); }
           if(InpAlertPush) { SendNotification(msg1); SendNotification(trade_msg2); }
           Print(msg1); Print(trade_msg2);

           // --- DOSYAYA YAZMA (EA İÇİN) ---
           if (InpEnableAutoTradeWriter) {
               string filename = "vol100_signal_" + Symbol() + ".txt";
               int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
               if (file_handle != INVALID_HANDLE) {
                   // Fiyat farklarını Puan (Point) cinsinden hesapla
                   double sl_dist_points = MathAbs(entry - sl) / Point();
                   double tp_dist_points = MathAbs(entry - tp) / Point();

                   // EA'ya direkt fiyat göndermek yerine Entry ve Mesafe gönderiyoruz
                   // Format: Sembol, Yön, Giriş Fiyatı, SL Mesafesi (Puan), TP Mesafesi (Puan)
                   string trade_cmd = Symbol() + "," + dir_str + "," + DoubleToString(entry, 5) + "," + DoubleToString(sl_dist_points, 0) + "," + DoubleToString(tp_dist_points, 0);
                   FileWrite(file_handle, trade_cmd);
                   FileClose(file_handle);
                   Print("✅ [AUTO-TRADE] EA İçin Sinyal Dosyası Gönderildi: ", trade_cmd, " (SL: ", DoubleToString(sl_dist_points,0), " Puan, TP: ", DoubleToString(tp_dist_points,0), " Puan)");
               } else {
                   Print("❌ [AUTO-TRADE] Sinyal Dosyası Oluşturulamadı! Hata Kodu: ", GetLastError());
               }
           }

           // Sanal İşlemi Başlat (Dosyaya yazılmasa bile arka planda takip eder)
           current_swing_trades++; // Aynı dalgadaki işlem sayısını artır
           g_virtual_trade_active = true;
           g_virtual_trade_dir = trigger_dir;
           g_virtual_sl = sl;
           g_virtual_tp = tp;
       if (current_swing_trades == 1) {
           g_virtual_last_entry_price = entry; // 1. işlemin giriş (kırılım) fiyatını kaydet
       }
           Print("🟢 [VIRTUAL TRADE] Sanal İşlem Takipli Başladı! Yön: ", dir_str, " SL: ", sl, " TP: ", tp);

       } else {
           string reason = (!is_deep_elastic) ? " (M1 Çekilmesi %40 seviyesine ulaşmadığı için sadece 1 işleme izin verildi)" : "";
           Print("⚠️ [TRADE LIMIT] Bu majör dalga için maksimum işlem limitine (" + IntegerToString(allowed_trades) + ") ulaşıldı" + reason + ".");
       }
   }
  }

string BuildDashboardText(double live_price)
  {
   string dash = "\n";
   dash += "=========================================================\n";
   dash += "   " + Symbol() + " | Canlı Fiyat: " + DoubleToString(live_price, _Digits) + "\n";
   dash += "=========================================================\n";
   dash += "Zaman\tYön\tÇekilme\tMax Çek.\tHigh\t\tLow\n";
   dash += "---------------------------------------------------------\n";

   ENUM_TIMEFRAMES tfs[6] = {PERIOD_H1, PERIOD_M30, PERIOD_M15, PERIOD_M5, PERIOD_M3, PERIOD_M1};
   string tfs_str[6] = {"H1 ", "M30", "M15", "M5 ", "M3 ", "M1 "};

   for(int i = 0; i < 6; i++)
     {
      int trend = 0;
      double pct = 0;
      double max_pct = 0;
      double ref_h = 0, ref_l = 0;
      datetime ref_time = 0;

      if(tfs[i] == PERIOD_M1)
        {
         // M1 verilerini g_state_curr içinden doğrudan çek
         trend = g_state_curr.maj_tr;
         ref_h = g_state_curr.maj_h;
         ref_l = g_state_curr.maj_l;
         if (ref_h != EMPTY_VALUE && ref_l != EMPTY_VALUE && ref_h != ref_l) {
             double range = ref_h - ref_l;
             if (trend == 1) {
                 pct = ((ref_h - live_price) / range) * 100.0;
                 max_pct = ((ref_h - g_state_curr.tmp_l) / range) * 100.0;
                 if (live_price >= ref_h) pct = 0;
             } else {
                 pct = ((live_price - ref_l) / range) * 100.0;
                 max_pct = ((g_state_curr.tmp_h - ref_l) / range) * 100.0;
                 if (live_price <= ref_l) pct = 0;
             }
             if (pct < 0) pct = 0;
             if (max_pct < 0) max_pct = 0;
             if (max_pct < pct) max_pct = pct;
         }
         string dir_str = (trend == 1) ? "YUKARI" : ((trend == -1) ? "AŞAĞI " : "YATAY ");
         dash += tfs_str[i] + "\t" + dir_str + "\t%" + DoubleToString(pct, 2) + "\t%" + DoubleToString(max_pct, 2) + "\t" + DoubleToString(ref_h, _Digits) + "\t" + DoubleToString(ref_l, _Digits) + "\n";
        }
      else
        {
         // Diğer zaman aralıklarını Global Variables'dan oku
         string base_name = "5parite_" + Symbol() + "_" + EnumToString(tfs[i]) + "_";
         if(GlobalVariableCheck(base_name + "Trend") &&
            GlobalVariableCheck(base_name + "Pct") &&
            GlobalVariableCheck(base_name + "MaxPct") &&
            GlobalVariableCheck(base_name + "High") &&
            GlobalVariableCheck(base_name + "Low") &&
            GlobalVariableCheck(base_name + "Time"))
           {
            trend = (int)GlobalVariableGet(base_name + "Trend");
            pct = GlobalVariableGet(base_name + "Pct");
            max_pct = GlobalVariableGet(base_name + "MaxPct");
            ref_h = GlobalVariableGet(base_name + "High");
            ref_l = GlobalVariableGet(base_name + "Low");
            ref_time = (datetime)GlobalVariableGet(base_name + "Time");

            // Eğer veri 5 dakikadan eskiyse güncel değil olarak işaretle
            if (TimeCurrent() - ref_time > 300) {
                 dash += tfs_str[i] + "\t[ESKİ]\t-\t-\t-\t-\n";
            } else {
                 string dir_str = (trend == 1) ? "YUKARI" : ((trend == -1) ? "AŞAĞI " : "YATAY ");
                 dash += tfs_str[i] + "\t" + dir_str + "\t%" + DoubleToString(pct, 2) + "\t%" + DoubleToString(max_pct, 2) + "\t" + DoubleToString(ref_h, _Digits) + "\t" + DoubleToString(ref_l, _Digits) + "\n";
            }
           }
         else
           {
            dash += tfs_str[i] + "\t[YOK]\t-\t-\t-\t-\n";
           }
        }
     }

   dash += "=========================================================\n";
   return dash;
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
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {
                  if (draw_ui && Period() == PERIOD_M1) {
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
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {
                  if (draw_ui && Period() == PERIOD_M1) {
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
//| Global Variables Updater                                         |
//+------------------------------------------------------------------+
void UpdateGlobalVariables(int last_idx, const double &close[], const datetime &time[])
  {
   string sym = Symbol();
   string tf_str = EnumToString(Period());
   string base_name = "5parite_" + sym + "_" + tf_str + "_";

   int live_tr = g_state_curr.maj_tr;
   double live_pct = 0.0;
   double max_pct = 0.0;
   double h = g_state_curr.maj_h;
   double l = g_state_curr.maj_l;
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   if (h != EMPTY_VALUE && l != EMPTY_VALUE && h != l) {
       double range = h - l;
       if (live_tr == 1) {
           live_pct = ((h - bid) / range) * 100.0;
           max_pct = ((h - g_state_curr.tmp_l) / range) * 100.0;
           if (bid >= h) live_pct = 0;
       } else {
           live_pct = ((bid - l) / range) * 100.0;
           max_pct = ((g_state_curr.tmp_h - l) / range) * 100.0;
           if (bid <= l) live_pct = 0;
       }
       if (live_pct < 0) live_pct = 0;
       if (max_pct < 0) max_pct = 0;
       if (max_pct < live_pct) max_pct = live_pct;
   }

   GlobalVariableSet(base_name + "Trend", (double)live_tr);
   GlobalVariableSet(base_name + "Pct", live_pct);
   GlobalVariableSet(base_name + "MaxPct", max_pct);
   GlobalVariableSet(base_name + "High", h);
   GlobalVariableSet(base_name + "Low", l);
   GlobalVariableSet(base_name + "Time", (double)TimeCurrent());
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

   if(last_idx >= 0)
     {
      // Force Global Variable update so Master on M1 instantly sees fresh data
      UpdateGlobalVariables(last_idx, close, time);
     }

   if(InpShowDashboard)
     {
      uint current_tick = GetTickCount();
      if(current_tick - g_last_dash_tick > 1000)
        {
         g_last_dash_tick = current_tick;
         if(Period() == PERIOD_M1)
           {
            string dash_text = BuildDashboardText(SymbolInfoDouble(Symbol(), SYMBOL_BID));
            Comment(dash_text);
           }
         else
           {
            Comment(">>> 5parite MTF Sender Aktif (Zaman: ", EnumToString(Period()), ") <<<");
           }
        }
     }
   else
     {
      Comment("");
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
               g_virtual_last_outcome = -1;
               g_virtual_last_sl_price = g_virtual_sl;
               g_virtual_trade_active = false;
           } else if (live_bid >= g_virtual_tp) {
               Print("🟢 [VIRTUAL TRADE] BUY İşlemi Sanal TP Oldu! Yeni işlem hakkı açıldı.");
               g_virtual_last_outcome = 1;
               g_virtual_trade_active = false;
           }
       } else if (g_virtual_trade_dir == -1) { // SELL Trade
           if (live_ask >= g_virtual_sl) {
               Print("🔴 [VIRTUAL TRADE] SELL İşlemi Sanal SL Oldu! Yeni işlem hakkı açıldı.");
               g_virtual_last_outcome = -1;
               g_virtual_last_sl_price = g_virtual_sl;
               g_virtual_trade_active = false;
           } else if (live_ask <= g_virtual_tp) {
               Print("🟢 [VIRTUAL TRADE] SELL İşlemi Sanal TP Oldu! Yeni işlem hakkı açıldı.");
               g_virtual_last_outcome = 1;
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
            g_last_alert_maj_h = g_state_hist.maj_h;
            g_last_alert_maj_l = g_state_hist.maj_l;
            g_last_alert_trend = g_state_hist.maj_tr;
           }
     }

   // 🧪 TEST TRIGGER EXECUTION (Toggled by User)
   if (last_idx > 0 && Period() == PERIOD_M1) {
       // Sadece InpTestTradeExecution durumu FALSE'tan TRUE'ya geçtiğinde (Tetiklendiğinde) 1 kez çalışır
       if (InpTestTradeExecution && !g_prev_test_state) {
           double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
           int test_choch_dir = g_state_curr.maj_tr;
           double live_pct = 0.0;

           if (g_state_curr.maj_h != EMPTY_VALUE && g_state_curr.maj_l != EMPTY_VALUE && g_state_curr.maj_h != g_state_curr.maj_l) {
               double range = g_state_curr.maj_h - g_state_curr.maj_l;
               if (test_choch_dir == 1) {
                   live_pct = ((g_state_curr.maj_h - bid) / range) * 100.0;
                   if (bid >= g_state_curr.maj_h) live_pct = 0;
               } else if (test_choch_dir == -1) {
                   live_pct = ((bid - g_state_curr.maj_l) / range) * 100.0;
                   if (bid <= g_state_curr.maj_l) live_pct = 0;
               }
               if (live_pct < 0) live_pct = 0;
           }

           // Gerçek algoritmaya tamamen gerçek verilerle TEST emri yolla (Sahte veri yok)
           EvaluateTradeSignal(last_idx, TimeCurrent(), bid, test_choch_dir, live_pct, true, bid, true);
       }
       // Mevcut durumu kaydet (Bir sonraki tick'te tekrar atmasını engeller, kapatıp açılmayı bekler)
       g_prev_test_state = InpTestTradeExecution;
   }

   return(rates_total);
  }