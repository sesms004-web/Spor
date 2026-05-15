//+------------------------------------------------------------------+
//|                                                    Structure.mq5 |
//|                          Sadece Görsel - Alert/Broadcast Yok     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

//--- Hesaplama Derinliği (Gün) ---
input double InpDaysM1   = 1.0;
input double InpDaysM3   = 3.0;
input double InpDaysM5   = 5.0;
input double InpDaysM15  = 15.0;
input double InpDaysM30  = 30.0;
input double InpDaysH1   = 60.0;
input double InpDaysH4   = 240.0;
input double InpDaysD1   = 1440.0;

//--- CHoCH Görsel Ayarları ---
input double InpMinPullbackPct   = 40.0;        // CHoCH Min Çekilme % (Bölge Filtresi)
input color  InpColorChochStrong = clrPurple;   // Güçlü CHoCH Rengi
input color  InpColorChochWeak   = clrRed;      // Zayıf CHoCH Rengi
input color  InpColorChochPath   = clrGray;     // T1-D1-T2 İz Rengi
input bool   InpShowChoch        = true;        // CHoCH Çizgilerini Göster

//--- Majör / Minör Görsel Ayarları ---
input bool   InpShowMin   = true;
input bool   InpShowMaj   = true;
input color  InpColorMin  = clrRed;
input color  InpColorBull = clrGreen;
input color  InpColorBear = clrRed;

//--- Globals ---
int      g_counter  = 0;
datetime g_anchor_time = 0;

//--- Çoklu İşlem Takibi (Etiket için) ---
double g_trade_t1_h[5];
double g_trade_t2_h[5];
int    g_trade_count_h  = 0;
int    g_current_maj_h_i = 0;

double g_trade_t1_l[5];
double g_trade_t2_l[5];
int    g_trade_count_l  = 0;
int    g_current_maj_l_i = 0;

void ResetBearishMemory() {
    g_trade_count_h = 0;
    for(int i=0;i<5;i++){ g_trade_t1_h[i]=0; g_trade_t2_h[i]=0; }
}
void ResetBullishMemory() {
    g_trade_count_l = 0;
    for(int i=0;i<5;i++){ g_trade_t1_l[i]=0; g_trade_t2_l[i]=0; }
}

//+------------------------------------------------------------------+
//| Yardımcı Fonksiyonlar                                            |
//+------------------------------------------------------------------+
datetime GetTimeSafe(const datetime &time_array[], int idx)
{
    if(idx >= 0 && idx < ArraySize(time_array)) return time_array[idx];
    return 0;
}

void DrawLine(string name, datetime time1, double price1, datetime time2, double price2,
              color clr, int width, ENUM_LINE_STYLE style, bool ray_right=false)
{
    if(ObjectFind(0, name) < 0)
        ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
    else {
        ObjectSetInteger(0, name, OBJPROP_TIME,  0, time1);
        ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, price1);
        ObjectSetInteger(0, name, OBJPROP_TIME,  1, time2);
        ObjectSetDouble(0,  name, OBJPROP_PRICE, 1, price2);
    }
    ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH,     width);
    ObjectSetInteger(0, name, OBJPROP_STYLE,     style);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, ray_right);
    ObjectSetInteger(0, name, OBJPROP_BACK,      true);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN,    true);
}

void DeleteLine(string name)
{
    if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
}

void CutLine(string name, datetime time_cut)
{
    if(ObjectFind(0, name) >= 0) {
        ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(0, name, OBJPROP_TIME, 1, time_cut);
    }
}

void UpdateLineLevel(string name, double level)
{
    if(ObjectFind(0, name) >= 0) {
        ObjectSetDouble(0, name, OBJPROP_PRICE, 0, level);
        ObjectSetDouble(0, name, OBJPROP_PRICE, 1, level);
    }
}

string GetUniqueName(string prefix)
{
    g_counter++;
    return prefix + IntegerToString(g_counter);
}

double GetDaysForTF(ENUM_TIMEFRAMES tf)
{
    if(tf == PERIOD_M1)  return InpDaysM1;
    if(tf == PERIOD_M3)  return InpDaysM3;
    if(tf == PERIOD_M5)  return InpDaysM5;
    if(tf == PERIOD_M15) return InpDaysM15;
    if(tf == PERIOD_M30) return InpDaysM30;
    if(tf == PERIOD_H1)  return InpDaysH1;
    if(tf == PERIOD_H4)  return InpDaysH4;
    if(tf == PERIOD_D1)  return InpDaysD1;
    return InpDaysM1;
}

//+------------------------------------------------------------------+
//| Stack Sınıfı                                                     |
//+------------------------------------------------------------------+
class CStack
{
private:
    double m_vals[];
    int    m_idx[];
public:
    CStack()  { ArrayResize(m_vals,0); ArrayResize(m_idx,0); }
    ~CStack() {}

    void   Clear() { ArrayResize(m_vals,0); ArrayResize(m_idx,0); }
    int    Size()  { return ArraySize(m_vals); }

    void   Push(double val, int idx)
    {
        int sz = ArraySize(m_vals);
        ArrayResize(m_vals, sz+1);
        ArrayResize(m_idx,  sz+1);
        m_vals[sz] = val;
        m_idx[sz]  = idx;
    }

    void   Pop()
    {
        int sz = ArraySize(m_vals);
        if(sz > 0) { ArrayResize(m_vals, sz-1); ArrayResize(m_idx, sz-1); }
    }

    double GetVal(int index) { return m_vals[index]; }
    int    GetIdx(int index) { return m_idx[index]; }

    void   CopyFrom(CStack &src)
    {
        ArrayCopy(m_vals, src.m_vals);
        ArrayCopy(m_idx,  src.m_idx);
    }
};

//+------------------------------------------------------------------+
//| Durum Struct                                                     |
//+------------------------------------------------------------------+
struct SState
{
    int    min_tr, maj_tr, maj_st;
    double min_h;  int min_h_i;
    double min_l;  int min_l_i;
    double trig_h, trig_l;
    int    lp_i;   double lp_p;
    double maj_h;  int maj_h_i;
    double maj_l;  int maj_l_i;
    double tmp_h;  int tmp_h_i;
    double tmp_l;  int tmp_l_i;
    int    anc_i;  double anc_v;
    int    bos_i;
    string cur_top_line, cur_bot_line;

    // Mother Bar
    double mb_h, mb_l;  int mb_i;

    // CHoCH Tracking
    double t1_h, t1_l;  int t1_i;
    double d1_h, d1_l;  int d1_i;
    double t2_h, t2_l;  int t2_i;
    int    choch_dir;

    // MTF CHoCH (kullanılmıyor ama CopyFrom uyumu için tutuldu)
    int      last_choch_dir;
    double   last_choch_level;
    datetime last_choch_time;
    int      last_choch_i;

    CStack st_h, st_l;

    void CopyFrom(SState &src)
    {
        min_tr = src.min_tr; maj_tr = src.maj_tr; maj_st = src.maj_st;
        min_h = src.min_h;   min_h_i = src.min_h_i;
        min_l = src.min_l;   min_l_i = src.min_l_i;
        trig_h = src.trig_h; trig_l = src.trig_l;
        lp_i = src.lp_i;     lp_p = src.lp_p;
        maj_h = src.maj_h;   maj_h_i = src.maj_h_i;
        maj_l = src.maj_l;   maj_l_i = src.maj_l_i;
        tmp_h = src.tmp_h;   tmp_h_i = src.tmp_h_i;
        tmp_l = src.tmp_l;   tmp_l_i = src.tmp_l_i;
        anc_i = src.anc_i;   anc_v = src.anc_v;
        bos_i = src.bos_i;
        cur_top_line = src.cur_top_line;
        cur_bot_line = src.cur_bot_line;
        mb_h = src.mb_h; mb_l = src.mb_l; mb_i = src.mb_i;
        t1_h = src.t1_h; t1_l = src.t1_l; t1_i = src.t1_i;
        d1_h = src.d1_h; d1_l = src.d1_l; d1_i = src.d1_i;
        t2_h = src.t2_h; t2_l = src.t2_l; t2_i = src.t2_i;
        choch_dir = src.choch_dir;
        last_choch_dir   = src.last_choch_dir;
        last_choch_level = src.last_choch_level;
        last_choch_time  = src.last_choch_time;
        last_choch_i     = src.last_choch_i;
        st_h.CopyFrom(src.st_h);
        st_l.CopyFrom(src.st_l);
    }
};

SState g_state_hist;
SState g_state_curr;

//+------------------------------------------------------------------+
//| Ana Bar İşleme                                                   |
//+------------------------------------------------------------------+
void ProcessBar(int i,
                const double &open[],  const double &high[],
                const double &low[],   const double &close[],
                const datetime &time[],
                SState &state,
                bool is_history,
                bool draw_ui = true)
{
    double val_h = high[i];
    double val_l = low[i];
    double val_c = close[i];

    string prefix = is_history ? "" : "Live_";

    // ── Çekilme yüzdesi hesabı (CHoCH bölge filtresi için) ──
    double cur_maj_h = state.maj_h;
    double cur_maj_l = state.maj_l;

    // Eğer majör yapı impuls aşamasındaysa (maj_st == 0),
    // aktif swing'in henüz kilitlenmemiş ucunu (tmp_h / tmp_l) kullan.
    if(state.maj_tr == 1 && state.maj_st == 0) cur_maj_h = state.tmp_h;
    if(state.maj_tr == -1 && state.maj_st == 0) cur_maj_l = state.tmp_l;

    double p_pct = 0;

    if(cur_maj_h != EMPTY_VALUE && cur_maj_l != EMPTY_VALUE && cur_maj_h != cur_maj_l)
    {
        double range = cur_maj_h - cur_maj_l;
        if(state.maj_tr == 1 && state.min_l >= cur_maj_l)
            p_pct = ((cur_maj_h - state.min_l) / range) * 100.0;
        else if(state.maj_tr == -1 && state.min_h <= cur_maj_h)
            p_pct = ((state.min_h - cur_maj_l) / range) * 100.0;
    }
    bool in_pullback_zone = (p_pct >= InpMinPullbackPct);

    // ══════════════════════════════════════════════════════════════
    //  MİNÖR YAPI
    // ══════════════════════════════════════════════════════════════
    if(state.min_tr == 1)
    {
        double old_trig = state.trig_l;
        if(val_h > state.min_h) { state.min_h = val_h; state.min_h_i = i; state.trig_l = val_l; }

        if(val_l < old_trig)
        {
            if(draw_ui && InpShowMin)
            {
                string name = GetUniqueName(prefix + "Minor_");
                DrawLine(name, GetTimeSafe(time, state.lp_i), state.lp_p,
                         GetTimeSafe(time, state.min_h_i), state.min_h, InpColorMin, 1, STYLE_SOLID);
            }
            state.st_h.Push(state.min_h, state.min_h_i);

            if(state.maj_tr == 1 && state.maj_st == 0 && state.min_h < state.tmp_h && state.st_l.Size() > 0)
                if(state.st_l.GetIdx(state.st_l.Size()-1) > state.bos_i) state.st_l.Pop();

            // CHoCH geçersizleştirme
            if(state.choch_dir == -1 && state.t2_h != 0)           state.choch_dir = 0;
            if(state.choch_dir ==  1 && state.t2_l != 0 && state.min_h <= state.d1_h) state.choch_dir = 0;

            // Bearish CHoCH T1-D1-T2 takibi
            if(state.maj_tr == -1 && in_pullback_zone)
            {
                if(state.choch_dir == 0 || state.choch_dir == 1)
                {
                    state.t1_h = state.min_h; state.t1_l = state.min_l; state.t1_i = state.min_h_i;
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
            state.lp_i   = state.min_h_i; state.lp_p = state.min_h;
            state.min_l  = val_l;         state.min_l_i = i;
            state.trig_h = val_h;
        }
    }
    else // min_tr == -1
    {
        double old_trig = state.trig_h;
        if(val_l < state.min_l) { state.min_l = val_l; state.min_l_i = i; state.trig_h = val_h; }

        if(val_h > old_trig)
        {
            if(draw_ui && InpShowMin)
            {
                string name = GetUniqueName(prefix + "Minor_");
                DrawLine(name, GetTimeSafe(time, state.lp_i), state.lp_p,
                         GetTimeSafe(time, state.min_l_i), state.min_l, InpColorMin, 1, STYLE_SOLID);
            }
            state.st_l.Push(state.min_l, state.min_l_i);

            if(state.maj_tr == -1 && state.maj_st == 0 && state.min_l > state.tmp_l && state.st_h.Size() > 0)
                if(state.st_h.GetIdx(state.st_h.Size()-1) > state.bos_i) state.st_h.Pop();

            // CHoCH geçersizleştirme
            if(state.choch_dir ==  1 && state.t2_l != 0)           state.choch_dir = 0;
            if(state.choch_dir == -1 && state.t2_h != 0 && state.min_l >= state.d1_l) state.choch_dir = 0;

            // Bullish CHoCH T1-D1-T2 takibi
            if(state.maj_tr == 1 && in_pullback_zone)
            {
                if(state.choch_dir == 0 || state.choch_dir == -1)
                {
                    state.t1_l = state.min_l; state.t1_h = state.min_h; state.t1_i = state.min_l_i;
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
            state.lp_i   = state.min_l_i; state.lp_p = state.min_l;
            state.min_h  = val_h;          state.min_h_i = i;
            state.trig_l = val_l;
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  CHoCH TETİKLEME & ÇİZİM
    // ══════════════════════════════════════════════════════════════

    // --- BEARISH CHoCH ---
    if(state.choch_dir == -1 && state.t2_h != 0 && state.d1_l != 0)
    {
        double range        = cur_maj_h - cur_maj_l;
        double level_40     = cur_maj_l + range * (InpMinPullbackPct / 100.0);
        bool   t2_valid     = (range > 0 && state.d1_l >= level_40 && state.t2_h >= level_40);
        bool   should_break = (val_c < state.d1_l);

        if(should_break)
        {
            if(!t2_valid)
            {
                state.choch_dir = 0;
                state.d1_l = 0;
                state.t2_h = 0;
            }
            else
            {
                state.last_choch_dir   = -1;
                state.last_choch_level = state.d1_l;
                state.last_choch_time  = time[i];

                bool is_strong = (state.t2_h > state.t1_h);

                if(draw_ui)
                {
                    static int last_d1_i_bear = 0;

                    if(state.maj_h_i != g_current_maj_h_i)
                    {
                        ResetBearishMemory();
                        g_current_maj_h_i = state.maj_h_i;
                    }

                    bool is_new = (state.d1_i != last_d1_i_bear);

                    // Sıra takibi (etiket numarası için)
                    int trade_idx = -1;
                    if(is_new)
                    {
                        bool valid_seq = false;
                        if(g_trade_count_h == 0) valid_seq = true;
                        else if(g_trade_count_h < 5)
                        {
                            double prev_peak = MathMax(g_trade_t1_h[g_trade_count_h-1], g_trade_t2_h[g_trade_count_h-1]);
                            if(state.t2_h > prev_peak) valid_seq = true;
                        }
                        if(valid_seq && g_trade_count_h < 5)
                        {
                            trade_idx = g_trade_count_h;
                            g_trade_t1_h[trade_idx] = state.t1_h;
                            g_trade_t2_h[trade_idx] = state.t2_h;
                            g_trade_count_h++;
                        }
                    }
                    else
                    {
                        for(int idx=0; idx<g_trade_count_h; idx++)
                            if(g_trade_t1_h[idx]==state.t1_h && g_trade_t2_h[idx]==state.t2_h)
                                { trade_idx = idx; break; }
                    }

                    if(is_new && trade_idx >= 0 && InpShowChoch)
                    {
                        color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

                        string p1 = GetUniqueName(prefix+"CHoCH_Path_");
                        DrawLine(p1, GetTimeSafe(time,state.t1_i), state.t1_h,
                                     GetTimeSafe(time,state.d1_i), state.d1_l,
                                     InpColorChochPath, 1, STYLE_DOT);

                        string p2 = GetUniqueName(prefix+"CHoCH_Path_");
                        DrawLine(p2, GetTimeSafe(time,state.d1_i), state.d1_l,
                                     GetTimeSafe(time,state.t2_i), state.t2_h,
                                     InpColorChochPath, 1, STYLE_DOT);

                        string p3 = GetUniqueName(prefix+"CHoCH_Path_");
                        DrawLine(p3, GetTimeSafe(time,state.t2_i), state.t2_h,
                                     GetTimeSafe(time,i),           state.d1_l,
                                     InpColorChochPath, 1, STYLE_DOT);

                        string sig_name = GetUniqueName(prefix+"CHoCH_Signal_");
                        DrawLine(sig_name,
                                 GetTimeSafe(time,i),                         state.d1_l,
                                 GetTimeSafe(time,i) + PeriodSeconds() * 5,   state.d1_l,
                                 sig_color, 3, STYLE_SOLID);

                        string txt_name = GetUniqueName(prefix+"CHoCH_Text_");
                        ObjectCreate(0, txt_name, OBJ_TEXT, 0, GetTimeSafe(time,i), state.d1_l);
                        ObjectSetString(0,  txt_name, OBJPROP_TEXT,     IntegerToString(trade_idx+1));
                        ObjectSetInteger(0, txt_name, OBJPROP_COLOR,    sig_color);
                        ObjectSetInteger(0, txt_name, OBJPROP_FONTSIZE, 10);
                        ObjectSetInteger(0, txt_name, OBJPROP_ANCHOR,   ANCHOR_RIGHT_UPPER);
                    }

                    if(is_new) last_d1_i_bear = state.d1_i;
                }

                state.choch_dir = 0;
            }
        }
    }

    // --- BULLISH CHoCH ---
    else if(state.choch_dir == 1 && state.t2_l != 0 && state.d1_h != 0)
    {
        double range        = cur_maj_h - cur_maj_l;
        double level_60     = cur_maj_l + range * (1.0 - InpMinPullbackPct / 100.0);
        bool   t2_valid     = (range > 0 && state.d1_h <= level_60 && state.t2_l <= level_60);
        bool   should_break = (val_c > state.d1_h);

        if(should_break)
        {
            if(!t2_valid)
            {
                state.choch_dir = 0;
                state.d1_h = 0;
                state.t2_l = 0;
            }
            else
            {
                state.last_choch_dir   = 1;
                state.last_choch_level = state.d1_h;
                state.last_choch_time  = time[i];

                bool is_strong = (state.t2_l < state.t1_l);

                if(draw_ui)
                {
                    static int last_d1_i_bull = 0;

                    if(state.maj_l_i != g_current_maj_l_i)
                    {
                        ResetBullishMemory();
                        g_current_maj_l_i = state.maj_l_i;
                    }

                    bool is_new = (state.d1_i != last_d1_i_bull);

                    int trade_idx = -1;
                    if(is_new)
                    {
                        bool valid_seq = false;
                        if(g_trade_count_l == 0) valid_seq = true;
                        else if(g_trade_count_l < 5)
                        {
                            double prev_dip = MathMin(g_trade_t1_l[g_trade_count_l-1], g_trade_t2_l[g_trade_count_l-1]);
                            if(state.t2_l < prev_dip) valid_seq = true;
                        }
                        if(valid_seq && g_trade_count_l < 5)
                        {
                            trade_idx = g_trade_count_l;
                            g_trade_t1_l[trade_idx] = state.t1_l;
                            g_trade_t2_l[trade_idx] = state.t2_l;
                            g_trade_count_l++;
                        }
                    }
                    else
                    {
                        for(int idx=0; idx<g_trade_count_l; idx++)
                            if(g_trade_t1_l[idx]==state.t1_l && g_trade_t2_l[idx]==state.t2_l)
                                { trade_idx = idx; break; }
                    }

                    if(is_new && trade_idx >= 0 && InpShowChoch)
                    {
                        color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

                        string p1 = GetUniqueName(prefix+"CHoCH_Path_");
                        DrawLine(p1, GetTimeSafe(time,state.t1_i), state.t1_l,
                                     GetTimeSafe(time,state.d1_i), state.d1_h,
                                     InpColorChochPath, 1, STYLE_DOT);

                        string p2 = GetUniqueName(prefix+"CHoCH_Path_");
                        DrawLine(p2, GetTimeSafe(time,state.d1_i), state.d1_h,
                                     GetTimeSafe(time,state.t2_i), state.t2_l,
                                     InpColorChochPath, 1, STYLE_DOT);

                        string p3 = GetUniqueName(prefix+"CHoCH_Path_");
                        DrawLine(p3, GetTimeSafe(time,state.t2_i), state.t2_l,
                                     GetTimeSafe(time,i),           state.d1_h,
                                     InpColorChochPath, 1, STYLE_DOT);

                        string sig_name = GetUniqueName(prefix+"CHoCH_Signal_");
                        DrawLine(sig_name,
                                 GetTimeSafe(time,i),                         state.d1_h,
                                 GetTimeSafe(time,i) + PeriodSeconds() * 5,   state.d1_h,
                                 sig_color, 3, STYLE_SOLID);

                        string txt_name = GetUniqueName(prefix+"CHoCH_Text_");
                        ObjectCreate(0, txt_name, OBJ_TEXT, 0, GetTimeSafe(time,i), state.d1_h);
                        ObjectSetString(0,  txt_name, OBJPROP_TEXT,     IntegerToString(trade_idx+1));
                        ObjectSetInteger(0, txt_name, OBJPROP_COLOR,    sig_color);
                        ObjectSetInteger(0, txt_name, OBJPROP_FONTSIZE, 10);
                        ObjectSetInteger(0, txt_name, OBJPROP_ANCHOR,   ANCHOR_RIGHT_LOWER);
                    }

                    if(is_new) last_d1_i_bull = state.d1_i;
                }

                state.choch_dir = 0;
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  MAJÖR YAPI
    // ══════════════════════════════════════════════════════════════
    if(state.maj_tr == 0)
    {
        state.maj_tr = 1;
        state.anc_i  = state.min_l_i;
        state.anc_v  = state.min_l;
        state.maj_l_i = state.min_l_i;
    }

    if(state.maj_tr == 1)
    {
        if(val_h > state.tmp_h) { state.tmp_h = val_h; state.tmp_h_i = i; }

        if(state.maj_st == 0)
        {
            double act = state.st_l.Size() > 0 ? state.st_l.GetVal(state.st_l.Size()-1) : EMPTY_VALUE;
            if(act != EMPTY_VALUE && val_l < act)
            {
                state.maj_h    = state.tmp_h;
                state.maj_h_i  = state.tmp_h_i;
                if(draw_ui && InpShowMaj)
                {
                    string name = GetUniqueName(prefix+"Major_");
                    DrawLine(name, GetTimeSafe(time,state.anc_i), state.anc_v,
                             GetTimeSafe(time,state.tmp_h_i), state.maj_h, InpColorBull, 2, STYLE_SOLID);
                }
                state.st_l.Clear(); state.st_h.Clear();
                state.maj_st = 1;
                state.anc_i  = state.tmp_h_i; state.anc_v = state.maj_h;
                state.tmp_l  = val_l;          state.tmp_l_i = i;

                CutLine(state.cur_top_line, GetTimeSafe(time,i));
                CutLine(state.cur_bot_line, GetTimeSafe(time,i));

                if(draw_ui && InpShowMaj)
                {
                    state.cur_top_line = GetUniqueName(prefix+"HLine_Top_");
                    DrawLine(state.cur_top_line, GetTimeSafe(time,state.maj_h_i), state.maj_h,
                             GetTimeSafe(time,i)+PeriodSeconds(), state.maj_h, InpColorBull, 1, STYLE_DASH, true);
                    if(state.maj_l != EMPTY_VALUE && state.maj_l != 0)
                    {
                        state.cur_bot_line = GetUniqueName(prefix+"HLine_Bot_");
                        DrawLine(state.cur_bot_line, GetTimeSafe(time,state.maj_l_i), state.maj_l,
                                 GetTimeSafe(time,i)+PeriodSeconds(), state.maj_l, InpColorBull, 1, STYLE_DASH, true);
                    }
                }
            }

            if(state.maj_l != EMPTY_VALUE && state.maj_l != 0)
            {
                if(val_l < state.maj_l && val_c >= state.maj_l)
                {
                    state.maj_l = val_l;
                    if(draw_ui && InpShowMaj) UpdateLineLevel(state.cur_bot_line, state.maj_l);
                }
                if(val_c < state.maj_l)
                {
                    state.maj_tr = -1; state.maj_st = 0; state.bos_i = i;
                    if(draw_ui && InpShowMaj)
                    {
                        string name = GetUniqueName(prefix+"Major_");
                        DrawLine(name, GetTimeSafe(time,state.anc_i), state.anc_v,
                                 GetTimeSafe(time,state.tmp_h_i), state.tmp_h, InpColorBull, 2, STYLE_SOLID);
                    }
                    state.st_l.Clear();
                    state.anc_i = state.tmp_h_i; state.anc_v = state.tmp_h;
                    state.tmp_l = val_l;          state.tmp_l_i = i;
                    state.maj_h = state.tmp_h;    state.maj_h_i = state.tmp_h_i;
                    CutLine(state.cur_top_line, GetTimeSafe(time,i));
                    CutLine(state.cur_bot_line, GetTimeSafe(time,i));
                    state.cur_top_line = ""; state.cur_bot_line = "";
                }
            }
        }
        else if(state.maj_st == 1)
        {
            if(val_l < state.tmp_l) { state.tmp_l = val_l; state.tmp_l_i = i; }

            if(state.maj_h != EMPTY_VALUE && val_h > state.maj_h && val_c <= state.maj_h)
            {
                state.maj_h = val_h;
                if(draw_ui && InpShowMaj) UpdateLineLevel(state.cur_top_line, state.maj_h);
            }

            if(val_c > state.maj_h)
            {
                state.bos_i   = i;
                state.maj_l   = state.tmp_l;  state.maj_l_i = state.tmp_l_i;
                if(draw_ui && InpShowMaj)
                {
                    string name = GetUniqueName(prefix+"Major_");
                    DrawLine(name, GetTimeSafe(time,state.anc_i), state.anc_v,
                             GetTimeSafe(time,state.tmp_l_i), state.maj_l, InpColorBull, 2, STYLE_SOLID);
                }
                state.st_h.Clear(); state.maj_st = 0;
                state.anc_i = state.tmp_l_i; state.anc_v = state.maj_l;
                state.tmp_h = val_h;          state.tmp_h_i = i;
                CutLine(state.cur_top_line, GetTimeSafe(time,i));
                CutLine(state.cur_bot_line, GetTimeSafe(time,i));
                state.cur_top_line = ""; state.cur_bot_line = "";
            }

            if(state.maj_l != EMPTY_VALUE && state.maj_l != 0)
            {
                if(val_l < state.maj_l && val_c >= state.maj_l)
                {
                    state.maj_l = val_l;
                    if(draw_ui && InpShowMaj) UpdateLineLevel(state.cur_bot_line, state.maj_l);
                }
                if(val_c < state.maj_l)
                {
                    state.maj_tr = -1; state.maj_st = 0; state.bos_i = i;
                    if(draw_ui && InpShowMaj)
                    {
                        string name = GetUniqueName(prefix+"Major_");
                        DrawLine(name, GetTimeSafe(time,state.anc_i), state.anc_v,
                                 GetTimeSafe(time,state.tmp_h_i), state.tmp_h, InpColorBull, 2, STYLE_SOLID);
                    }
                    state.st_l.Clear();
                    state.anc_i = state.tmp_h_i; state.anc_v = state.tmp_h;
                    state.tmp_l = val_l;          state.tmp_l_i = i;
                    state.maj_h = state.tmp_h;    state.maj_h_i = state.tmp_h_i;
                    CutLine(state.cur_top_line, GetTimeSafe(time,i));
                    CutLine(state.cur_bot_line, GetTimeSafe(time,i));
                    state.cur_top_line = ""; state.cur_bot_line = "";
                }
            }
        }
    }
    else // maj_tr == -1
    {
        if(val_l < state.tmp_l) { state.tmp_l = val_l; state.tmp_l_i = i; }

        if(state.maj_st == 0)
        {
            double act = state.st_h.Size() > 0 ? state.st_h.GetVal(state.st_h.Size()-1) : EMPTY_VALUE;
            if(act != EMPTY_VALUE && val_h > act)
            {
                state.maj_l    = state.tmp_l;
                state.maj_l_i  = state.tmp_l_i;
                if(draw_ui && InpShowMaj)
                {
                    string name = GetUniqueName(prefix+"Major_");
                    DrawLine(name, GetTimeSafe(time,state.anc_i), state.anc_v,
                             GetTimeSafe(time,state.tmp_l_i), state.maj_l, InpColorBear, 2, STYLE_SOLID);
                }
                state.st_l.Clear(); state.st_h.Clear();
                state.maj_st = 1;
                state.anc_i  = state.tmp_l_i; state.anc_v = state.maj_l;
                state.tmp_h  = val_h;          state.tmp_h_i = i;

                CutLine(state.cur_top_line, GetTimeSafe(time,i));
                CutLine(state.cur_bot_line, GetTimeSafe(time,i));

                if(draw_ui && InpShowMaj)
                {
                    state.cur_bot_line = GetUniqueName(prefix+"HLine_Bot_");
                    DrawLine(state.cur_bot_line, GetTimeSafe(time,state.maj_l_i), state.maj_l,
                             GetTimeSafe(time,i)+PeriodSeconds(), state.maj_l, InpColorBear, 1, STYLE_DASH, true);
                    if(state.maj_h != EMPTY_VALUE && state.maj_h != 0)
                    {
                        state.cur_top_line = GetUniqueName(prefix+"HLine_Top_");
                        DrawLine(state.cur_top_line, GetTimeSafe(time,state.maj_h_i), state.maj_h,
                                 GetTimeSafe(time,i)+PeriodSeconds(), state.maj_h, InpColorBear, 1, STYLE_DASH, true);
                    }
                }
            }

            if(state.maj_h != EMPTY_VALUE && state.maj_h != 0)
            {
                if(val_h > state.maj_h && val_c <= state.maj_h)
                {
                    state.maj_h = val_h;
                    if(draw_ui && InpShowMaj) UpdateLineLevel(state.cur_top_line, state.maj_h);
                }
                if(val_c > state.maj_h)
                {
                    state.maj_tr = 1; state.maj_st = 0; state.bos_i = i;
                    if(draw_ui && InpShowMaj)
                    {
                        string name = GetUniqueName(prefix+"Major_");
                        DrawLine(name, GetTimeSafe(time,state.anc_i), state.anc_v,
                                 GetTimeSafe(time,state.tmp_l_i), state.tmp_l, InpColorBear, 2, STYLE_SOLID);
                    }
                    state.st_h.Clear();
                    state.anc_i = state.tmp_l_i; state.anc_v = state.tmp_l;
                    state.tmp_h = val_h;          state.tmp_h_i = i;
                    state.maj_l = state.tmp_l;    state.maj_l_i = state.tmp_l_i;
                    CutLine(state.cur_top_line, GetTimeSafe(time,i));
                    CutLine(state.cur_bot_line, GetTimeSafe(time,i));
                    state.cur_top_line = ""; state.cur_bot_line = "";
                }
            }
        }
        else if(state.maj_st == 1)
        {
            if(val_h > state.tmp_h) { state.tmp_h = val_h; state.tmp_h_i = i; }

            if(state.maj_l != EMPTY_VALUE && val_l < state.maj_l && val_c >= state.maj_l)
            {
                state.maj_l = val_l;
                if(draw_ui && InpShowMaj) UpdateLineLevel(state.cur_bot_line, state.maj_l);
            }

            if(state.maj_l != EMPTY_VALUE && val_c < state.maj_l)
            {
                state.maj_h   = state.tmp_h;  state.maj_h_i = state.tmp_h_i;
                state.bos_i   = i;
                if(draw_ui && InpShowMaj)
                {
                    string name = GetUniqueName(prefix+"Major_");
                    DrawLine(name, GetTimeSafe(time,state.anc_i), state.anc_v,
                             GetTimeSafe(time,state.tmp_h_i), state.maj_h, InpColorBear, 2, STYLE_SOLID);
                }
                state.st_l.Clear(); state.maj_st = 0;
                state.anc_i = state.tmp_h_i; state.anc_v = state.maj_h;
                state.tmp_l = val_l;          state.tmp_l_i = i;
                CutLine(state.cur_top_line, GetTimeSafe(time,i));
                CutLine(state.cur_bot_line, GetTimeSafe(time,i));
                state.cur_top_line = ""; state.cur_bot_line = "";
            }

            if(state.maj_h != EMPTY_VALUE && state.maj_h != 0)
            {
                if(val_h > state.maj_h && val_c <= state.maj_h)
                {
                    state.maj_h = val_h;
                    if(draw_ui && InpShowMaj) UpdateLineLevel(state.cur_top_line, state.maj_h);
                }
                if(val_c > state.maj_h)
                {
                    state.maj_tr = 1; state.maj_st = 0; state.bos_i = i;
                    state.st_h.Clear();
                    state.anc_i = state.tmp_l_i; state.anc_v = state.tmp_l;
                    state.tmp_h = val_h;          state.tmp_h_i = i;
                    state.maj_l = state.tmp_l;    state.maj_l_i = state.tmp_l_i;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
    IndicatorSetString(INDICATOR_SHORTNAME, "Structure");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0, "Minor_");
    ObjectsDeleteAll(0, "Major_");
    ObjectsDeleteAll(0, "HLine_");
    ObjectsDeleteAll(0, "Live_");
    ObjectsDeleteAll(0, "CHoCH_Path_");
    ObjectsDeleteAll(0, "CHoCH_Signal_");
    ObjectsDeleteAll(0, "CHoCH_Text_");
    DeleteLine("LiveLeg");
    Comment("");
}

//+------------------------------------------------------------------+
//| OnCalculate                                                      |
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
    if(rates_total < 2) return 0;

    static datetime last_calc_time = 0;
    int virtual_prev = prev_calculated;

    if(prev_calculated == 0 && last_calc_time == time[rates_total-1])
        virtual_prev = rates_total - 1;

    int limit;

    if(virtual_prev == 0)
    {
        last_calc_time = time[rates_total-1];

        double tf_days  = GetDaysForTF(Period());
        g_anchor_time   = TimeCurrent() - (datetime)(tf_days * 24.0 * 60.0 * 60.0);
        g_counter       = 0;

        ObjectsDeleteAll(0, "Minor_");
        ObjectsDeleteAll(0, "Major_");
        ObjectsDeleteAll(0, "HLine_");
        ObjectsDeleteAll(0, "Live_");
        ObjectsDeleteAll(0, "CHoCH_Path_");
        ObjectsDeleteAll(0, "CHoCH_Signal_");
        ObjectsDeleteAll(0, "CHoCH_Text_");

        int start_idx = 0;
        // Always start calculation from index 0 for consistent swing structures
        // We will only use g_anchor_time to determine whether to draw UI elements

        g_state_hist.min_h   = high[start_idx];  g_state_hist.min_h_i = start_idx;
        g_state_hist.min_l   = low[start_idx];   g_state_hist.min_l_i = start_idx;
        g_state_hist.trig_h  = high[start_idx];  g_state_hist.trig_l  = low[start_idx];
        g_state_hist.tmp_h   = high[start_idx];  g_state_hist.tmp_h_i = start_idx;
        g_state_hist.tmp_l   = low[start_idx];   g_state_hist.tmp_l_i = start_idx;
        g_state_hist.min_tr  = (close[start_idx] > open[start_idx]) ? 1 : -1;
        g_state_hist.anc_i   = start_idx;        g_state_hist.anc_v   = close[start_idx];
        g_state_hist.lp_i    = start_idx;        g_state_hist.lp_p    = close[start_idx];
        g_state_hist.mb_h    = high[start_idx];  g_state_hist.mb_l    = low[start_idx];
        g_state_hist.mb_i    = start_idx;

        g_state_hist.t1_h = 0; g_state_hist.t1_l = 0; g_state_hist.t1_i = 0;
        g_state_hist.d1_h = 0; g_state_hist.d1_l = 0; g_state_hist.d1_i = 0;
        g_state_hist.t2_h = 0; g_state_hist.t2_l = 0; g_state_hist.t2_i = 0;
        g_state_hist.choch_dir = 0;
        g_state_hist.last_choch_dir = 0;
        g_state_hist.last_choch_level = 0;
        g_state_hist.last_choch_time  = 0;

        double atr   = (high[start_idx] - low[start_idx]);
        if(atr == 0) atr = Point() * 10;
        double tiny  = atr * 0.1;

        g_state_hist.maj_h   = high[start_idx] + tiny;
        g_state_hist.maj_l   = low[start_idx]  - tiny;
        g_state_hist.maj_tr  = g_state_hist.min_tr;
        g_state_hist.maj_st  = 1;
        g_state_hist.bos_i   = start_idx;
        g_state_hist.maj_h_i = start_idx;
        g_state_hist.maj_l_i = start_idx;

        limit = start_idx + 1;
    }
    else
    {
        limit = virtual_prev - 1;
    }

    // Mother bar başlangıç değeri
    if(virtual_prev == 0 && limit < rates_total)
    {
        g_state_hist.mb_h = high[limit-1];
        g_state_hist.mb_l = low[limit-1];
        g_state_hist.mb_i = limit-1;
    }

    // ── Tarihsel tarama ──
    for(int i = limit; i < rates_total - 1; i++)
    {
        bool inside = (high[i] <= g_state_hist.mb_h) && (low[i] >= g_state_hist.mb_l);
        if(!inside)
        {
            if(high[i] > g_state_hist.mb_h || low[i] < g_state_hist.mb_l)
            {
                g_state_hist.mb_h = high[i];
                g_state_hist.mb_l = low[i];
                g_state_hist.mb_i = i;
            }
            bool should_draw = (time[i] >= g_anchor_time);
            ProcessBar(i, open, high, low, close, time, g_state_hist, true, should_draw);
        }
    }

    // ── Canlı bar ──
    ObjectsDeleteAll(0, "Live_");
    DeleteLine("LiveLeg");

    g_state_curr.CopyFrom(g_state_hist);

    int last_idx = rates_total - 1;
    if(last_idx > 0)
    {
        bool inside_last = (high[last_idx] <= g_state_curr.mb_h) && (low[last_idx] >= g_state_curr.mb_l);
        if(!inside_last)
        {
            bool should_draw = (time[last_idx] >= g_anchor_time);
            ProcessBar(last_idx, open, high, low, close, time, g_state_curr, false, should_draw);
        }
    }

    // Canlı minör bacak çizgisi
    if(InpShowMin && last_idx > 0)
    {
        int    leg_i = (g_state_curr.min_tr == 1) ? g_state_curr.min_h_i : g_state_curr.min_l_i;
        double leg_p = (g_state_curr.min_tr == 1) ? g_state_curr.min_h   : g_state_curr.min_l;
        DrawLine("LiveLeg",
                 GetTimeSafe(time, g_state_curr.lp_i), g_state_curr.lp_p,
                 GetTimeSafe(time, leg_i),              leg_p,
                 InpColorMin, 1, STYLE_DOT);
    }

    return rates_total;
}
