//+------------------------------------------------------------------+
//|                                             mt5destekdirencm.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

// --- Inputs ---
input double i_days = 1.0; // Lookback Days (Main)
input double i_minPullbackPct = 40.0; // Min Pullback %
input double i_maxPullbackPct = 100.0; // Max Pullback %
input color c_chochStrong = clrPurple; // CHoCH Strong Color
input color c_chochWeak = clrRed; // CHoCH Weak Color
input color c_chochPath = clrGray; // CHoCH Path Color
input bool i_showChoch = true; // Show CHoCH

input bool i_showMin = true; // Show Minor
input bool i_showMaj = true; // Show Major
input color c_min = clrRed; // Minor Color
input color c_bear = clrRed; // Bearish Major Color
input color c_bull = clrGreen; // Bullish Major Color

input double i_bigCandleMult = 1.6; // Big Candle Multiplier
input int i_baseMaxCandles = 5; // Base Max Candles
input int i_baseAvgLookback = 10; // Base Avg Lookback
input bool i_showBox = true; // Show Box
input bool i_boxTrendFilter = true; // Trend Filter for Boxes
input double i_minBreakoutPct = 50.0; // Min Breakout Distance %
input int i_minBaseHeightTicks = 0; // Min Base Height (Ticks)
input double i_maxBoxPct = 20.0; // Max Box Pct
input double i_weakZonePct = 50.0; // Weak Zone Pct
input color c_boxBull = clrBlue; // Bull Box Color
input color c_boxBear = clrRed; // Bear Box Color
input color c_weakBull = C'0,25,55'; // Weak Bull Box Color
input color c_weakBear = C'55,15,0'; // Weak Bear Box Color

// --- Classes ---
class CStackFloat
  {
private:
   double            m_vals[];
   int               m_size;
public:
                     CStackFloat() { m_size = 0; ArrayResize(m_vals, 0); }
                     ~CStackFloat() {}
   void              Push(double val) { m_size++; ArrayResize(m_vals, m_size); m_vals[m_size-1] = val; }
   void              Pop() { if(m_size > 0) { m_size--; ArrayResize(m_vals, m_size); } }
   double            Get(int index) { if(index >= 0 && index < m_size) return m_vals[index]; return 0.0; }
   void              Clear() { m_size = 0; ArrayResize(m_vals, 0); }
   int               Size() { return m_size; }
   void              CopyFrom(CStackFloat &other)
     {
      m_size = other.Size();
      ArrayResize(m_vals, m_size);
      for(int i=0; i<m_size; i++) m_vals[i] = other.Get(i);
     }
  };

class CStackInt
  {
private:
   int               m_vals[];
   int               m_size;
public:
                     CStackInt() { m_size = 0; ArrayResize(m_vals, 0); }
                     ~CStackInt() {}
   void              Push(int val) { m_size++; ArrayResize(m_vals, m_size); m_vals[m_size-1] = val; }
   void              Pop() { if(m_size > 0) { m_size--; ArrayResize(m_vals, m_size); } }
   int               Get(int index) { if(index >= 0 && index < m_size) return m_vals[index]; return 0; }
   void              Clear() { m_size = 0; ArrayResize(m_vals, 0); }
   int               Size() { return m_size; }
   void              CopyFrom(CStackInt &other)
     {
      m_size = other.Size();
      ArrayResize(m_vals, m_size);
      for(int i=0; i<m_size; i++) m_vals[i] = other.Get(i);
     }
  };

class CStackString
  {
private:
   string            m_vals[];
   int               m_size;
public:
                     CStackString() { m_size = 0; ArrayResize(m_vals, 0); }
                     ~CStackString() {}
   void              Push(string val) { m_size++; ArrayResize(m_vals, m_size); m_vals[m_size-1] = val; }
   void              Pop() { if(m_size > 0) { m_size--; ArrayResize(m_vals, m_size); } }
   string            Get(int index) { if(index >= 0 && index < m_size) return m_vals[index]; return ""; }
   void              Set(int index, string val) { if(index >= 0 && index < m_size) m_vals[index] = val; }
   void              Clear() { m_size = 0; ArrayResize(m_vals, 0); }
   int               Size() { return m_size; }
   void              Remove(int index)
     {
      if(index < 0 || index >= m_size) return;
      for(int i=index; i<m_size-1; i++) m_vals[i] = m_vals[i+1];
      m_size--;
      ArrayResize(m_vals, m_size);
     }
   void              CopyFrom(CStackString &other)
     {
      m_size = other.Size();
      ArrayResize(m_vals, m_size);
      for(int i=0; i<m_size; i++) m_vals[i] = other.Get(i);
     }
  };


CStackString g_live_objects;

void AddLiveObject(string name)
  {
   g_live_objects.Push(name);
  }

void ClearLiveObjects()
  {
   for(int i=0; i<g_live_objects.Size(); i++)
     {
      ObjectDelete(0, g_live_objects.Get(i));
     }
   g_live_objects.Clear();
  }

struct SState
  {
   int min_tr;
   int maj_tr;
   int maj_st;
   double min_h;
   int min_h_i;
   double min_l;
   int min_l_i;
   double trig_h;
   double trig_l;
   int lp_i;
   double lp_p;
   double maj_h;
   int maj_h_i;
   double maj_l;
   int maj_l_i;
   double tmp_h;
   int tmp_h_i;
   double tmp_l;
   int tmp_l_i;
   int anc_i;
   double anc_v;
   int bos_i;
   int bos_count;
   double mb_h;
   double mb_l;
   int mb_i;
   double t1_h;
   double t1_l;
   int t1_i;
   double d1_h;
   double d1_l;
   int d1_i;
   double t2_h;
   double t2_l;
   int t2_i;
   int choch_dir;
   bool swept_choch;
   int bx_phase;
   bool bx_extreme;
   double bx_swing_h;
   double bx_swing_l;

   bool has_pot_bull_minor;
   int pot_bull_start_i;
   double pot_bull_start_p;
   double pot_bull_end_p;
   bool has_pot_bear_minor;
   int pot_bear_start_i;
   double pot_bear_start_p;
   double pot_bear_end_p;

   CStackString active_boxes;
   CStackString active_wk_abv;
   CStackString active_wk_blw;
   CStackFloat active_box_top;
   CStackFloat active_box_bot;

   CStackFloat st_h_val;
   CStackInt st_h_idx;
   CStackFloat st_l_val;
   CStackInt st_l_idx;

   void CopyFrom(SState &other)
     {
      min_tr = other.min_tr;
      maj_tr = other.maj_tr;
      maj_st = other.maj_st;
      min_h = other.min_h;
      min_h_i = other.min_h_i;
      min_l = other.min_l;
      min_l_i = other.min_l_i;
      trig_h = other.trig_h;
      trig_l = other.trig_l;
      lp_i = other.lp_i;
      lp_p = other.lp_p;
      maj_h = other.maj_h;
      maj_h_i = other.maj_h_i;
      maj_l = other.maj_l;
      maj_l_i = other.maj_l_i;
      tmp_h = other.tmp_h;
      tmp_h_i = other.tmp_h_i;
      tmp_l = other.tmp_l;
      tmp_l_i = other.tmp_l_i;
      anc_i = other.anc_i;
      anc_v = other.anc_v;
      bos_i = other.bos_i;
      bos_count = other.bos_count;
      mb_h = other.mb_h;
      mb_l = other.mb_l;
      mb_i = other.mb_i;
      t1_h = other.t1_h;
      t1_l = other.t1_l;
      t1_i = other.t1_i;
      d1_h = other.d1_h;
      d1_l = other.d1_l;
      d1_i = other.d1_i;
      t2_h = other.t2_h;
      t2_l = other.t2_l;
      t2_i = other.t2_i;
      choch_dir = other.choch_dir;
      swept_choch = other.swept_choch;
      bx_phase = other.bx_phase;
      bx_extreme = other.bx_extreme;
      bx_swing_h = other.bx_swing_h;
      bx_swing_l = other.bx_swing_l;

      has_pot_bull_minor = other.has_pot_bull_minor;
      pot_bull_start_i = other.pot_bull_start_i;
      pot_bull_start_p = other.pot_bull_start_p;
      pot_bull_end_p = other.pot_bull_end_p;
      has_pot_bear_minor = other.has_pot_bear_minor;
      pot_bear_start_i = other.pot_bear_start_i;
      pot_bear_start_p = other.pot_bear_start_p;
      pot_bear_end_p = other.pot_bear_end_p;

      active_boxes.CopyFrom(other.active_boxes);
      active_wk_abv.CopyFrom(other.active_wk_abv);
      active_wk_blw.CopyFrom(other.active_wk_blw);
      active_box_top.CopyFrom(other.active_box_top);
      active_box_bot.CopyFrom(other.active_box_bot);

      st_h_val.CopyFrom(other.st_h_val);
      st_h_idx.CopyFrom(other.st_h_idx);
      st_l_val.CopyFrom(other.st_l_val);
      st_l_idx.CopyFrom(other.st_l_idx);
     }
  };

SState g_state_hist;
SState g_state_curr;


int g_min_counter = 0;
int g_maj_counter = 0;
int g_choch_counter = 0;
int g_box_counter = 0;

bool g_is_live = false;

// --- Helper Functions ---
void DrawLine(string name, datetime time1, double price1, datetime time2, double price2, color clr, int width, ENUM_LINE_STYLE style, bool ray_right=false)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
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
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   if(g_is_live) AddLiveObject(name);
  }

void DrawMinorLine(datetime time1, double price1, datetime time2, double price2)
  {
   if(!i_showMin) return;
   if(!g_is_live) g_min_counter = (g_min_counter + 1) % 5000;
   static int live_min_sub = 0;
   if(g_is_live) live_min_sub++;
   string name = "str_min_" + IntegerToString(g_is_live ? (999000 + (live_min_sub%1000)) : g_min_counter);
   DrawLine(name, time1, price1, time2, price2, c_min, 1, STYLE_SOLID);
  }

void DrawMajorLine(datetime time1, double price1, datetime time2, double price2, color clr)
  {
   if(!i_showMaj) return;
   if(!g_is_live) g_maj_counter = (g_maj_counter + 1) % 5000;
   static int live_maj_sub = 0;
   if(g_is_live) live_maj_sub++;
   string name = "str_maj_" + IntegerToString(g_is_live ? (999000 + (live_maj_sub%1000)) : g_maj_counter);
   DrawLine(name, time1, price1, time2, price2, clr, 2, STYLE_SOLID);
  }

void DrawChochLine(datetime time1, double price1, datetime time2, double price2, bool is_strong, datetime path_t1, double path_p1)
  {
   if(!i_showChoch) return;
   if(!g_is_live) g_choch_counter = (g_choch_counter + 1) % 5000;
   static int live_choch_sub = 0;
   if(g_is_live) live_choch_sub++;
   string name = "str_choch_" + IntegerToString(g_is_live ? (999000 + (live_choch_sub%1000)) : g_choch_counter);
   color clr = is_strong ? c_chochStrong : c_chochWeak;
   DrawLine(name, time1, price1, time2, price2, clr, 3, STYLE_SOLID);

   string path_name = "str_choch_path_" + IntegerToString(g_is_live ? (999000 + (live_choch_sub%1000)) : g_choch_counter);
   DrawLine(path_name, path_t1, path_p1, time1, price1, c_chochPath, 1, STYLE_DOT);
  }

string DrawBox(datetime time1, double price1, datetime time2, double price2, color border_clr, color bg_clr)
  {
   if(!g_is_live) g_box_counter = (g_box_counter + 1) % 15000;
   static int live_box_sub = 0;
   if(g_is_live) live_box_sub++;
   string name = "bx_" + IntegerToString(g_is_live ? (999000 + (live_box_sub%1000)) : g_box_counter);
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price2);
     }
   ObjectSetInteger(0, name, OBJPROP_COLOR, border_clr);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_clr);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   if(g_is_live) AddLiveObject(name);
   return name;
  }

void UpdateBoxRight(string name, datetime time2)
  {
   if(ObjectFind(0, name) >= 0)
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
  }

void DeleteCustomObjects()
  {
   for(int i=ObjectsTotal(0)-1; i>=0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, "str_") == 0 || StringFind(name, "bx_") == 0)
         ObjectDelete(0, name);
     }
  }

int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   DeleteCustomObjects();
  }

// --- Main Calculation ---
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
   if(rates_total < i_baseAvgLookback + i_baseMaxCandles + 2) return 0;

   ArraySetAsSeries(time, false);
   ArraySetAsSeries(open, false);
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(close, false);

   int limit = prev_calculated == 0 ? 0 : prev_calculated - 1;
   if(prev_calculated == 0)
     {
      DeleteCustomObjects();

      // Init state
      g_state_hist.min_tr = close[0] > open[0] ? 1 : -1;
      g_state_hist.maj_tr = g_state_hist.min_tr;
      g_state_hist.maj_st = 1;
      g_state_hist.min_h = high[0];
      g_state_hist.min_h_i = 0;
      g_state_hist.min_l = low[0];
      g_state_hist.min_l_i = 0;
      g_state_hist.trig_h = high[0];
      g_state_hist.trig_l = low[0];
      g_state_hist.tmp_h = high[0];
      g_state_hist.tmp_h_i = 0;
      g_state_hist.tmp_l = low[0];
      g_state_hist.tmp_l_i = 0;
      g_state_hist.anc_i = 0;
      g_state_hist.anc_v = close[0];
      g_state_hist.lp_i = 0;
      g_state_hist.lp_p = close[0];
      g_state_hist.bos_i = 0;
      g_state_hist.bos_count = 0;
      g_state_hist.mb_h = high[0];
      g_state_hist.mb_l = low[0];
      g_state_hist.mb_i = 0;
      g_state_hist.t1_h = 0; g_state_hist.t1_l = 0; g_state_hist.t1_i = 0;
      g_state_hist.d1_h = 0; g_state_hist.d1_l = 0; g_state_hist.d1_i = 0;
      g_state_hist.t2_h = 0; g_state_hist.t2_l = 0; g_state_hist.t2_i = 0;
      g_state_hist.choch_dir = 0;
      g_state_hist.bx_phase = 0;
      g_state_hist.bx_extreme = false;
      g_state_hist.bx_swing_l = low[0];
      g_state_hist.bx_swing_h = high[0];

      double atr = (high[0]-low[0]) == 0 ? 10 * _Point : high[0]-low[0];
      g_state_hist.maj_h = high[0] + atr*0.1;
      g_state_hist.maj_l = low[0] - atr*0.1;

      g_state_hist.active_boxes.Clear();
      g_state_hist.active_wk_abv.Clear();
      g_state_hist.active_wk_blw.Clear();
      g_state_hist.active_box_top.Clear();
      g_state_hist.active_box_bot.Clear();
      g_state_hist.st_h_val.Clear();
      g_state_hist.st_h_idx.Clear();
      g_state_hist.st_l_val.Clear();
      g_state_hist.st_l_idx.Clear();

      g_min_counter = 0;
      g_maj_counter = 0;
      g_choch_counter = 0;
      g_box_counter = 0;

      limit = 1;
     }

   ClearLiveObjects();
   for(int i = limit; i < rates_total; i++)
     {
      bool is_live = (i == rates_total - 1);
      g_is_live = is_live;
      g_state_curr.CopyFrom(g_state_hist);

      double c_h = high[i];
      double c_l = low[i];
      double c_c = close[i];
      double c_o = open[i];

      bool is_inside = c_h <= g_state_curr.mb_h && c_l >= g_state_curr.mb_l;

      if(!is_inside)
        {
         if(c_h > g_state_curr.mb_h || c_l < g_state_curr.mb_l)
           {
            g_state_curr.mb_h = c_h;
            g_state_curr.mb_l = c_l;
            g_state_curr.mb_i = i;
           }

         double val_h = c_h;
         double val_l = c_l;
         double val_c = c_c;

         // --- Box Trimming & Creation ---
         if(i_showBox)
           {
            // Trim
            for(int k = g_state_curr.active_boxes.Size() - 1; k >= 0; k--)
              {
               double top = g_state_curr.active_box_top.Get(k);
               double bot = g_state_curr.active_box_bot.Get(k);
               if(val_h >= bot && val_l <= top)
                 {
                  UpdateBoxRight(g_state_curr.active_boxes.Get(k), time[i]);
                  UpdateBoxRight(g_state_curr.active_wk_abv.Get(k), time[i]);
                  UpdateBoxRight(g_state_curr.active_wk_blw.Get(k), time[i]);

                  g_state_curr.active_boxes.Remove(k);
                  g_state_curr.active_wk_abv.Remove(k);
                  g_state_curr.active_wk_blw.Remove(k);

                  CStackFloat temp_top, temp_bot;
                  for(int m=0; m<g_state_curr.active_box_top.Size(); m++)
                    {
                     if(m != k) { temp_top.Push(g_state_curr.active_box_top.Get(m)); temp_bot.Push(g_state_curr.active_box_bot.Get(m)); }
                    }
                  g_state_curr.active_box_top.CopyFrom(temp_top);
                  g_state_curr.active_box_bot.CopyFrom(temp_bot);
                 }
               else
                 {
                  datetime end_t = time[i] + PeriodSeconds()*5;
                  UpdateBoxRight(g_state_curr.active_boxes.Get(k), end_t);
                  UpdateBoxRight(g_state_curr.active_wk_abv.Get(k), end_t);
                  UpdateBoxRight(g_state_curr.active_wk_blw.Get(k), end_t);
                 }
              }

            // Create
            if(i > i_baseAvgLookback + i_baseMaxCandles)
            {
               double sum_body = 0;
               for(int j=1; j<=i_baseAvgLookback; j++)
                  sum_body += MathAbs(close[i-j] - open[i-j]);
            double avg_body = sum_body / i_baseAvgLookback;

            if(avg_body > 0)
              {
               double cur_body = MathAbs(c_c - c_o);
               if(cur_body > avg_body * i_bigCandleMult)
                 {
                  bool is_bullish = c_c > c_o;
                  int base_start = 1;
                  int base_count = 0;
                  double box_top = -1.0;
                  double box_bot = -1.0;

                  while(base_count < i_baseMaxCandles && base_start <= i_baseAvgLookback + i_baseMaxCandles)
                    {
                     double body = MathAbs(close[i-base_start] - open[i-base_start]);
                     if(body < avg_body)
                       {
                        if(box_top == -1.0 || high[i-base_start] > box_top) box_top = high[i-base_start];
                        if(box_bot == -1.0 || low[i-base_start] < box_bot) box_bot = low[i-base_start];
                        base_count++;
                        base_start++;
                       }
                     else break;
                    }

                  bool strong_breakout = false;
                  if(base_count > 0)
                    {
                     double base_height = box_top - box_bot;
                     bool is_base_large_enough = (base_height / _Point) >= i_minBaseHeightTicks;

                     if(is_base_large_enough)
                       {
                        double req_break_dist = base_height * (i_minBreakoutPct / 100.0);
                        if(is_bullish && (c_c - box_top) >= req_break_dist)
                          {
                           if(!i_boxTrendFilter || g_state_curr.maj_tr == 1) strong_breakout = true;
                          }
                        if(!is_bullish && (box_bot - c_c) >= req_break_dist)
                          {
                           if(!i_boxTrendFilter || g_state_curr.maj_tr == -1) strong_breakout = true;
                          }
                       }
                    }

                  bool is_overlapping = false;
                  if(strong_breakout && g_state_curr.active_box_top.Size() > 0)
                    {
                     for(int k=0; k<g_state_curr.active_box_top.Size(); k++)
                       {
                        double a_top = g_state_curr.active_box_top.Get(k);
                        double a_bot = g_state_curr.active_box_bot.Get(k);
                        if(!(box_top < a_bot || box_bot > a_top)) { is_overlapping = true; break; }
                       }
                    }

                  if(strong_breakout && !is_overlapping)
                    {
                     color box_clr = is_bullish ? c_boxBull : c_boxBear;
                     color wk_clr = is_bullish ? c_weakBull : c_weakBear;
                     double wk_sz = (box_top - box_bot) * i_weakZonePct / 100.0;

                     datetime start_t = time[i-base_start+1];
                     datetime end_t = time[i] + PeriodSeconds()*5;

                     string b_main = DrawBox(start_t, box_top, end_t, box_bot, box_clr, box_clr); // Should use rgba but mt5 colors differ
                     string b_abv = DrawBox(start_t, box_top + wk_sz, end_t, box_top, wk_clr, wk_clr);
                     string b_blw = DrawBox(start_t, box_bot, end_t, box_bot - wk_sz, wk_clr, wk_clr);

                     g_state_curr.active_boxes.Push(b_main);
                     g_state_curr.active_wk_abv.Push(b_abv);
                     g_state_curr.active_wk_blw.Push(b_blw);
                     g_state_curr.active_box_top.Push(box_top);
                     g_state_curr.active_box_bot.Push(box_bot);
                    }
                 }
              }
            }
           }

         // Pullback Pct calculation
         double ch_h = g_state_curr.maj_h;
         double ch_l = g_state_curr.maj_l;
         if(g_state_curr.maj_st == 0)
           {
            if(g_state_curr.maj_tr == 1) ch_h = g_state_curr.tmp_h;
            if(g_state_curr.maj_tr == -1) ch_l = g_state_curr.tmp_l;
           }
         double rng = ch_h - ch_l;
         bool in_pb = false;

         if(rng > 0)
           {
            double pb_pct = 0.0;
            if(g_state_curr.maj_tr == 1) pb_pct = ((ch_h - val_l) / rng) * 100.0;
            else if(g_state_curr.maj_tr == -1) pb_pct = ((val_h - ch_l) / rng) * 100.0;

            in_pb = (pb_pct >= i_minPullbackPct && pb_pct <= i_maxPullbackPct);
           }

         // Minor Structure Logic
         if(g_state_curr.min_tr == 1)
           {
            double ob = g_state_curr.trig_l;
            if(val_h > g_state_curr.min_h)
              {
               g_state_curr.min_h = val_h;
               g_state_curr.min_h_i = i;
               g_state_curr.trig_l = val_l;
              }
            if(val_l < ob)
              {
               int ti = g_state_curr.min_h_i;
               double tp = g_state_curr.min_h;
               int si = g_state_curr.lp_i;
               double sp = g_state_curr.lp_p;
               DrawMinorLine(time[si], sp, time[ti], tp);

               if(g_state_curr.maj_tr == -1 && !g_state_curr.has_pot_bull_minor && si >= g_state_curr.tmp_l_i)
                 {
                  g_state_curr.has_pot_bull_minor = true;
                  g_state_curr.pot_bull_start_i = si;
                  g_state_curr.pot_bull_start_p = sp;
                  g_state_curr.pot_bull_end_p = tp;
                 }

               if(g_state_curr.maj_st == 0 && g_state_curr.maj_tr == -1 && g_state_curr.bx_phase == 1)
                 {
                  if(g_state_curr.bx_extreme && tp > g_state_curr.bx_swing_h)
                    {
                     g_state_curr.bx_phase = 2;
                     g_state_curr.bx_extreme = false;
                    }
                  else g_state_curr.bx_swing_h = tp;
                 }

               g_state_curr.st_h_val.Push(tp);
               g_state_curr.st_h_idx.Push(ti);

               if(g_state_curr.maj_tr == 1 && g_state_curr.maj_st == 0 && tp < g_state_curr.tmp_h && g_state_curr.st_l_val.Size() > 0)
                 {
                  if(g_state_curr.st_l_idx.Get(g_state_curr.st_l_idx.Size()-1) > g_state_curr.bos_i)
                    {
                     g_state_curr.st_l_val.Pop();
                     g_state_curr.st_l_idx.Pop();
                    }
                 }

               if(g_state_curr.choch_dir == -1 && g_state_curr.t2_h != 0) g_state_curr.choch_dir = 0;
               if(g_state_curr.choch_dir == 1 && g_state_curr.t2_l != 0 && g_state_curr.min_h <= g_state_curr.d1_h) g_state_curr.choch_dir = 0;
               if(g_state_curr.choch_dir != 0 && !in_pb) g_state_curr.choch_dir = 0;

               if(g_state_curr.maj_tr == -1 && in_pb)
                 {
                  if(g_state_curr.choch_dir == 0 || g_state_curr.choch_dir == 1)
                    {
                     g_state_curr.t1_h = g_state_curr.min_h;
                     g_state_curr.t1_l = g_state_curr.min_l;
                     g_state_curr.t1_i = g_state_curr.min_h_i;
                     g_state_curr.d1_h = 0; g_state_curr.d1_l = 0; g_state_curr.d1_i = 0;
                     g_state_curr.t2_h = 0; g_state_curr.t2_l = 0; g_state_curr.t2_i = 0;
                     g_state_curr.choch_dir = -1;
                    }
                  else if(g_state_curr.choch_dir == -1)
                    {
                     if(g_state_curr.d1_l == 0)
                       {
                        g_state_curr.d1_l = g_state_curr.min_l;
                        g_state_curr.d1_i = g_state_curr.min_l_i;
                       }
                     if(g_state_curr.d1_l != 0 && g_state_curr.t2_h == 0)
                       {
                        g_state_curr.t2_h = g_state_curr.min_h;
                        g_state_curr.t2_i = g_state_curr.min_h_i;
                       }
                    }
                 }

               g_state_curr.min_tr = -1;
               g_state_curr.lp_i = ti;
               g_state_curr.lp_p = tp;
               g_state_curr.min_l = val_l;
               g_state_curr.min_l_i = i;
               g_state_curr.trig_h = val_h;
              }
           }
         else
           {
            double ot = g_state_curr.trig_h;
            if(val_l < g_state_curr.min_l)
              {
               g_state_curr.min_l = val_l;
               g_state_curr.min_l_i = i;
               g_state_curr.trig_h = val_h;
              }
            if(val_h > ot)
              {
               int ti = g_state_curr.min_l_i;
               double tp = g_state_curr.min_l;
               int si = g_state_curr.lp_i;
               double sp = g_state_curr.lp_p;
               DrawMinorLine(time[si], sp, time[ti], tp);

               if(g_state_curr.maj_tr == 1 && !g_state_curr.has_pot_bear_minor && si >= g_state_curr.tmp_h_i)
                 {
                  g_state_curr.has_pot_bear_minor = true;
                  g_state_curr.pot_bear_start_i = si;
                  g_state_curr.pot_bear_start_p = sp;
                  g_state_curr.pot_bear_end_p = tp;
                 }

               if(g_state_curr.maj_st == 0 && g_state_curr.maj_tr == 1 && g_state_curr.bx_phase == 1)
                 {
                  if(g_state_curr.bx_extreme && tp < g_state_curr.bx_swing_l)
                    {
                     g_state_curr.bx_phase = 2;
                     g_state_curr.bx_extreme = false;
                    }
                  else g_state_curr.bx_swing_l = tp;
                 }

               g_state_curr.st_l_val.Push(tp);
               g_state_curr.st_l_idx.Push(ti);

               if(g_state_curr.maj_tr == -1 && g_state_curr.maj_st == 0 && tp > g_state_curr.tmp_l && g_state_curr.st_h_val.Size() > 0)
                 {
                  if(g_state_curr.st_h_idx.Get(g_state_curr.st_h_idx.Size()-1) > g_state_curr.bos_i)
                    {
                     g_state_curr.st_h_val.Pop();
                     g_state_curr.st_h_idx.Pop();
                    }
                 }

               if(g_state_curr.choch_dir == 1 && g_state_curr.t2_l != 0) g_state_curr.choch_dir = 0;
               if(g_state_curr.choch_dir == -1 && g_state_curr.t2_h != 0 && g_state_curr.min_l >= g_state_curr.d1_l) g_state_curr.choch_dir = 0;
               if(g_state_curr.choch_dir != 0 && !in_pb) g_state_curr.choch_dir = 0;

               if(g_state_curr.maj_tr == 1 && in_pb)
                 {
                  if(g_state_curr.choch_dir == 0 || g_state_curr.choch_dir == -1)
                    {
                     g_state_curr.t1_l = g_state_curr.min_l;
                     g_state_curr.t1_h = g_state_curr.min_h;
                     g_state_curr.t1_i = g_state_curr.min_l_i;
                     g_state_curr.d1_l = 0; g_state_curr.d1_h = 0; g_state_curr.d1_i = 0;
                     g_state_curr.t2_l = 0; g_state_curr.t2_h = 0; g_state_curr.t2_i = 0;
                     g_state_curr.choch_dir = 1;
                    }
                  else if(g_state_curr.choch_dir == 1)
                    {
                     if(g_state_curr.d1_h == 0)
                       {
                        g_state_curr.d1_h = g_state_curr.min_h;
                        g_state_curr.d1_i = g_state_curr.min_h_i;
                       }
                     if(g_state_curr.d1_h != 0 && g_state_curr.t2_l == 0)
                       {
                        g_state_curr.t2_l = g_state_curr.min_l;
                        g_state_curr.t2_i = g_state_curr.min_l_i;
                       }
                    }
                 }

               g_state_curr.min_tr = 1;
               g_state_curr.lp_i = ti;
               g_state_curr.lp_p = tp;
               g_state_curr.min_h = val_h;
               g_state_curr.min_h_i = i;
               g_state_curr.trig_l = val_l;
              }
           }

         // CHoCH Trigger
         if(g_state_curr.choch_dir == -1 && g_state_curr.t2_h != 0 && g_state_curr.d1_l != 0)
           {
            if(val_c < g_state_curr.d1_l && in_pb)
              {
               bool is_strong = g_state_curr.t2_h > g_state_curr.t1_h;
               DrawChochLine(time[i], g_state_curr.d1_l, time[i] + PeriodSeconds()*5, g_state_curr.d1_l, is_strong, time[g_state_curr.t1_i], g_state_curr.d1_l);
               g_state_curr.choch_dir = 0;
              }
           }
         if(g_state_curr.choch_dir == 1 && g_state_curr.t2_l != 0 && g_state_curr.d1_h != 0)
           {
            if(val_c > g_state_curr.d1_h && in_pb)
              {
               bool is_strong = g_state_curr.t2_l < g_state_curr.t1_l;
               DrawChochLine(time[i], g_state_curr.d1_h, time[i] + PeriodSeconds()*5, g_state_curr.d1_h, is_strong, time[g_state_curr.t1_i], g_state_curr.d1_h);
               g_state_curr.choch_dir = 0;
              }
           }

         // Major Structure
         if(g_state_curr.maj_tr == 1)
           {
            if(g_state_curr.maj_st == 0)
              {
               if(val_h > g_state_curr.tmp_h) { g_state_curr.tmp_h = val_h; g_state_curr.tmp_h_i = i; g_state_curr.has_pot_bear_minor = false; }
               if(g_state_curr.maj_l != 0 && val_l < g_state_curr.maj_l && val_c >= g_state_curr.maj_l) { g_state_curr.maj_l = val_l; g_state_curr.maj_l_i = i; }
               if(g_state_curr.maj_l != 0 && val_c < g_state_curr.maj_l)
                 {
                  g_state_curr.choch_dir = 0; g_state_curr.swept_choch = false;
                  g_state_curr.t1_h=0; g_state_curr.t1_l=0; g_state_curr.t1_i=0;
                  g_state_curr.d1_h=0; g_state_curr.d1_l=0; g_state_curr.d1_i=0;
                  g_state_curr.t2_h=0; g_state_curr.t2_l=0; g_state_curr.t2_i=0;
                  g_state_curr.maj_h = g_state_curr.tmp_h; g_state_curr.maj_h_i = g_state_curr.tmp_h_i;
                  g_state_curr.bos_i = i; g_state_curr.bos_count++;
                  DrawMajorLine(time[g_state_curr.anc_i], g_state_curr.anc_v, time[g_state_curr.maj_h_i], g_state_curr.maj_h, c_bull);
                  g_state_curr.st_l_val.Clear(); g_state_curr.st_l_idx.Clear();
                  g_state_curr.maj_st = 1;
                  g_state_curr.anc_i = g_state_curr.maj_h_i; g_state_curr.anc_v = g_state_curr.maj_h;
                  g_state_curr.tmp_l = val_l; g_state_curr.tmp_l_i = i;
                  g_state_curr.bx_phase = 0; g_state_curr.bx_swing_l = val_l; g_state_curr.bx_swing_h = g_state_curr.maj_h;
                 }
              }
            else if(g_state_curr.maj_st == 1)
              {
               if(val_l < g_state_curr.tmp_l) { g_state_curr.tmp_l = val_l; g_state_curr.tmp_l_i = i; g_state_curr.has_pot_bull_minor = false; }
               if(g_state_curr.maj_h != 0 && val_h > g_state_curr.maj_h && val_c <= g_state_curr.maj_h) { g_state_curr.maj_h = val_h; g_state_curr.maj_h_i = i; g_state_curr.swept_choch = true; }
               if(g_state_curr.maj_h != 0 && val_c > g_state_curr.maj_h)
                 {
                  g_state_curr.choch_dir = 0; g_state_curr.swept_choch = false;
                  g_state_curr.t1_h=0; g_state_curr.t1_l=0; g_state_curr.t1_i=0;
                  g_state_curr.d1_h=0; g_state_curr.d1_l=0; g_state_curr.d1_i=0;
                  g_state_curr.t2_h=0; g_state_curr.t2_l=0; g_state_curr.t2_i=0;
                  g_state_curr.maj_tr = -1; g_state_curr.maj_st = 0;
                  g_state_curr.bos_i = i; g_state_curr.bos_count = 0;
                  DrawMajorLine(time[g_state_curr.anc_i], g_state_curr.anc_v, time[g_state_curr.tmp_h_i], g_state_curr.tmp_h, c_bull);
                  g_state_curr.st_h_val.Clear(); g_state_curr.st_h_idx.Clear();
                  g_state_curr.anc_i = g_state_curr.tmp_h_i; g_state_curr.anc_v = g_state_curr.tmp_h;
                  g_state_curr.tmp_l = val_l; g_state_curr.tmp_l_i = i;
                  g_state_curr.maj_h = g_state_curr.tmp_h; g_state_curr.maj_h_i = g_state_curr.tmp_h_i;
                  g_state_curr.bx_phase = 0; g_state_curr.bx_swing_l = g_state_curr.tmp_h; g_state_curr.bx_swing_h = val_l;
                  g_state_curr.has_pot_bear_minor = false;
                 }
              }
           }
         else if(g_state_curr.maj_tr == -1)
           {
            if(g_state_curr.maj_st == 0)
              {
               if(val_l < g_state_curr.tmp_l) { g_state_curr.tmp_l = val_l; g_state_curr.tmp_l_i = i; g_state_curr.has_pot_bull_minor = false; }
               if(g_state_curr.maj_h != 0 && val_h > g_state_curr.maj_h && val_c <= g_state_curr.maj_h) { g_state_curr.maj_h = val_h; g_state_curr.maj_h_i = i; }
               if(g_state_curr.maj_h != 0 && val_c > g_state_curr.maj_h)
                 {
                  g_state_curr.choch_dir = 0; g_state_curr.swept_choch = false;
                  g_state_curr.t1_h=0; g_state_curr.t1_l=0; g_state_curr.t1_i=0;
                  g_state_curr.d1_h=0; g_state_curr.d1_l=0; g_state_curr.d1_i=0;
                  g_state_curr.t2_h=0; g_state_curr.t2_l=0; g_state_curr.t2_i=0;
                  g_state_curr.maj_l = g_state_curr.tmp_l; g_state_curr.maj_l_i = g_state_curr.tmp_l_i;
                  g_state_curr.bos_i = i; g_state_curr.bos_count++;
                  DrawMajorLine(time[g_state_curr.anc_i], g_state_curr.anc_v, time[g_state_curr.maj_l_i], g_state_curr.maj_l, c_bear);
                  g_state_curr.st_h_val.Clear(); g_state_curr.st_h_idx.Clear();
                  g_state_curr.maj_st = 1;
                  g_state_curr.anc_i = g_state_curr.maj_l_i; g_state_curr.anc_v = g_state_curr.maj_l;
                  g_state_curr.tmp_h = val_h; g_state_curr.tmp_h_i = i;
                  g_state_curr.bx_phase = 0; g_state_curr.bx_swing_l = g_state_curr.maj_l; g_state_curr.bx_swing_h = val_h;
                 }
              }
            else if(g_state_curr.maj_st == 1)
              {
               if(val_h > g_state_curr.tmp_h) { g_state_curr.tmp_h = val_h; g_state_curr.tmp_h_i = i; g_state_curr.has_pot_bear_minor = false; }
               if(g_state_curr.maj_l != 0 && val_l < g_state_curr.maj_l && val_c >= g_state_curr.maj_l) { g_state_curr.maj_l = val_l; g_state_curr.maj_l_i = i; }
               if(g_state_curr.maj_l != 0 && val_c < g_state_curr.maj_l)
                 {
                  g_state_curr.choch_dir = 0; g_state_curr.swept_choch = false;
                  g_state_curr.t1_h=0; g_state_curr.t1_l=0; g_state_curr.t1_i=0;
                  g_state_curr.d1_h=0; g_state_curr.d1_l=0; g_state_curr.d1_i=0;
                  g_state_curr.t2_h=0; g_state_curr.t2_l=0; g_state_curr.t2_i=0;
                  g_state_curr.maj_h = g_state_curr.tmp_h; g_state_curr.maj_h_i = g_state_curr.tmp_h_i;
                  g_state_curr.bos_i = i; g_state_curr.bos_count++;
                  DrawMajorLine(time[g_state_curr.anc_i], g_state_curr.anc_v, time[g_state_curr.maj_h_i], g_state_curr.maj_h, c_bear);
                  g_state_curr.st_l_val.Clear(); g_state_curr.st_l_idx.Clear();
                  g_state_curr.maj_st = 0;
                  g_state_curr.anc_i = g_state_curr.maj_h_i; g_state_curr.anc_v = g_state_curr.maj_h;
                  g_state_curr.tmp_l = val_l; g_state_curr.tmp_l_i = i;
                  g_state_curr.bx_phase = 0; g_state_curr.bx_swing_l = val_l; g_state_curr.bx_swing_h = g_state_curr.maj_h;
                 }
               if(g_state_curr.maj_h != 0 && val_h > g_state_curr.maj_h && val_c <= g_state_curr.maj_h) { g_state_curr.maj_h = val_h; g_state_curr.maj_h_i = i; g_state_curr.swept_choch = true; }
               if(g_state_curr.maj_h != 0 && val_c > g_state_curr.maj_h)
                 {
                  g_state_curr.choch_dir = 0; g_state_curr.swept_choch = false;
                  g_state_curr.t1_h=0; g_state_curr.t1_l=0; g_state_curr.t1_i=0;
                  g_state_curr.d1_h=0; g_state_curr.d1_l=0; g_state_curr.d1_i=0;
                  g_state_curr.t2_h=0; g_state_curr.t2_l=0; g_state_curr.t2_i=0;
                  g_state_curr.maj_tr = 1; g_state_curr.maj_st = 0;
                  g_state_curr.bos_i = i; g_state_curr.bos_count = 0;
                  DrawMajorLine(time[g_state_curr.anc_i], g_state_curr.anc_v, time[g_state_curr.tmp_l_i], g_state_curr.tmp_l, c_bear);
                  g_state_curr.st_h_val.Clear(); g_state_curr.st_h_idx.Clear();
                  g_state_curr.anc_i = g_state_curr.tmp_l_i; g_state_curr.anc_v = g_state_curr.tmp_l;
                  g_state_curr.tmp_h = val_h; g_state_curr.tmp_h_i = i;
                  g_state_curr.maj_l = g_state_curr.tmp_l; g_state_curr.maj_l_i = g_state_curr.tmp_l_i;
                  g_state_curr.bx_phase = 0; g_state_curr.bx_swing_l = g_state_curr.tmp_l; g_state_curr.bx_swing_h = val_h;
                  g_state_curr.has_pot_bull_minor = false;
                 }
              }
           }
        }

      if(is_live)
        {
         // Render dynamic live minor leg if necessary
         if(i_showMin)
           {
            if(g_state_curr.min_tr == 1)
               DrawMinorLine(time[g_state_curr.lp_i], g_state_curr.lp_p, time[g_state_curr.min_h_i], g_state_curr.min_h);
            else
               DrawMinorLine(time[g_state_curr.lp_i], g_state_curr.lp_p, time[g_state_curr.min_l_i], g_state_curr.min_l);
           }
        }
      else
        {
         // Finalize state for historical bars
         g_state_hist.CopyFrom(g_state_curr);
        }
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
