//+------------------------------------------------------------------+
//|                                                    Structure.mq5 |
//|                    CHoCH + Kutu - Sadece Görsel                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.04"
#property indicator_chart_window
#property indicator_plots 0

// ─── Hesaplama Derinliği (Gün) ────────────────────────────────────
input double InpDaysM1   = 1.0;
input double InpDaysM3   = 3.0;
input double InpDaysM5   = 5.0;
input double InpDaysM15  = 15.0;
input double InpDaysM30  = 30.0;
input double InpDaysH1   = 60.0;
input double InpDaysH4   = 240.0;
input double InpDaysD1   = 1440.0;

// ─── CHoCH Görsel ─────────────────────────────────────────────────
input double InpMinPullbackPct   = 40.0;
input color  InpColorChochStrong = clrPurple;
input color  InpColorChochWeak   = clrRed;
input color  InpColorChochPath   = clrGray;
input bool   InpShowChoch        = true;

// ─── Majör / Minör ────────────────────────────────────────────────
input bool   InpShowMin   = true;
input bool   InpShowMaj   = true;
input color  InpColorMin  = clrRed;
input color  InpColorBull = clrGreen;
input color  InpColorBear = clrRed;

// ─── Kutu ─────────────────────────────────────────────────────────
input bool   InpShowBox           = true;
input double InpMaxBoxPct         = 20.0;
input double InpWeakZonePct       = 50.0;
input color  InpColorBoxBull      = clrDodgerBlue;
input color  InpColorBoxBear      = clrRed;
input color  InpColorBoxBullFaint = C'0,40,90';
input color  InpColorBoxBearFaint = C'90,20,0';
input color  InpColorWeakBull     = C'0,25,55';
input color  InpColorWeakBear     = C'55,15,0';

// ─── Yatay Bölge ─────────────────────────────────────────────────
input group "--- YATAY BOLGE ---"
input int    InpExhaustionCount = 3;

// ─── Test Bildirimi ───────────────────────────────────────────────
input group "--- BILDIRIM TEST ---"
input bool   InpNotifTest    = false;
input bool   InpAlertPush    = true;
input bool   InpAlertPopup   = false;

// ─── Bildirim Zaman Dilimleri ─────────────────────────────────────
input group "--- BILDIRIM ZAMAN DILIMLERI ---"
input bool   InpEnableM1  = false;
input bool   InpEnableM5  = false;
input bool   InpEnableM15 = true;
input bool   InpEnableM30 = true;
input bool   InpEnableH1  = true;
input bool   InpEnableH4  = true;
input bool   InpEnableD1  = true;

// ─── Globals ──────────────────────────────────────────────────────
int      g_counter     = 0;
datetime g_anchor_time = 0;

double g_trade_t1_h[5]; double g_trade_t2_h[5];
int    g_trade_count_h = 0; int g_current_maj_h_i = 0;
double g_trade_t1_l[5]; double g_trade_t2_l[5];
int    g_trade_count_l = 0; int g_current_maj_l_i = 0;

void ResetBearishMemory(){g_trade_count_h=0;for(int i=0;i<5;i++){g_trade_t1_h[i]=0;g_trade_t2_h[i]=0;}}
void ResetBullishMemory(){g_trade_count_l=0;for(int i=0;i<5;i++){g_trade_t1_l[i]=0;g_trade_t2_l[i]=0;}}

// ─── Bildirim Tekrar Engeli ───────────────────────────────────────
int g_last_notif_d1i_sell = -1;
int g_last_notif_d1i_buy  = -1;

// ─── Kutu Dizileri ────────────────────────────────────────────────
#define BOX_MAX 512

bool g_shadow_mode = false;
#define SHD_BOX_MAX 64
int      g_shd_state[SHD_BOX_MAX];
double   g_shd_top[SHD_BOX_MAX];
double   g_shd_bot[SHD_BOX_MAX];
int      g_shd_touch[SHD_BOX_MAX];
int      g_shd_appr[SHD_BOX_MAX];
int      g_shd_cnt_in[SHD_BOX_MAX];
datetime g_shd_ev_t[SHD_BOX_MAX];
datetime g_shd_entry_t[SHD_BOX_MAX];   // ← YENİ: ilk giriş zamanı
int      g_shd_break_up[SHD_BOX_MAX];
int      g_shd_break_dn[SHD_BOX_MAX];
double   g_shd_wk_sz[SHD_BOX_MAX];
int      g_shd_wka_touch[SHD_BOX_MAX]; int g_shd_wka_appr[SHD_BOX_MAX];
int      g_shd_wka_cnt[SHD_BOX_MAX];   datetime g_shd_wka_ev[SHD_BOX_MAX];
int      g_shd_wkb_touch[SHD_BOX_MAX]; int g_shd_wkb_appr[SHD_BOX_MAX];
int      g_shd_wkb_cnt[SHD_BOX_MAX];   datetime g_shd_wkb_ev[SHD_BOX_MAX];
int      g_shd_cnt = 0;

string   g_bx_nm[BOX_MAX];
int      g_bx_state[BOX_MAX];
double   g_bx_top[BOX_MAX];
double   g_bx_bot[BOX_MAX];
int      g_bx_touch_state[BOX_MAX];
int      g_bx_approach[BOX_MAX];
int      g_bx_inside_cnt[BOX_MAX];
datetime g_bx_event_time[BOX_MAX];
string   g_bx_wk_abv_nm[BOX_MAX];
string   g_bx_wk_blw_nm[BOX_MAX];
double   g_bx_wk_abv_top[BOX_MAX];
double   g_bx_wk_blw_bot[BOX_MAX];
int      g_bx_cnt = 0;

// ─── TF Kutu Sonucu Struct ────────────────────────────────────────
struct TFBoxResult {
    ENUM_TIMEFRAMES tf;
    bool     has_box;
    int      touch_state; int approach; int cnt_in;
    int      break_up;    int break_dn;
    datetime ev_t;        datetime entry_t;
    int      wka_touch;   int wka_appr; int wka_cnt; datetime wka_ev;
    int      wkb_touch;   int wkb_appr; int wkb_cnt; datetime wkb_ev;
};

// ─── Yardımcı Fonksiyonlar ────────────────────────────────────────
datetime GetTimeSafe(const datetime &t[],int idx)
{int s=ArraySize(t);if(s<=0)return 0;if(idx<0)return t[0];if(idx>=s)return t[s-1];return t[idx];}

string GetUniqueName(string p){g_counter++;return p+IntegerToString(g_counter);}

double GetDaysForTF(ENUM_TIMEFRAMES tf)
{
    if(tf==PERIOD_M1) return InpDaysM1; if(tf==PERIOD_M3) return InpDaysM3;
    if(tf==PERIOD_M5) return InpDaysM5; if(tf==PERIOD_M15)return InpDaysM15;
    if(tf==PERIOD_M30)return InpDaysM30;if(tf==PERIOD_H1) return InpDaysH1;
    if(tf==PERIOD_H4) return InpDaysH4; if(tf==PERIOD_D1) return InpDaysD1;
    return InpDaysM1;
}

string FormatTimeAgo(datetime ev_t)
{
    if(ev_t==0) return "";
    int secs=(int)(TimeCurrent()-ev_t);
    if(secs<0)  secs=0;
    if(secs<60)    return IntegerToString(secs)+" sn once";
    if(secs<3600)  return IntegerToString(secs/60)+" dk once";
    if(secs<86400) return IntegerToString(secs/3600)+" saat once";
    return IntegerToString(secs/86400)+" gun once";
}

// ─── 25 Mum Geçerlilik ───────────────────────────────────────────
bool IsGecersiz(int touch, int cnt_in, datetime ev_t, ENUM_TIMEFRAMES tf)
{
    if(touch==0) return true;
    int ps=PeriodSeconds(tf);
    if(touch==1) return (cnt_in>25);
    return (ps>0 && (int)((TimeCurrent()-ev_t)/ps)>25);
}
// ─── Zayıf Bölge Onayı (sadece içi ve tepki, deldi→kutu gibi) ───
bool IsApprovedWeak(int choch_dir, int touch, int appr)
{
    if(touch==0||touch==2) return false;
    return (choch_dir==-1) ? (appr==-1) : (appr==1);
}
// ─── Yön Bazlı Onay Mantığı ──────────────────────────────────────
// SELL onaylı: Alttan→İçi / Üstten→Aşağı Deldi / Alttan→Aşağı Tepki
// BUY  onaylı: Üstten→İçi / Alttan→Yukarı Deldi / Üstten→Yukarı Tepki
bool IsApproved(int choch_dir, int ts, int appr, int break_up, int break_dn)
{
    if(ts == 0) return false;
    int total = break_up + break_dn;
    bool is_yatay = (InpExhaustionCount > 0) && (break_up >= 1) && (break_dn >= 1) && (total >= InpExhaustionCount);
    if(is_yatay) return false;

    if(choch_dir == -1) { // SELL
        if(ts==1 && appr==-1) return true;  // Alttan→İçi
        if(ts==2 && appr== 1) return true;  // Üstten→Aşağı Deldi
        if(ts==3 && appr==-1) return true;  // Alttan→Aşağı Tepki
        return false;
    } else { // BUY
        if(ts==1 && appr== 1) return true;  // Üstten→İçi
        if(ts==2 && appr==-1) return true;  // Alttan→Yukarı Deldi
        if(ts==3 && appr== 1) return true;  // Üstten→Yukarı Tepki
        return false;
    }
}

// ─── Kutu Durum Kısa Metin ───────────────────────────────────────
string GetBoxStatusShort(int ts, int appr, int break_up, int break_dn)
{
    int total = break_up + break_dn;
    bool is_yatay = (InpExhaustionCount > 0) && (break_up >= 1) && (break_dn >= 1) && (total >= InpExhaustionCount);
    if(is_yatay) return StringFormat("YATAY (U:%d A:%d)", break_up, break_dn);
    if(ts==0) return "Temas yok";
    if(ts==1) return (appr==-1) ? "Alttan->Ici"          : "Ustten->Ici";
    if(ts==2) return (appr==-1) ? "Alttan->Yukari Deldi"  : "Ustten->Asagi Deldi";
    if(ts==3) return (appr==-1) ? "Alttan->Asagi Tepki"   : "Ustten->Yukari Tepki";
    return "?";
}

// ─── Kutu Durum Uzun Metin (Test bildirimi için) ─────────────────
string GetBoxStatusStr(int ts, int appr)
{
    if(ts==0) return "Bekleniyor";
    if(ts==1) return (appr==1) ? "Ustten Geldi - Kutu Icinde"          : "Alttan Geldi - Kutu Icinde";
    if(ts==2) return (appr==1) ? "Ustten Geldi - Alti Deldi"           : "Alttan Geldi - Yukari Deldi";
    if(ts==3) return (appr==1) ? "Ustten Geldi - Icinden Yukari Tepki" : "Alttan Geldi - Icinden Asagi Tepki";
    return "?";
}

void DrawLine(string nm,datetime t1,double p1,datetime t2,double p2,
              color clr,int w,ENUM_LINE_STYLE st,bool ray=false)
{
    if(g_shadow_mode)return;
    if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_TREND,0,t1,p1,t2,p2);
    else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p1);
         ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2);ObjectSetDouble(0,nm,OBJPROP_PRICE,1,p2);}
    ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_WIDTH,w);
    ObjectSetInteger(0,nm,OBJPROP_STYLE,st); ObjectSetInteger(0,nm,OBJPROP_RAY_RIGHT,ray);
    ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void DeleteLine(string n){if(g_shadow_mode)return;if(ObjectFind(0,n)>=0)ObjectDelete(0,n);}
void CutLine(string n,datetime t){if(g_shadow_mode)return;if(ObjectFind(0,n)>=0){ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,n,OBJPROP_TIME,1,t);}}
void UpdateLineLevel(string n,double v){if(g_shadow_mode)return;if(ObjectFind(0,n)>=0){ObjectSetDouble(0,n,OBJPROP_PRICE,0,v);ObjectSetDouble(0,n,OBJPROP_PRICE,1,v);}}

void DrawRect(string nm,datetime t1,double top,datetime t2,double bot,color clr)
{
    if(g_shadow_mode)return;
    if(top<bot){double tmp=top;top=bot;bot=tmp;}
    if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,top,t2,bot);
    else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,top);
         ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2);ObjectSetDouble(0,nm,OBJPROP_PRICE,1,bot);}
    ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_SOLID);
    ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);  ObjectSetInteger(0,nm,OBJPROP_FILL,true);
    ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void _DrawWeakRect(string nm,datetime t1,double top,double bot,color clr)
{
    if(g_shadow_mode)return;
    if(top<bot){double tmp=top;top=bot;bot=tmp;}
    if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,top,D'2099.12.31 00:00',bot);
    else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,top);
         ObjectSetInteger(0,nm,OBJPROP_TIME,1,D'2099.12.31 00:00');ObjectSetDouble(0,nm,OBJPROP_PRICE,1,bot);}
    ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_DOT);
    ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);  ObjectSetInteger(0,nm,OBJPROP_FILL,false);
    ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}

// ─── Kutu Fonksiyonları ───────────────────────────────────────────
void BxAdd(string nm,double top,double bot,color box_clr,const datetime &time[],int right_i)
{
    if(g_shadow_mode){
        if(g_shd_cnt>=SHD_BOX_MAX)return;
        g_shd_state[g_shd_cnt]    = 2;
        g_shd_top[g_shd_cnt]      = top;
        g_shd_bot[g_shd_cnt]      = bot;
        g_shd_touch[g_shd_cnt]    = 0;
        g_shd_appr[g_shd_cnt]     = 0;
        g_shd_cnt_in[g_shd_cnt]   = 0;
        g_shd_ev_t[g_shd_cnt]     = 0;
        g_shd_entry_t[g_shd_cnt]  = 0;
        g_shd_break_up[g_shd_cnt] = 0;
        g_shd_break_dn[g_shd_cnt] = 0;
        g_shd_wk_sz[g_shd_cnt]    = (top-bot)*InpWeakZonePct/100.0;
        g_shd_wka_touch[g_shd_cnt]=0; g_shd_wka_appr[g_shd_cnt]=0;
        g_shd_wka_cnt[g_shd_cnt]  =0; g_shd_wka_ev[g_shd_cnt]  =0;
        g_shd_wkb_touch[g_shd_cnt]=0; g_shd_wkb_appr[g_shd_cnt]=0;
        g_shd_wkb_cnt[g_shd_cnt]  =0; g_shd_wkb_ev[g_shd_cnt]  =0;
        g_shd_cnt++;
        return;
    }
    if(g_bx_cnt>=BOX_MAX)return;
    double wk_sz=(top-bot)*InpWeakZonePct/100.0;
    color wk_clr=(box_clr==InpColorBoxBull||box_clr==InpColorBoxBullFaint)?InpColorWeakBull:InpColorWeakBear;
    g_bx_nm[g_bx_cnt]=nm; g_bx_state[g_bx_cnt]=2;
    g_bx_top[g_bx_cnt]=top; g_bx_bot[g_bx_cnt]=bot;
    g_bx_touch_state[g_bx_cnt]=0; g_bx_approach[g_bx_cnt]=0;
    g_bx_inside_cnt[g_bx_cnt]=0;  g_bx_event_time[g_bx_cnt]=0;
    g_bx_wk_abv_nm[g_bx_cnt]="BoxWkAbv_"+IntegerToString(g_bx_cnt);
    g_bx_wk_blw_nm[g_bx_cnt]="BoxWkBlw_"+IntegerToString(g_bx_cnt);
    g_bx_wk_abv_top[g_bx_cnt]=top+wk_sz;
    g_bx_wk_blw_bot[g_bx_cnt]=bot-wk_sz;
    datetime t_left=GetTimeSafe(time,right_i);
    _DrawWeakRect(g_bx_wk_abv_nm[g_bx_cnt],t_left,g_bx_wk_abv_top[g_bx_cnt],top,wk_clr);
    _DrawWeakRect(g_bx_wk_blw_nm[g_bx_cnt],t_left,bot,g_bx_wk_blw_bot[g_bx_cnt],wk_clr);
    g_bx_cnt++;
}

void ShdBxUpdateStats(double h,double l,double c,double prev_c,datetime bar_time)
{
    for(int k=0;k<g_shd_cnt;k++){
        if(g_shd_state[k]==0)continue;
        double top=g_shd_top[k],bot=g_shd_bot[k];
        bool im=(h>=bot)&&(l<=top);
        int na;if(prev_c>top)na=1;else if(prev_c<bot)na=-1;else na=g_shd_appr[k];
        int ts=g_shd_touch[k];
        if(ts==0){
            if(im){
                g_shd_appr[k]   =(na!=0)?na:(c>(top+bot)/2.0?1:-1);
                g_shd_touch[k]  =1;
                g_shd_cnt_in[k] =1;
                g_shd_ev_t[k]   =bar_time;
                g_shd_entry_t[k]=bar_time;   // ← YENİ: ilk giriş
            }
        }
        else if(ts==1){
            if(im){g_shd_cnt_in[k]++;g_shd_ev_t[k]=bar_time;}
            else{
                bool bd=(c<bot),bu=(c>top);
                int  ap=g_shd_appr[k];
                if(ap==1){
                    if(bd){g_shd_touch[k]=2;g_shd_break_dn[k]++;}
                    else if(bu)g_shd_touch[k]=3;
                }else{
                    if(bu){g_shd_touch[k]=2;g_shd_break_up[k]++;}
                    else if(bd)g_shd_touch[k]=3;
                }
                g_shd_ev_t[k]=bar_time;
            }
        }
        else{
            if(im){
                g_shd_appr[k]   =(na!=0)?na:(c>(top+bot)/2.0?1:-1);
                g_shd_touch[k]  =1;
                g_shd_cnt_in[k] =1;
                g_shd_ev_t[k]   =bar_time;
                g_shd_entry_t[k]=bar_time;
            }
        }

        double wk_sz=g_shd_wk_sz[k]; if(wk_sz<=0) continue;
        // ── Zayıf Üst [top, top+wk_sz] ──────────────────────────────
        {double wa_top=top+wk_sz;
        bool iw=(h>=top)&&(l<=wa_top);
        int na_w;if(prev_c>wa_top)na_w=1;else if(prev_c<top)na_w=-1;else na_w=g_shd_wka_appr[k];
        int ts_w=g_shd_wka_touch[k];
        if(ts_w==0){if(iw){g_shd_wka_appr[k]=(na_w!=0)?na_w:1;g_shd_wka_touch[k]=1;g_shd_wka_cnt[k]=1;g_shd_wka_ev[k]=bar_time;}}
        else if(ts_w==1){if(iw){g_shd_wka_cnt[k]++;g_shd_wka_ev[k]=bar_time;}
            else{int ap=g_shd_wka_appr[k];
                if(ap==1){if(c<top)g_shd_wka_touch[k]=2;else if(c>wa_top)g_shd_wka_touch[k]=3;}
                else{if(c>wa_top)g_shd_wka_touch[k]=2;else if(c<top)g_shd_wka_touch[k]=3;}
                g_shd_wka_ev[k]=bar_time;}}
        else{if(iw){g_shd_wka_appr[k]=(na_w!=0)?na_w:1;g_shd_wka_touch[k]=1;g_shd_wka_cnt[k]=1;g_shd_wka_ev[k]=bar_time;}}}
        // ── Zayıf Alt [bot-wk_sz, bot] ───────────────────────────────
        {double wb_bot=bot-wk_sz;
        bool iw=(h>=wb_bot)&&(l<=bot);
        int na_w;if(prev_c<wb_bot)na_w=-1;else if(prev_c>bot)na_w=1;else na_w=g_shd_wkb_appr[k];
        int ts_w=g_shd_wkb_touch[k];
        if(ts_w==0){if(iw){g_shd_wkb_appr[k]=(na_w!=0)?na_w:-1;g_shd_wkb_touch[k]=1;g_shd_wkb_cnt[k]=1;g_shd_wkb_ev[k]=bar_time;}}
        else if(ts_w==1){if(iw){g_shd_wkb_cnt[k]++;g_shd_wkb_ev[k]=bar_time;}
            else{int ap=g_shd_wkb_appr[k];
                if(ap==1){if(c<wb_bot)g_shd_wkb_touch[k]=2;else if(c>bot)g_shd_wkb_touch[k]=3;}
                else{if(c>bot)g_shd_wkb_touch[k]=2;else if(c<wb_bot)g_shd_wkb_touch[k]=3;}
                g_shd_wkb_ev[k]=bar_time;}}
        else{if(iw){g_shd_wkb_appr[k]=(na_w!=0)?na_w:-1;g_shd_wkb_touch[k]=1;g_shd_wkb_cnt[k]=1;g_shd_wkb_ev[k]=bar_time;}}}
    }
}

void BxUpdateStats(double h,double l,double c,double prev_c,datetime bar_time)
{
    if(g_shadow_mode){ShdBxUpdateStats(h,l,c,prev_c,bar_time);return;}
    for(int k=0;k<g_bx_cnt;k++)
    {
        if(g_bx_state[k]==0)continue;
        double top=g_bx_top[k],bot=g_bx_bot[k];
        bool im=(h>=bot)&&(l<=top);
        int na;if(prev_c>top)na=1;else if(prev_c<bot)na=-1;else na=g_bx_approach[k];
        int ts=g_bx_touch_state[k];
        if(ts==0){if(im){
            g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);
            g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;
        }}
        else if(ts==1){if(im){g_bx_inside_cnt[k]++;g_bx_event_time[k]=bar_time;}
            else{bool bd=(c<bot),bu=(c>top);int ap=g_bx_approach[k];
                if(ap==1){if(bd)g_bx_touch_state[k]=2;else if(bu)g_bx_touch_state[k]=3;}
                else{if(bu)g_bx_touch_state[k]=2;else if(bd)g_bx_touch_state[k]=3;}
                g_bx_event_time[k]=bar_time;}}
        else{if(im){
            g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);
            g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;
        }}
    }
}

void ShdBxAdvanceTrim()
{
    for(int k=0;k<g_shd_cnt;k++){
        if(g_shd_state[k]==1){if(g_shd_touch[k]==1)continue;g_shd_state[k]=0;}
        else if(g_shd_state[k]==2)g_shd_state[k]=1;
    }
}

void BxAdvanceTrim(datetime t)
{
    if(g_shadow_mode){ShdBxAdvanceTrim();return;}
    for(int k=0;k<g_bx_cnt;k++){
        if(g_bx_state[k]==1){
            if(g_bx_touch_state[k]==1)continue;
            if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectSetInteger(0,g_bx_nm[k],OBJPROP_TIME,1,t);
            if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,t);
            if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,t);
            g_bx_state[k]=0;
        }
        else if(g_bx_state[k]==2)g_bx_state[k]=1;
    }
}

void BxDeleteAll()
{
    for(int k=0;k<g_bx_cnt;k++){
        if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectDelete(0,g_bx_nm[k]);
        if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectDelete(0,g_bx_wk_abv_nm[k]);
        if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectDelete(0,g_bx_wk_blw_nm[k]);
    }
    g_bx_cnt=0;
}
void BxClear(){g_bx_cnt=0;}

// ─── CStack ───────────────────────────────────────────────────────
class CStack{
private: double m_v[];int m_i[];
public:
    CStack(){ArrayResize(m_v,0);ArrayResize(m_i,0);}
    void   Clear(){ArrayResize(m_v,0);ArrayResize(m_i,0);}
    int    Size(){return ArraySize(m_v);}
    void   Push(double v,int i){int s=ArraySize(m_v);ArrayResize(m_v,s+1);ArrayResize(m_i,s+1);m_v[s]=v;m_i[s]=i;}
    void   Pop(){int s=ArraySize(m_v);if(s>0){ArrayResize(m_v,s-1);ArrayResize(m_i,s-1);}}
    double GetVal(int i){return m_v[i];}
    int    GetIdx(int i){return m_i[i];}
    void   CopyFrom(CStack &s){ArrayCopy(m_v,s.m_v);ArrayCopy(m_i,s.m_i);}
};

// ─── SState ───────────────────────────────────────────────────────
struct SState{
    int    min_tr,maj_tr,maj_st;
    double min_h;int min_h_i;double min_l;int min_l_i;
    double trig_h,trig_l;int lp_i;double lp_p;
    double maj_h;int maj_h_i;double maj_l;int maj_l_i;
    double tmp_h;int tmp_h_i;double tmp_l;int tmp_l_i;
    int    anc_i;double anc_v;int bos_i;
    string cur_top_line,cur_bot_line;
    double mb_h,mb_l;int mb_i;
    double t1_h,t1_l;int t1_i;
    double d1_h,d1_l;int d1_i;
    double t2_h,t2_l;int t2_i;
    int    choch_dir;
    int    last_choch_dir;double last_choch_level;datetime last_choch_time;int last_choch_i;
    int    last_choch_tdx;bool last_choch_strong;double last_choch_pb;
    int    bx_phase;bool bx_extreme;double bx_swing_h,bx_swing_l;
    bool   has_pot_bull_minor;int pot_bull_start_i;double pot_bull_start_p,pot_bull_end_p;
    bool   has_pot_bear_minor;int pot_bear_start_i;double pot_bear_start_p,pot_bear_end_p;
    CStack st_h,st_l;

    void CopyFrom(SState &s){
        min_tr=s.min_tr;maj_tr=s.maj_tr;maj_st=s.maj_st;
        min_h=s.min_h;min_h_i=s.min_h_i;min_l=s.min_l;min_l_i=s.min_l_i;
        trig_h=s.trig_h;trig_l=s.trig_l;lp_i=s.lp_i;lp_p=s.lp_p;
        maj_h=s.maj_h;maj_h_i=s.maj_h_i;maj_l=s.maj_l;maj_l_i=s.maj_l_i;
        tmp_h=s.tmp_h;tmp_h_i=s.tmp_h_i;tmp_l=s.tmp_l;tmp_l_i=s.tmp_l_i;
        anc_i=s.anc_i;anc_v=s.anc_v;bos_i=s.bos_i;
        cur_top_line=s.cur_top_line;cur_bot_line=s.cur_bot_line;
        mb_h=s.mb_h;mb_l=s.mb_l;mb_i=s.mb_i;
        t1_h=s.t1_h;t1_l=s.t1_l;t1_i=s.t1_i;
        d1_h=s.d1_h;d1_l=s.d1_l;d1_i=s.d1_i;
        t2_h=s.t2_h;t2_l=s.t2_l;t2_i=s.t2_i;
        choch_dir=s.choch_dir;
        last_choch_dir=s.last_choch_dir;last_choch_level=s.last_choch_level;
        last_choch_time=s.last_choch_time;last_choch_i=s.last_choch_i;
        last_choch_tdx=s.last_choch_tdx;last_choch_strong=s.last_choch_strong;last_choch_pb=s.last_choch_pb;
        bx_phase=s.bx_phase;bx_extreme=s.bx_extreme;
        bx_swing_h=s.bx_swing_h;bx_swing_l=s.bx_swing_l;
        has_pot_bull_minor=s.has_pot_bull_minor;pot_bull_start_i=s.pot_bull_start_i;
        pot_bull_start_p=s.pot_bull_start_p;pot_bull_end_p=s.pot_bull_end_p;
        has_pot_bear_minor=s.has_pot_bear_minor;pot_bear_start_i=s.pot_bear_start_i;
        pot_bear_start_p=s.pot_bear_start_p;pot_bear_end_p=s.pot_bear_end_p;
        st_h.CopyFrom(s.st_h);st_l.CopyFrom(s.st_l);}
};

SState g_state_hist,g_state_curr;

void BxReset(SState &s,double rl,double rh){s.bx_phase=0;s.bx_extreme=false;s.bx_swing_l=rl;s.bx_swing_h=rh;}

// ─── DoDrawBox ────────────────────────────────────────────────────
void DoDrawBox(const datetime &time[],string pfx,SState &s,
               int left_i,double top,double bot,color clr)
{
    if(left_i<s.anc_i)left_i=s.anc_i;
    if(top<bot){double tmp=top;top=bot;bot=tmp;}
    double maj_sz=s.maj_h-s.maj_l;
    if(maj_sz>0&&(top-bot)/maj_sz*100.0>InpMaxBoxPct){
        if(clr==InpColorBoxBull||clr==InpColorBoxBullFaint){
            double fh=-1;int fi=left_i;
            for(int k=0;k<s.st_h.Size();k++){double mh=s.st_h.GetVal(k);if(mh>bot&&mh<top&&(fh<0||mh<fh)){fh=mh;fi=s.st_h.GetIdx(k);}}
            if(fh>0){top=fh;left_i=fi;}else top=bot+maj_sz*InpMaxBoxPct/100.0;
        }else{
            double fl=-1;int fi=left_i;
            for(int k=0;k<s.st_l.Size();k++){double ml=s.st_l.GetVal(k);if(ml<top&&ml>bot&&(fl<0||ml>fl)){fl=ml;fi=s.st_l.GetIdx(k);}}
            if(fl>0){bot=fl;left_i=fi;}else bot=top-maj_sz*InpMaxBoxPct/100.0;
        }
    }
    if(top<=bot)return;
    string nm=GetUniqueName(pfx+"Box_");
    DrawRect(nm,GetTimeSafe(time,left_i),top,D'2099.12.31 00:00',bot,clr);
    BxAdd(nm,top,bot,clr,time,left_i);
}

// ─── CHoCH Renk Sıralaması ────────────────────────────────────────
color GetChochColor(int tdx)
{
    switch(tdx)
    {
        case 0: return clrBlack;
        case 1: return clrYellow;
        case 2: return clrRed;
        case 3: return clrGray;
        case 4: return C'255,230,180';
    }
    return clrWhite;
}

// ─── TF Kutu Analizi (Shadow) ─────────────────────────────────────
// Forward declaration - ProcessBar önce tanımlanmalı
void ProcessBar(int i,
                const double &open[],const double &high[],
                const double &low[], const double &close[],
                const datetime &time[],
                SState &state,bool is_history,bool draw_ui=true);

bool AnalyzeTFBoxResult(ENUM_TIMEFRAMES tf, double days_inp, TFBoxResult &res)
{
    res.tf=tf; res.has_box=false; res.touch_state=0; res.approach=0;
    res.cnt_in=0; res.break_up=0; res.break_dn=0; res.ev_t=0; res.entry_t=0;

    MqlRates r[];
    datetime anc=TimeCurrent()-(datetime)(days_inp*86400.0);
    int n=CopyRates(Symbol(),tf,anc,TimeCurrent(),r);
    if(n<5) return false;

    double o[],h[],l[],c[]; datetime t[];
    ArrayResize(o,n);ArrayResize(h,n);ArrayResize(l,n);ArrayResize(c,n);ArrayResize(t,n);
    for(int j=0;j<n;j++){o[j]=r[j].open;h[j]=r[j].high;l[j]=r[j].low;c[j]=r[j].close;t[j]=r[j].time;}

    g_shadow_mode=true; g_shd_cnt=0;

    SState st;
    int si=0;
    st.min_h=h[si];st.min_h_i=si;st.min_l=l[si];st.min_l_i=si;
    st.trig_h=h[si];st.trig_l=l[si];st.tmp_h=h[si];st.tmp_h_i=si;
    st.tmp_l=l[si];st.tmp_l_i=si;st.min_tr=(c[si]>o[si])?1:-1;
    st.anc_i=si;st.anc_v=c[si];st.lp_i=si;st.lp_p=c[si];
    st.bos_i=si;st.maj_h_i=si;st.maj_l_i=si;
    st.mb_h=h[si];st.mb_l=l[si];st.mb_i=si;
    st.t1_h=0;st.t1_l=0;st.t1_i=0;
    st.d1_h=0;st.d1_l=0;st.d1_i=0;
    st.t2_h=0;st.t2_l=0;st.t2_i=0;
    st.choch_dir=0;st.last_choch_dir=0;st.last_choch_level=0;st.last_choch_time=0;st.last_choch_i=0;st.last_choch_tdx=-1;st.last_choch_strong=false;st.last_choch_pb=0;
    double ig=h[si]-l[si];if(ig==0)ig=Point()*10;
    st.maj_h=h[si]+ig*0.1;st.maj_l=l[si]-ig*0.1;
    st.maj_tr=st.min_tr;st.maj_st=1;
    st.cur_top_line="";st.cur_bot_line="";
    st.st_h.Clear();st.st_l.Clear();
    BxReset(st,l[si],h[si]);
    st.has_pot_bull_minor=false;st.has_pot_bear_minor=false;

    for(int i=si+1;i<n-1;i++){
        bool inside=(h[i]<=st.mb_h)&&(l[i]>=st.mb_l);
        if(!inside){
            if(h[i]>st.mb_h||l[i]<st.mb_l){st.mb_h=h[i];st.mb_l=l[i];st.mb_i=i;}
            ProcessBar(i,o,h,l,c,t,st,true,false); // draw_ui=false: static ld1b/ld1l bozulmasın
        }else{double pc=(i>0)?c[i-1]:c[i];ShdBxUpdateStats(h[i],l[i],c[i],pc,t[i]);}
    }
    int li=n-1;
    SState sc; sc.CopyFrom(st);
    bool il=(h[li]<=sc.mb_h)&&(l[li]>=sc.mb_l);
    if(!il)ProcessBar(li,o,h,l,c,t,sc,true,false); // draw_ui=false
    else{double pc=(li>0)?c[li-1]:c[li];ShdBxUpdateStats(h[li],l[li],c[li],pc,t[li]);}

    g_shadow_mode=false;

    int bk=-1; datetime bt=0;
    for(int k=0;k<g_shd_cnt;k++){
        if(g_shd_state[k]==0)continue;
        if(g_shd_touch[k]>0 && g_shd_ev_t[k]>bt){bt=g_shd_ev_t[k];bk=k;}
    }
    if(bk<0){
        for(int k=g_shd_cnt-1;k>=0;k--){
            if(g_shd_state[k]>0){bk=k;break;}
        }
    }
    if(bk<0) return false;

    res.has_box     = true;
    res.touch_state = g_shd_touch[bk];
    res.approach    = g_shd_appr[bk];
    res.cnt_in      = g_shd_cnt_in[bk];
    res.break_up    = g_shd_break_up[bk];
    res.break_dn    = g_shd_break_dn[bk];
    res.ev_t        = g_shd_ev_t[bk];
    res.entry_t     = g_shd_entry_t[bk];
    res.wka_touch   = g_shd_wka_touch[bk]; res.wka_appr=g_shd_wka_appr[bk];
    res.wka_cnt     = g_shd_wka_cnt[bk];   res.wka_ev  =g_shd_wka_ev[bk];
    res.wkb_touch   = g_shd_wkb_touch[bk]; res.wkb_appr=g_shd_wkb_appr[bk];
    res.wkb_cnt     = g_shd_wkb_cnt[bk];   res.wkb_ev  =g_shd_wkb_ev[bk];
    return true;
}

// ─── TF Satır Çözümleyici ─────────────────────────────────────────
void ResolveTFRow(const TFBoxResult &res, int choch_dir,
                  string &time_out, string &status_out,
                  bool &gecersiz_out, bool &yatay_out, bool &appr_out)
{
    ENUM_TIMEFRAMES tf=res.tf; int ps=PeriodSeconds(tf);
    int  m_ts=res.touch_state, m_ap=res.approach, m_cnt=res.cnt_in;
    datetime m_ev=res.ev_t;
    bool m_ok=res.has_box&&(m_ts>0);
    bool m_gec=!m_ok||IsGecersiz(m_ts,m_cnt,m_ev,tf);
    bool m_yat=false;
    if(m_ok&&!m_gec){int tot=res.break_up+res.break_dn;m_yat=(InpExhaustionCount>0)&&(res.break_up>=1)&&(res.break_dn>=1)&&(tot>=InpExhaustionCount);}

    bool wa_gec=IsGecersiz(res.wka_touch,res.wka_cnt,res.wka_ev,tf)||(res.wka_touch==0);
    bool wb_gec=IsGecersiz(res.wkb_touch,res.wkb_cnt,res.wkb_ev,tf)||(res.wkb_touch==0);

    // En güncel geçerli etkileşimi seç
    int sel=-1; datetime best=0;
    if(!m_gec&&m_ev>best){best=m_ev;sel=0;}
    if(!wa_gec&&res.wka_ev>best){best=res.wka_ev;sel=1;}
    if(!wb_gec&&res.wkb_ev>best){best=res.wkb_ev;sel=2;}

    if(sel<0){
        bool any=m_ok||(res.wka_touch>0)||(res.wkb_touch>0);
        time_out   = any?"25+ mum once   ":"Temas yok      ";
        status_out = "-"; gecersiz_out=true; yatay_out=false; appr_out=false;
        return;
    }
    gecersiz_out=false; yatay_out=false; appr_out=false;

    if(sel==0){
        if(m_ts==1) time_out=StringFormat("%d mum icinde  ",m_cnt);
        else{int mu=(ps>0)?(int)((TimeCurrent()-m_ev)/ps):0;time_out=StringFormat("%d mum once    ",mu);}
        yatay_out=m_yat;
        if(m_yat) status_out=StringFormat("YATAY (U:%d A:%d)",res.break_up,res.break_dn);
        else       status_out=GetBoxStatusShort(m_ts,m_ap,res.break_up,res.break_dn);
        appr_out=IsApproved(choch_dir,m_ts,m_ap,res.break_up,res.break_dn);
    }
    else if(sel==1){
        int ts=res.wka_touch,ap=res.wka_appr,cnt=res.wka_cnt; datetime ev=res.wka_ev;
        if(ts==1) time_out=StringFormat("%d mum icinde  ",cnt);
        else{int mu=(ps>0)?(int)((TimeCurrent()-ev)/ps):0;time_out=StringFormat("%d mum once    ",mu);}
        if(ts==2){status_out=GetBoxStatusShort(ts,ap,0,0);appr_out=IsApproved(choch_dir,ts,ap,0,0);}
        else{status_out="ZAYIF-"+GetBoxStatusShort(ts,ap,0,0);appr_out=IsApprovedWeak(choch_dir,ts,ap);}
    }
    else{
        int ts=res.wkb_touch,ap=res.wkb_appr,cnt=res.wkb_cnt; datetime ev=res.wkb_ev;
        if(ts==1) time_out=StringFormat("%d mum icinde  ",cnt);
        else{int mu=(ps>0)?(int)((TimeCurrent()-ev)/ps):0;time_out=StringFormat("%d mum once    ",mu);}
        if(ts==2){status_out=GetBoxStatusShort(ts,ap,0,0);appr_out=IsApproved(choch_dir,ts,ap,0,0);}
        else{status_out="ZAYIF-"+GetBoxStatusShort(ts,ap,0,0);appr_out=IsApprovedWeak(choch_dir,ts,ap);}
    }
}

// ─── CHoCH Bildirimi ──────────────────────────────────────────────
void SendChochNotif(int choch_dir, bool is_strong, double pb_pct, datetime choch_time, ENUM_TIMEFRAMES signal_tf, int tdx)
{
    ENUM_TIMEFRAMES tfs[5]      = {PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
    double          days_arr[5] = {InpDaysM15, InpDaysM30, InpDaysH1, InpDaysH4, InpDaysD1};
    bool            ena[5]      = {InpEnableM15,InpEnableM30,InpEnableH1,InpEnableH4,InpEnableD1};

    TFBoxResult results[5]; datetime ev_times[5]; int count=0;
    for(int i=0;i<5;i++){
        if(!ena[i]) continue;
        TFBoxResult res; AnalyzeTFBoxResult(tfs[i],days_arr[i],res);
        res.tf=tfs[i]; results[count]=res;
        datetime bt=res.has_box?res.ev_t:0;
        if(res.wka_ev>bt)bt=res.wka_ev; if(res.wkb_ev>bt)bt=res.wkb_ev;
        ev_times[count]=bt; count++;
    }
    for(int i=0;i<count-1;i++)for(int j=i+1;j<count;j++)
        if(ev_times[j]>ev_times[i]){
            datetime tt=ev_times[i];ev_times[i]=ev_times[j];ev_times[j]=tt;
            TFBoxResult tr=results[i];results[i]=results[j];results[j]=tr;}

    // ── Her satır çöz ──────────────────────────────────────────────
    string row_time[5],row_status[5]; bool row_gec[5],row_yat[5],row_appr[5];
    for(int i=0;i<count;i++)
        ResolveTFRow(results[i],choch_dir,row_time[i],row_status[i],row_gec[i],row_yat[i],row_appr[i]);

    // ── Kaskad kararı ──────────────────────────────────────────────
    bool has_yatay=false;
    for(int i=0;i<count;i++) if(!row_gec[i]&&row_yat[i]) has_yatay=true;

    int valid[5]; int v=0;
    for(int i=0;i<count;i++) if(!row_gec[i]){valid[v]=i;v++;}

    int need=has_yatay?3:2;
    bool   trade_ok=false; string trade_reason="Islem Yok";

    if(v>0&&row_appr[valid[0]]){
        trade_ok=true;
        trade_reason=StringFormat("%d. Kutu Onayli -> Isleme Girilir",valid[0]+1);
    }else if(v>need){
        bool all=true; string idx_s="";
        for(int i=1;i<=need;i++){
            if(!row_appr[valid[i]]){all=false;break;}
            if(idx_s!="")idx_s+="+";
            idx_s+=IntegerToString(valid[i]+1);
        }
        if(all){trade_ok=true;trade_reason=idx_s+". Kutu Onayli -> Isleme Girilir";}
    }
    if(has_yatay&&!trade_ok) trade_reason="Islem Yok (YATAY - 3 onayli gerekli)";

    // ── Mesaj ──────────────────────────────────────────────────────
    string nl="\n",sep="=========================";
    string ds=(choch_dir==-1)?"SELL":"BUY";
    string tf_lbl=EnumToString(signal_tf);StringReplace(tf_lbl,"PERIOD_","");
    string msg=StringFormat("CHoCH %s #%d | %s | %s\n",ds,tdx+1,Symbol(),tf_lbl);
    msg+=TimeToString(choch_time,TIME_DATE|TIME_MINUTES);
    msg+=StringFormat(" | %s | %%%d\n",is_strong?"GUCLU":"ZAYIF",(int)MathRound(pb_pct));
    msg+=sep+nl;
    for(int i=0;i<count;i++){
        string rtf=EnumToString(results[i].tf);StringReplace(rtf,"PERIOD_","");
        string tick=row_gec[i]?"GECERSIZ":(row_appr[i]?"OK":"X");
        msg+=StringFormat("%d. %-3s  %s%s  %s\n",i+1,rtf,row_time[i],row_status[i],tick);
    }
    msg+=sep+nl+">>> "+trade_reason;

    Print("=== CHoCH BILDIRIM ===\n"+msg);
    if(InpAlertPopup)Alert(msg);
    if(InpAlertPush)SendNotification(msg);
}

// ─── ProcessBar ───────────────────────────────────────────────────
void ProcessBar(int i,
                const double &open[],const double &high[],
                const double &low[], const double &close[],
                const datetime &time[],
                SState &state,bool is_history,bool draw_ui=true)
{
    double val_h=high[i],val_l=low[i],val_c=close[i];
    double prev_c=(i>0)?close[i-1]:close[i];
    string pfx=is_history?"":"Live_";

    BxUpdateStats(val_h,val_l,val_c,prev_c,time[i]);

    double cur_maj_h=state.maj_h,cur_maj_l=state.maj_l;
    if(state.maj_tr==1  &&state.maj_st==0)cur_maj_h=state.tmp_h;
    if(state.maj_tr==-1 &&state.maj_st==0)cur_maj_l=state.tmp_l;
    double p_pct=0;
    if(cur_maj_h!=EMPTY_VALUE&&cur_maj_l!=EMPTY_VALUE&&cur_maj_h!=cur_maj_l){
        double rng=cur_maj_h-cur_maj_l;
        if(state.maj_tr==1  &&state.min_l>=cur_maj_l)p_pct=((cur_maj_h-state.min_l)/rng)*100.0;
        else if(state.maj_tr==-1&&state.min_h<=cur_maj_h)p_pct=((state.min_h-cur_maj_l)/rng)*100.0;
    }
    bool in_pb=(p_pct>=InpMinPullbackPct);

    // ══ MİNÖR ════════════════════════════════════════════════════
    if(state.min_tr==1){
        double ot=state.trig_l;
        if(val_h>state.min_h){state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;}
        if(val_l<ot){
            int pi=state.min_h_i;double pp=state.min_h;
            int si=state.lp_i;  double sp=state.lp_p;
            if(draw_ui&&InpShowMin)DrawLine(GetUniqueName(pfx+"Minor_"),GetTimeSafe(time,si),sp,GetTimeSafe(time,pi),pp,InpColorMin,1,STYLE_SOLID);
            if(state.maj_tr==-1&&!state.has_pot_bull_minor&&si>=state.tmp_l_i)
            {state.has_pot_bull_minor=true;state.pot_bull_start_i=si;state.pot_bull_start_p=sp;state.pot_bull_end_p=pp;}
            if(state.maj_st==0&&state.maj_tr==1){
                if(state.bx_phase==0||state.bx_phase==2){
                    if(is_history&&(g_shadow_mode||(draw_ui&&InpShowBox)))DoDrawBox(time,pfx,state,si,pp,sp,InpColorBoxBull);
                    state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=pp;state.bx_swing_l=sp;
                }else{if(pp>state.bx_swing_h){state.bx_extreme=true;state.bx_swing_h=pp;}}
            }
            if(state.maj_st==0&&state.maj_tr==-1&&state.bx_phase==1){
                if(state.bx_extreme&&pp>state.bx_swing_h){state.bx_phase=2;state.bx_extreme=false;}
                else state.bx_swing_h=pp;
            }
            state.st_h.Push(pp,pi);
            if(state.maj_tr==1&&state.maj_st==0&&pp<state.tmp_h&&state.st_l.Size()>0)
                if(state.st_l.GetIdx(state.st_l.Size()-1)>state.bos_i)state.st_l.Pop();
            if(state.choch_dir==-1&&state.t2_h!=0)state.choch_dir=0;
            if(state.choch_dir==1&&state.t2_l!=0&&state.min_h<=state.d1_h)state.choch_dir=0;
            if(state.maj_tr==-1&&in_pb){
                if(state.choch_dir==0||state.choch_dir==1){
                    state.t1_h=state.min_h;state.t1_l=state.min_l;state.t1_i=state.min_h_i;
                    state.d1_h=0;state.d1_l=0;state.d1_i=0;
                    state.t2_h=0;state.t2_l=0;state.t2_i=0;state.choch_dir=-1;
                }else if(state.choch_dir==-1){
                    if(state.d1_l==0){state.d1_l=state.min_l;state.d1_i=state.min_l_i;}
                    if(state.d1_l!=0&&state.t2_h==0){state.t2_h=state.min_h;state.t2_i=state.min_h_i;}
                }
            }
            state.min_tr=-1;state.lp_i=pi;state.lp_p=pp;state.min_l=val_l;state.min_l_i=i;state.trig_h=val_h;
        }
    }else{
        double ot=state.trig_h;
        if(val_l<state.min_l){state.min_l=val_l;state.min_l_i=i;state.trig_h=val_h;}
        if(val_h>ot){
            int ti=state.min_l_i;double tp=state.min_l;
            int si=state.lp_i;  double sp=state.lp_p;
            if(draw_ui&&InpShowMin)DrawLine(GetUniqueName(pfx+"Minor_"),GetTimeSafe(time,si),sp,GetTimeSafe(time,ti),tp,InpColorMin,1,STYLE_SOLID);
            if(state.maj_tr==1&&!state.has_pot_bear_minor&&si>=state.tmp_h_i)
            {state.has_pot_bear_minor=true;state.pot_bear_start_i=si;state.pot_bear_start_p=sp;state.pot_bear_end_p=tp;}
            if(state.maj_st==0&&state.maj_tr==1&&state.bx_phase==1){
                if(state.bx_extreme&&tp<state.bx_swing_l){state.bx_phase=2;state.bx_extreme=false;}
                else state.bx_swing_l=tp;
            }
            if(state.maj_st==0&&state.maj_tr==-1){
                if(state.bx_phase==0||state.bx_phase==2){
                    if(is_history&&(g_shadow_mode||(draw_ui&&InpShowBox)))DoDrawBox(time,pfx,state,si,sp,tp,InpColorBoxBear);
                    state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=sp;state.bx_swing_l=tp;
                }else{if(tp<state.bx_swing_l){state.bx_extreme=true;state.bx_swing_l=tp;}}
            }
            state.st_l.Push(tp,ti);
            if(state.maj_tr==-1&&state.maj_st==0&&tp>state.tmp_l&&state.st_h.Size()>0)
                if(state.st_h.GetIdx(state.st_h.Size()-1)>state.bos_i)state.st_h.Pop();
            if(state.choch_dir==1&&state.t2_l!=0)state.choch_dir=0;
            if(state.choch_dir==-1&&state.t2_h!=0&&state.min_l>=state.d1_l)state.choch_dir=0;
            if(state.maj_tr==1&&in_pb){
                if(state.choch_dir==0||state.choch_dir==-1){
                    state.t1_l=state.min_l;state.t1_h=state.min_h;state.t1_i=state.min_l_i;
                    state.d1_l=0;state.d1_h=0;state.d1_i=0;
                    state.t2_l=0;state.t2_h=0;state.t2_i=0;state.choch_dir=1;
                }else if(state.choch_dir==1){
                    if(state.d1_h==0){state.d1_h=state.min_h;state.d1_i=state.min_h_i;}
                    if(state.d1_h!=0&&state.t2_l==0){state.t2_l=state.min_l;state.t2_i=state.min_l_i;}
                }
            }
            state.min_tr=1;state.lp_i=ti;state.lp_p=tp;state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;
        }
    }

    // ══ CHoCH TETİK & ÇİZİM ══════════════════════════════════════

    // --- BEARISH ---
    if(state.choch_dir==-1&&state.t2_h!=0&&state.d1_l!=0){
        double rng=cur_maj_h-cur_maj_l;
        double lvl40=cur_maj_l+rng*(InpMinPullbackPct/100.0);
        bool tv=(rng>0&&state.d1_l>=lvl40&&state.t2_h>=lvl40);
        if(val_c<state.d1_l){
            if(!tv){state.choch_dir=0;state.d1_l=0;state.t2_h=0;}
            else{
                state.last_choch_dir=-1;state.last_choch_level=state.d1_l;state.last_choch_time=time[i];
                state.last_choch_i=i;
                bool is_strong=(state.t2_h>state.t1_h);
                if(draw_ui){
                    static int ld1b=-1;
                    if(state.maj_h_i!=g_current_maj_h_i){ResetBearishMemory();g_current_maj_h_i=state.maj_h_i;ld1b=-1;}
                    bool isn=(state.d1_i!=ld1b);
                    int tdx=-1;
                    if(isn){
                        bool vs=false;
                        if(g_trade_count_h==0)vs=true;
                        else if(g_trade_count_h<2){double pv=MathMax(g_trade_t1_h[g_trade_count_h-1],g_trade_t2_h[g_trade_count_h-1]);if(state.t2_h>pv)vs=true;}
                        if(vs&&g_trade_count_h<2){tdx=g_trade_count_h;g_trade_t1_h[tdx]=state.t1_h;g_trade_t2_h[tdx]=state.t2_h;g_trade_count_h++;}
                    }else{for(int x=0;x<g_trade_count_h;x++)if(g_trade_t1_h[x]==state.t1_h&&g_trade_t2_h[x]==state.t2_h){tdx=x;break;}}
                    if(isn&&tdx>=0&&InpShowChoch){
                        color sc=GetChochColor(tdx);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t1_i),state.t1_h,GetTimeSafe(time,state.d1_i),state.d1_l,sc,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.d1_i),state.d1_l,GetTimeSafe(time,state.t2_i),state.t2_h,sc,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t2_i),state.t2_h,GetTimeSafe(time,i),state.d1_l,sc,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Signal_"),GetTimeSafe(time,i),state.d1_l,GetTimeSafe(time,i)+PeriodSeconds()*5,state.d1_l,sc,3,(tdx<=4)?STYLE_DASH:STYLE_SOLID);
                    }
                    // ── Tum CHoCH'larda bildirim ──
                    // isn'den bağımsız: tdx her zaman resolve edildi
                    {double pb_disp=(rng>0)?((state.t2_h-cur_maj_l)/rng*100.0):0;
                    state.last_choch_tdx=tdx;state.last_choch_strong=is_strong;state.last_choch_pb=pb_disp;}
                    if(tdx>=0 && tdx<=4 && !g_shadow_mode && !is_history){
                        if(state.d1_i != g_last_notif_d1i_sell){
                            g_last_notif_d1i_sell = state.d1_i;
                            double pb_disp=(rng>0)?((state.t2_h-cur_maj_l)/rng*100.0):0;
                            SendChochNotif(-1, is_strong, pb_disp, time[i], Period(), tdx);
                        }
                    }
                    if(isn)ld1b=state.d1_i;
                }
                state.choch_dir=0;
            }
        }
    }
    // --- BULLISH ---
    else if(state.choch_dir==1&&state.t2_l!=0&&state.d1_h!=0){
        double rng=cur_maj_h-cur_maj_l;
        double lvl60=cur_maj_l+rng*(1.0-InpMinPullbackPct/100.0);
        bool tv=(rng>0&&state.d1_h<=lvl60&&state.t2_l<=lvl60);
        if(val_c>state.d1_h){
            if(!tv){state.choch_dir=0;state.d1_h=0;state.t2_l=0;}
            else{
                state.last_choch_dir=1;state.last_choch_level=state.d1_h;state.last_choch_time=time[i];
                state.last_choch_i=i;
                bool is_strong=(state.t2_l<state.t1_l);
                if(draw_ui){
                    static int ld1l=-1;
                    if(state.maj_l_i!=g_current_maj_l_i){ResetBullishMemory();g_current_maj_l_i=state.maj_l_i;ld1l=-1;}
                    bool isn=(state.d1_i!=ld1l);
                    int tdx=-1;
                    if(isn){
                        bool vs=false;
                        if(g_trade_count_l==0)vs=true;
                        else if(g_trade_count_l<2){double pv=MathMin(g_trade_t1_l[g_trade_count_l-1],g_trade_t2_l[g_trade_count_l-1]);if(state.t2_l<pv)vs=true;}
                        if(vs&&g_trade_count_l<2){tdx=g_trade_count_l;g_trade_t1_l[tdx]=state.t1_l;g_trade_t2_l[tdx]=state.t2_l;g_trade_count_l++;}
                    }else{for(int x=0;x<g_trade_count_l;x++)if(g_trade_t1_l[x]==state.t1_l&&g_trade_t2_l[x]==state.t2_l){tdx=x;break;}}
                    if(isn&&tdx>=0&&InpShowChoch){
                        color sc=GetChochColor(tdx);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t1_i),state.t1_l,GetTimeSafe(time,state.d1_i),state.d1_h,sc,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.d1_i),state.d1_h,GetTimeSafe(time,state.t2_i),state.t2_l,sc,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t2_i),state.t2_l,GetTimeSafe(time,i),state.d1_h,sc,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Signal_"),GetTimeSafe(time,i),state.d1_h,GetTimeSafe(time,i)+PeriodSeconds()*5,state.d1_h,sc,3,(tdx<=4)?STYLE_DASH:STYLE_SOLID);
                    }
                    // ── Tum CHoCH'larda bildirim ──
                    {double pb_disp=(rng>0)?((cur_maj_h-state.t2_l)/rng*100.0):0;
                    state.last_choch_tdx=tdx;state.last_choch_strong=is_strong;state.last_choch_pb=pb_disp;}
                    if(tdx>=0 && tdx<=4 && !g_shadow_mode && !is_history){
                        if(state.d1_i != g_last_notif_d1i_buy){
                            g_last_notif_d1i_buy = state.d1_i;
                            double pb_disp=(rng>0)?((cur_maj_h-state.t2_l)/rng*100.0):0;
                            SendChochNotif(1, is_strong, pb_disp, time[i], Period(), tdx);
                        }
                    }
                    if(isn)ld1l=state.d1_i;
                }
                state.choch_dir=0;
            }
        }
    }

    // ══ MAJÖR YAPI ═══════════════════════════════════════════════
    if(state.maj_tr==0){state.maj_tr=1;state.anc_i=state.min_l_i;state.anc_v=state.min_l;state.maj_l_i=state.min_l_i;}

    if(state.maj_tr==1){
        if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
        if(state.maj_st==0){
            double act=state.st_l.Size()>0?state.st_l.GetVal(state.st_l.Size()-1):EMPTY_VALUE;
            if(act!=EMPTY_VALUE&&val_l<act){
                state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
                if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_h_i),state.maj_h,InpColorBull,2,STYLE_SOLID);
                BxAdvanceTrim(GetTimeSafe(time,state.maj_h_i));
                state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
                state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
                CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));
                if(draw_ui&&InpShowMaj){
                    state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");
                    DrawLine(state.cur_top_line,GetTimeSafe(time,state.maj_h_i),state.maj_h,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_h,InpColorBull,1,STYLE_DASH,true);
                    if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,GetTimeSafe(time,state.maj_l_i),state.maj_l,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_l,InpColorBull,1,STYLE_DASH,true);}
                }
            }
            if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0){
                if(val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
                if(val_c<state.maj_l){
                    BxAdvanceTrim(GetTimeSafe(time,state.tmp_h_i));
                    state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
                    if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
                    state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;state.maj_l=val_l;state.maj_l_i=i;
                    if(state.has_pot_bear_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
                    BxReset(state,val_l,state.tmp_h);
                    CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
                }
            }
        }else if(state.maj_st==1){
            if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
            if(state.maj_h!=EMPTY_VALUE&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
            if(val_c>state.maj_h){
                state.bos_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
                if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_l_i),state.maj_l,InpColorBull,2,STYLE_SOLID);
                state.st_h.Clear();state.maj_st=0;state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
                BxReset(state,state.maj_l,val_h);
                CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
            }
            if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0){
                if(val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
                if(val_c<state.maj_l){
                    BxAdvanceTrim(GetTimeSafe(time,state.tmp_h_i));
                    state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
                    if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
                    state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;state.maj_l=val_l;state.maj_l_i=i;
                    if(state.has_pot_bear_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
                    BxReset(state,val_l,state.tmp_h);
                    CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
                }
            }
        }
    }else{
        if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
        if(state.maj_st==0){
            double act=state.st_h.Size()>0?state.st_h.GetVal(state.st_h.Size()-1):EMPTY_VALUE;
            if(act!=EMPTY_VALUE&&val_h>act){
                state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
                if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_l_i),state.maj_l,InpColorBear,2,STYLE_SOLID);
                BxAdvanceTrim(GetTimeSafe(time,state.maj_l_i));
                state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
                state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
                CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));
                if(draw_ui&&InpShowMaj){
                    state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");
                    DrawLine(state.cur_bot_line,GetTimeSafe(time,state.maj_l_i),state.maj_l,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_l,InpColorBear,1,STYLE_DASH,true);
                    if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,GetTimeSafe(time,state.maj_h_i),state.maj_h,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_h,InpColorBear,1,STYLE_DASH,true);}
                }
            }
            if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0){
                if(val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
                if(val_c>state.maj_h){
                    BxAdvanceTrim(GetTimeSafe(time,state.tmp_l_i));
                    state.maj_tr=1;state.maj_st=0;state.bos_i=i;
                    if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
                    state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;state.maj_h=val_h;state.maj_h_i=i;
                    if(state.has_pot_bull_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
                    BxReset(state,state.tmp_l,val_h);
                    CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
                }
            }
        }else if(state.maj_st==1){
            if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
            if(state.maj_l!=EMPTY_VALUE&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
            if(state.maj_l!=EMPTY_VALUE&&val_c<state.maj_l){
                state.maj_h=state.tmp_h;state.bos_i=i;state.maj_h_i=state.tmp_h_i;
                if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_h_i),state.maj_h,InpColorBear,2,STYLE_SOLID);
                state.st_l.Clear();state.maj_st=0;state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
                BxReset(state,val_l,state.maj_h);
                CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
            }
            if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0){
                if(val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
                if(val_c>state.maj_h){
                    BxAdvanceTrim(GetTimeSafe(time,state.tmp_l_i));
                    state.maj_tr=1;state.maj_st=0;state.bos_i=i;
                    if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
                    state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;state.maj_h=val_h;state.maj_h_i=i;
                    if(state.has_pot_bull_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
                    BxReset(state,state.tmp_l,val_h);
                    CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
                }
            }
        }
    }
}

// ─── Test Bildirimi (Kutu Analizi) ───────────────────────────────
string AnalyzeTFBoxes(ENUM_TIMEFRAMES tf, double days_inp, datetime &out_ev_time)
{
    out_ev_time = 0;
    if(tf==PERIOD_M1) return ""; // ← M1 kutu analizi devre dışı
    string lbl=EnumToString(tf); StringReplace(lbl,"PERIOD_","");

    MqlRates r[];
    datetime anc=TimeCurrent()-(datetime)(days_inp*86400.0);
    int n=CopyRates(Symbol(),tf,anc,TimeCurrent(),r);
    if(n<5) return lbl+": Veri yok";

    double o[],h[],l[],c[]; datetime t[];
    ArrayResize(o,n);ArrayResize(h,n);ArrayResize(l,n);ArrayResize(c,n);ArrayResize(t,n);
    for(int j=0;j<n;j++){o[j]=r[j].open;h[j]=r[j].high;l[j]=r[j].low;c[j]=r[j].close;t[j]=r[j].time;}

    g_shadow_mode=true; g_shd_cnt=0;

    SState st;
    int si=0;
    st.min_h=h[si];st.min_h_i=si;st.min_l=l[si];st.min_l_i=si;
    st.trig_h=h[si];st.trig_l=l[si];st.tmp_h=h[si];st.tmp_h_i=si;
    st.tmp_l=l[si];st.tmp_l_i=si;st.min_tr=(c[si]>o[si])?1:-1;
    st.anc_i=si;st.anc_v=c[si];st.lp_i=si;st.lp_p=c[si];
    st.bos_i=si;st.maj_h_i=si;st.maj_l_i=si;
    st.mb_h=h[si];st.mb_l=l[si];st.mb_i=si;
    st.t1_h=0;st.t1_l=0;st.t1_i=0;
    st.d1_h=0;st.d1_l=0;st.d1_i=0;
    st.t2_h=0;st.t2_l=0;st.t2_i=0;
    st.choch_dir=0;st.last_choch_dir=0;st.last_choch_level=0;st.last_choch_time=0;st.last_choch_i=0;st.last_choch_tdx=-1;st.last_choch_strong=false;st.last_choch_pb=0;
    double ig=h[si]-l[si];if(ig==0)ig=Point()*10;
    st.maj_h=h[si]+ig*0.1;st.maj_l=l[si]-ig*0.1;
    st.maj_tr=st.min_tr;st.maj_st=1;
    st.cur_top_line="";st.cur_bot_line="";
    st.st_h.Clear();st.st_l.Clear();
    BxReset(st,l[si],h[si]);
    st.has_pot_bull_minor=false;st.has_pot_bear_minor=false;

    for(int i=si+1;i<n-1;i++){
        bool inside=(h[i]<=st.mb_h)&&(l[i]>=st.mb_l);
        if(!inside){
            if(h[i]>st.mb_h||l[i]<st.mb_l){st.mb_h=h[i];st.mb_l=l[i];st.mb_i=i;}
            ProcessBar(i,o,h,l,c,t,st,true,false); // draw_ui=false
        }else{double pc=(i>0)?c[i-1]:c[i];ShdBxUpdateStats(h[i],l[i],c[i],pc,t[i]);}
    }
    int li=n-1;
    SState sc; sc.CopyFrom(st);
    bool il=(h[li]<=sc.mb_h)&&(l[li]>=sc.mb_l);
    if(!il)ProcessBar(li,o,h,l,c,t,sc,true,false); // draw_ui=false
    else{double pc=(li>0)?c[li-1]:c[li];ShdBxUpdateStats(h[li],l[li],c[li],pc,t[li]);}

    g_shadow_mode=false;

    int bk=-1; datetime bt=0;
    for(int k=0;k<g_shd_cnt;k++){
        if(g_shd_state[k]==0)continue;
        if(g_shd_touch[k]>0 && g_shd_ev_t[k]>bt){bt=g_shd_ev_t[k];bk=k;}
    }
    if(bk<0){
        for(int k=g_shd_cnt-1;k>=0;k--){
            if(g_shd_state[k]>0){bk=k;break;}
        }
    }
    if(bk<0) return lbl+": Kutu yok";

    out_ev_time = g_shd_ev_t[bk];

    string fmt="%." + IntegerToString((int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)) + "f";
    string kutu=StringFormat(fmt,g_shd_top[bk])+" - "+StringFormat(fmt,g_shd_bot[bk]);

    int  total_breaks = g_shd_break_up[bk] + g_shd_break_dn[bk];
    bool is_exhausted = (InpExhaustionCount > 0) &&
                        (g_shd_break_up[bk] >= 1) &&
                        (g_shd_break_dn[bk] >= 1) &&
                        (total_breaks >= InpExhaustionCount);

    string status;
    if(is_exhausted)
        status = StringFormat("*** YATAY BOLGE *** (U:%d A:%d)", g_shd_break_up[bk], g_shd_break_dn[bk]);
    else
        status = GetBoxStatusStr(g_shd_touch[bk], g_shd_appr[bk]);

    // ── Zaman fix: içindeyse entry_t kullan, çıktıysa ev_t ──────
    string time_str = "";
    if(g_shd_ev_t[bk]>0){
        int mum_ps=PeriodSeconds(tf);
        if(g_shd_touch[bk]==1){
            string ago=FormatTimeAgo(g_shd_entry_t[bk]>0 ? g_shd_entry_t[bk] : g_shd_ev_t[bk]);
            time_str=StringFormat(" (%d mum icinde, %s girdi)", g_shd_cnt_in[bk], ago);
        } else if(g_shd_touch[bk]>=2){
            int mums=(mum_ps>0)?(int)((TimeCurrent()-g_shd_ev_t[bk])/mum_ps):0;
            string ago=FormatTimeAgo(g_shd_ev_t[bk]);
            time_str=StringFormat(" (+%d mum once, %s)", mums, ago);
        }
    }

    return StringFormat("%s: [%s] %s%s", lbl, kutu, status, time_str);
}

// ─── Test Bildirimi Gönder ────────────────────────────────────────
void SendTestNotif()
{
    ENUM_TIMEFRAMES tfs[5]      = {PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
    double          days_arr[5] = {InpDaysM15, InpDaysM30, InpDaysH1, InpDaysH4, InpDaysD1};
    bool            ena[5]      = {InpEnableM15,InpEnableM30,InpEnableH1,InpEnableH4,InpEnableD1};

    TFBoxResult results[5];
    datetime    ev_times[5];
    int         count = 0;

    for(int i=0;i<5;i++){
        if(!ena[i]) continue;
        TFBoxResult res;
        AnalyzeTFBoxResult(tfs[i], days_arr[i], res);
        res.tf         = tfs[i];
        results[count] = res;
        ev_times[count]= res.has_box ? res.ev_t : 0;
        count++;
    }

    // En güncel tema en üste
    for(int i=0;i<count-1;i++){
        for(int j=i+1;j<count;j++){
            if(ev_times[j]>ev_times[i]){
                datetime    tmp_t=ev_times[i]; ev_times[i]=ev_times[j]; ev_times[j]=tmp_t;
                TFBoxResult tmp_r=results[i];  results[i]=results[j];   results[j]=tmp_r;
            }
        }
    }

    string nl  = "\n";
    string sep = "=========================";
    string tf_lbl = EnumToString(Period()); StringReplace(tf_lbl,"PERIOD_","");

    string msg = "KUTU ANALIZI | " + Symbol() + " | " + tf_lbl + nl;
    msg += TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES) + nl;
    msg += sep + nl;

    for(int i=0;i<count;i++){
        string rtf=EnumToString(results[i].tf);StringReplace(rtf,"PERIOD_","");
        string t_str,s_str; bool gec,yat,appr;
        ResolveTFRow(results[i],0,t_str,s_str,gec,yat,appr);
        string tag=gec?"  GECERSIZ":"";
        msg+=StringFormat("%d. %-3s  %s%s%s\n",i+1,rtf,t_str,s_str,tag);
    }

    msg += sep;

    if(InpAlertPopup) Alert(msg);
    if(InpAlertPush)  SendNotification(msg);
    Print("=== KUTU TEST BILDIRIMI ===" + nl + msg);
}

// ─── OnInit ───────────────────────────────────────────────────────
int OnInit(){IndicatorSetString(INDICATOR_SHORTNAME,"Structure");return INIT_SUCCEEDED;}

// ─── OnDeinit ─────────────────────────────────────────────────────
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0,"Minor_");  ObjectsDeleteAll(0,"Major_");
    ObjectsDeleteAll(0,"HLine_");  ObjectsDeleteAll(0,"Live_");
    ObjectsDeleteAll(0,"CHoCH_Path_");ObjectsDeleteAll(0,"CHoCH_Signal_");ObjectsDeleteAll(0,"CHoCH_Text_");
    ObjectsDeleteAll(0,"Box_");    ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");
    DeleteLine("LiveLeg");
    BxClear();
    Comment("");
}

// ─── OnCalculate ──────────────────────────────────────────────────
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[], const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[], const int &spread[])
{
    if(rates_total<2)return 0;

    static datetime last_calc_time=0;
    int vp=prev_calculated;
    if(prev_calculated==0&&last_calc_time==time[rates_total-1])vp=rates_total-1;

    int limit;

    if(vp==0){
        last_calc_time=time[rates_total-1];
        double tf_days=GetDaysForTF(Period());
        g_anchor_time=TimeCurrent()-(datetime)(tf_days*24.0*60.0*60.0);
        g_counter=0;

        ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
        ObjectsDeleteAll(0,"Live_"); ObjectsDeleteAll(0,"CHoCH_Path_");ObjectsDeleteAll(0,"CHoCH_Signal_");
        ObjectsDeleteAll(0,"CHoCH_Text_");ObjectsDeleteAll(0,"Box_");
        ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");
        BxClear();

        int si=0;
        for(int k=0;k<rates_total;k++)if(time[k]>=g_anchor_time){si=k;break;}

        g_state_hist.min_h=high[si];g_state_hist.min_h_i=si;g_state_hist.min_l=low[si];g_state_hist.min_l_i=si;
        g_state_hist.trig_h=high[si];g_state_hist.trig_l=low[si];
        g_state_hist.tmp_h=high[si];g_state_hist.tmp_h_i=si;g_state_hist.tmp_l=low[si];g_state_hist.tmp_l_i=si;
        g_state_hist.min_tr=(close[si]>open[si])?1:-1;
        g_state_hist.anc_i=si;g_state_hist.anc_v=close[si];g_state_hist.lp_i=si;g_state_hist.lp_p=close[si];
        g_state_hist.mb_h=high[si];g_state_hist.mb_l=low[si];g_state_hist.mb_i=si;
        g_state_hist.t1_h=0;g_state_hist.t1_l=0;g_state_hist.t1_i=0;
        g_state_hist.d1_h=0;g_state_hist.d1_l=0;g_state_hist.d1_i=0;
        g_state_hist.t2_h=0;g_state_hist.t2_l=0;g_state_hist.t2_i=0;
        g_state_hist.choch_dir=0;g_state_hist.last_choch_dir=0;g_state_hist.last_choch_level=0;g_state_hist.last_choch_time=0;g_state_hist.last_choch_i=0;g_state_hist.last_choch_tdx=-1;g_state_hist.last_choch_strong=false;g_state_hist.last_choch_pb=0;
        double atr=high[si]-low[si];if(atr==0)atr=Point()*10;
        g_state_hist.maj_h=high[si]+atr*0.1;g_state_hist.maj_l=low[si]-atr*0.1;
        g_state_hist.maj_tr=g_state_hist.min_tr;g_state_hist.maj_st=1;
        g_state_hist.bos_i=si;g_state_hist.maj_h_i=si;g_state_hist.maj_l_i=si;
        g_state_hist.cur_top_line="";g_state_hist.cur_bot_line="";
        g_state_hist.st_h.Clear();g_state_hist.st_l.Clear();
        BxReset(g_state_hist,low[si],high[si]);
        g_state_hist.has_pot_bull_minor=false;g_state_hist.has_pot_bear_minor=false;

        limit=si+1;
    }else{limit=vp-1;}

    if(vp==0&&limit<rates_total)
    {g_state_hist.mb_h=high[limit-1];g_state_hist.mb_l=low[limit-1];g_state_hist.mb_i=limit-1;}

    // ── Tarihsel tarama ──
    for(int i=limit;i<rates_total-1;i++)
    {
        bool inside=(high[i]<=g_state_hist.mb_h)&&(low[i]>=g_state_hist.mb_l);
        if(!inside){
            if(high[i]>g_state_hist.mb_h||low[i]<g_state_hist.mb_l)
            {g_state_hist.mb_h=high[i];g_state_hist.mb_l=low[i];g_state_hist.mb_i=i;}
            ProcessBar(i,open,high,low,close,time,g_state_hist,true,true);
        }else{
            double pc=(i>0)?close[i-1]:close[i];
            BxUpdateStats(high[i],low[i],close[i],pc,time[i]);
        }
    }

    // ── Canlı bar ──
    ObjectsDeleteAll(0,"Live_");
    DeleteLine("LiveLeg");

    g_state_curr.CopyFrom(g_state_hist);
    int li=rates_total-1;
    if(li>0){
        bool il=(high[li]<=g_state_curr.mb_h)&&(low[li]>=g_state_curr.mb_l);
        if(!il){
            ProcessBar(li,open,high,low,close,time,g_state_curr,false,true);
        }else{
            double pc=(li>0)?close[li-1]:close[li];
            BxUpdateStats(high[li],low[li],close[li],pc,time[li]);
        }
    }

    if(InpShowMin&&li>0){
        int lgi=(g_state_curr.min_tr==1)?g_state_curr.min_h_i:g_state_curr.min_l_i;
        double lgp=(g_state_curr.min_tr==1)?g_state_curr.min_h:g_state_curr.min_l;
        DrawLine("LiveLeg",GetTimeSafe(time,g_state_curr.lp_i),g_state_curr.lp_p,
                 GetTimeSafe(time,lgi),lgp,InpColorMin,1,STYLE_DOT);
    }

    static bool s_notif_sent = false;
    if(InpNotifTest && !s_notif_sent && rates_total > 2)
    {
        SendTestNotif();
        s_notif_sent = true;
    }
    if(!InpNotifTest) s_notif_sent = false;

    return rates_total;
}
