//+------------------------------------------------------------------+
//|                                                    Structure.mq5 |
//|                    CHoCH + Kutu - Sadece Görsel                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.02"
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

// ─── Bildirim (Kutu Testi) ────────────────────────────────────────
input bool   InpNotifTest         = false; // Test Kutu Bildirimi Gönder

// ─── Globals ──────────────────────────────────────────────────────
int      g_counter     = 0;
datetime g_anchor_time = 0;

// CHoCH etiket takibi
double g_trade_t1_h[5]; double g_trade_t2_h[5];
int    g_trade_count_h = 0; int g_current_maj_h_i = 0;
double g_trade_t1_l[5]; double g_trade_t2_l[5];
int    g_trade_count_l = 0; int g_current_maj_l_i = 0;

void ResetBearishMemory(){g_trade_count_h=0;for(int i=0;i<5;i++){g_trade_t1_h[i]=0;g_trade_t2_h[i]=0;}}
void ResetBullishMemory(){g_trade_count_l=0;for(int i=0;i<5;i++){g_trade_t1_l[i]=0;g_trade_t2_l[i]=0;}}

// ─── Kutu Dizileri ────────────────────────────────────────────────

#define BOX_MAX 512
struct SBoxMem {
    string   nm[BOX_MAX];
    int      state[BOX_MAX];
    double   top[BOX_MAX];
    double   bot[BOX_MAX];
    int      touch_state[BOX_MAX];
    int      approach[BOX_MAX];
    int      inside_cnt[BOX_MAX];
    datetime event_time[BOX_MAX];
    string   wk_abv_nm[BOX_MAX];
    string   wk_blw_nm[BOX_MAX];
    double   wk_abv_top[BOX_MAX];
    double   wk_blw_bot[BOX_MAX];
    int      cnt;

    void Clear(){cnt=0;}
    void CopyFrom(SBoxMem &o){
        cnt=o.cnt;
        for(int i=0;i<cnt;i++){
            nm[i]=o.nm[i]; state[i]=o.state[i]; top[i]=o.top[i]; bot[i]=o.bot[i];
            touch_state[i]=o.touch_state[i]; approach[i]=o.approach[i];
            inside_cnt[i]=o.inside_cnt[i]; event_time[i]=o.event_time[i];
            wk_abv_nm[i]=o.wk_abv_nm[i]; wk_blw_nm[i]=o.wk_blw_nm[i];
            wk_abv_top[i]=o.wk_abv_top[i]; wk_blw_bot[i]=o.wk_blw_bot[i];
        }
    }
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

void DrawLine(string nm,datetime t1,double p1,datetime t2,double p2,
              color clr,int w,ENUM_LINE_STYLE st,bool ray=false)
{
    if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_TREND,0,t1,p1,t2,p2);
    else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p1);
         ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2);ObjectSetDouble(0,nm,OBJPROP_PRICE,1,p2);}
    ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_WIDTH,w);
    ObjectSetInteger(0,nm,OBJPROP_STYLE,st); ObjectSetInteger(0,nm,OBJPROP_RAY_RIGHT,ray);
    ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void DeleteLine(string n){if(ObjectFind(0,n)>=0)ObjectDelete(0,n);}
void CutLine(string n,datetime t){if(ObjectFind(0,n)>=0){ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,n,OBJPROP_TIME,1,t);}}
void UpdateLineLevel(string n,double v){if(ObjectFind(0,n)>=0){ObjectSetDouble(0,n,OBJPROP_PRICE,0,v);ObjectSetDouble(0,n,OBJPROP_PRICE,1,v);}}

void DrawRect(string nm,datetime t1,double top,datetime t2,double bot,color clr)
{
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
    if(top<bot){double tmp=top;top=bot;bot=tmp;}
    if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,top,D'2099.12.31 00:00',bot);
    else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,top);
         ObjectSetInteger(0,nm,OBJPROP_TIME,1,D'2099.12.31 00:00');ObjectSetDouble(0,nm,OBJPROP_PRICE,1,bot);}
    ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_DOT);
    ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);  ObjectSetInteger(0,nm,OBJPROP_FILL,false);
    ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}

// ─── Kutu Fonksiyonları ───────────────────────────────────────────
void BxAdd(SBoxMem &bmem, string nm,double top,double bot,color box_clr,const datetime &time[],int right_i, bool draw_ui)
{
    if(bmem.cnt>=BOX_MAX)return;
    double wk_sz=(top-bot)*InpWeakZonePct/100.0;
    color wk_clr=(box_clr==InpColorBoxBull||box_clr==InpColorBoxBullFaint)?InpColorWeakBull:InpColorWeakBear;
    int k = bmem.cnt;
    bmem.nm[k]=nm; bmem.state[k]=2;
    bmem.top[k]=top; bmem.bot[k]=bot;
    bmem.touch_state[k]=0; bmem.approach[k]=0;
    bmem.inside_cnt[k]=0;  bmem.event_time[k]=0;
    bmem.wk_abv_nm[k]="BoxWkAbv_"+nm;
    bmem.wk_blw_nm[k]="BoxWkBlw_"+nm;
    bmem.wk_abv_top[k]=top+wk_sz;
    bmem.wk_blw_bot[k]=bot-wk_sz;
    if(draw_ui) {
        datetime t_left=GetTimeSafe(time,right_i);
        _DrawWeakRect(bmem.wk_abv_nm[k],t_left,bmem.wk_abv_top[k],top,wk_clr);
        _DrawWeakRect(bmem.wk_blw_nm[k],t_left,bot,bmem.wk_blw_bot[k],wk_clr);
    }
    bmem.cnt++;
}

void BxUpdateStats(SBoxMem &bmem, double h,double l,double c,double prev_c,datetime bar_time)
{
    for(int k=0;k<bmem.cnt;k++)
    {
        if(bmem.state[k]==0)continue;
        double top=bmem.top[k],bot=bmem.bot[k];
        bool im=(h>=bot)&&(l<=top);
        int na;if(prev_c>top)na=1;else if(prev_c<bot)na=-1;else na=bmem.approach[k];
        int ts=bmem.touch_state[k];
        if(ts==0){if(im){
            bmem.approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);
            bmem.touch_state[k]=1;bmem.inside_cnt[k]=1;bmem.event_time[k]=bar_time;
        }}
        else if(ts==1){if(im){bmem.inside_cnt[k]++;bmem.event_time[k]=bar_time;}
            else{bool bd=(c<bot),bu=(c>top);int ap=bmem.approach[k];
                if(ap==1){if(bd)bmem.touch_state[k]=2;else if(bu)bmem.touch_state[k]=3;}
                else{if(bu)bmem.touch_state[k]=2;else if(bd)bmem.touch_state[k]=3;}
                bmem.event_time[k]=bar_time;}}
        else{if(im){
            bmem.approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);
            bmem.touch_state[k]=1;bmem.inside_cnt[k]=1;bmem.event_time[k]=bar_time;
        }}
    }
}

void BxAdvanceTrim(SBoxMem &bmem, datetime t, bool draw_ui)
{
    for(int k=0;k<bmem.cnt;k++){
        if(bmem.state[k]==1){
            if(bmem.touch_state[k]==1)continue;
            if(draw_ui) {
                if(ObjectFind(0,bmem.nm[k])>=0)       ObjectSetInteger(0,bmem.nm[k],OBJPROP_TIME,1,t);
                if(ObjectFind(0,bmem.wk_abv_nm[k])>=0)ObjectSetInteger(0,bmem.wk_abv_nm[k],OBJPROP_TIME,1,t);
                if(ObjectFind(0,bmem.wk_blw_nm[k])>=0)ObjectSetInteger(0,bmem.wk_blw_nm[k],OBJPROP_TIME,1,t);
            }
            bmem.state[k]=0;
        }
        else if(bmem.state[k]==2)bmem.state[k]=1;
    }
}

void BxDeleteAll(SBoxMem &bmem)
{
    for(int k=0;k<bmem.cnt;k++){
        if(ObjectFind(0,bmem.nm[k])>=0)       ObjectDelete(0,bmem.nm[k]);
        if(ObjectFind(0,bmem.wk_abv_nm[k])>=0)ObjectDelete(0,bmem.wk_abv_nm[k]);
        if(ObjectFind(0,bmem.wk_blw_nm[k])>=0)ObjectDelete(0,bmem.wk_blw_nm[k]);
    }
    bmem.cnt=0;
}
void BxClear(SBoxMem &bmem){bmem.cnt=0;}

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

    // CHoCH
    double t1_h,t1_l;int t1_i;
    double d1_h,d1_l;int d1_i;
    double t2_h,t2_l;int t2_i;
    int    choch_dir;
    int    last_choch_dir;double last_choch_level;datetime last_choch_time;int last_choch_i;

    // Kutu
    int    bx_phase;bool bx_extreme;double bx_swing_h,bx_swing_l;
    bool   has_pot_bull_minor;int pot_bull_start_i;double pot_bull_start_p,pot_bull_end_p;
    bool   has_pot_bear_minor;int pot_bear_start_i;double pot_bear_start_p,pot_bear_end_p;

    CStack st_h,st_l;
    SBoxMem bmem;

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
        bx_phase=s.bx_phase;bx_extreme=s.bx_extreme;
        bx_swing_h=s.bx_swing_h;bx_swing_l=s.bx_swing_l;
        has_pot_bull_minor=s.has_pot_bull_minor;pot_bull_start_i=s.pot_bull_start_i;
        pot_bull_start_p=s.pot_bull_start_p;pot_bull_end_p=s.pot_bull_end_p;
        has_pot_bear_minor=s.has_pot_bear_minor;pot_bear_start_i=s.pot_bear_start_i;
        pot_bear_start_p=s.pot_bear_start_p;pot_bear_end_p=s.pot_bear_end_p;
        st_h.CopyFrom(s.st_h);st_l.CopyFrom(s.st_l);
        bmem.CopyFrom(s.bmem);}
};

SState g_state_hist,g_state_curr;

void BxReset(SState &s,double rl,double rh){s.bx_phase=0;s.bx_extreme=false;s.bx_swing_l=rl;s.bx_swing_h=rh;}

// ─── DoDrawBox ────────────────────────────────────────────────────
void DoDrawBox(const datetime &time[],string pfx,SState &s,
               int left_i,double top,double bot,color clr, bool draw_ui=true)
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
    if(draw_ui) DrawRect(nm,GetTimeSafe(time,left_i),top,D'2099.12.31 00:00',bot,clr);
    BxAdd(s.bmem, nm,top,bot,clr,time,left_i, draw_ui);
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

    // Kutu istatistik (her zaman, çizim bağımsız)
    BxUpdateStats(state.bmem, val_h,val_l,val_c,prev_c,time[i]);

    // CHoCH bölge hesabı
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

            // Pot bull minor (bearish trend → bullish faint kutu için)
            if(state.maj_tr==-1&&!state.has_pot_bull_minor&&si>=state.tmp_l_i)
            {state.has_pot_bull_minor=true;state.pot_bull_start_i=si;state.pot_bull_start_p=sp;state.pot_bull_end_p=pp;}

            // Kutu: bullish impuls aşaması (maj_tr==1, maj_st==0)
            if(state.maj_st==0&&state.maj_tr==1){
                if(state.bx_phase==0||state.bx_phase==2){
                    if(InpShowBox&&is_history)DoDrawBox(time,pfx,state,si,pp,sp,InpColorBoxBull,draw_ui);
                    state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=pp;state.bx_swing_l=sp;
                }else{if(pp>state.bx_swing_h){state.bx_extreme=true;state.bx_swing_h=pp;}}
            }
            // Kutu: bearish extreme takibi (maj_tr==-1, maj_st==0, bx_phase==1)
            if(state.maj_st==0&&state.maj_tr==-1&&state.bx_phase==1){
                if(state.bx_extreme&&pp>state.bx_swing_h){state.bx_phase=2;state.bx_extreme=false;}
                else state.bx_swing_h=pp;
            }

            state.st_h.Push(pp,pi);
            if(state.maj_tr==1&&state.maj_st==0&&pp<state.tmp_h&&state.st_l.Size()>0)
                if(state.st_l.GetIdx(state.st_l.Size()-1)>state.bos_i)state.st_l.Pop();

            // CHoCH geçersizleştirme
            if(state.choch_dir==-1&&state.t2_h!=0)state.choch_dir=0;
            if(state.choch_dir==1&&state.t2_l!=0&&state.min_h<=state.d1_h)state.choch_dir=0;

            // Bearish CHoCH T1-D1-T2
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

            // Pot bear minor (bullish trend → bearish faint kutu için)
            if(state.maj_tr==1&&!state.has_pot_bear_minor&&si>=state.tmp_h_i)
            {state.has_pot_bear_minor=true;state.pot_bear_start_i=si;state.pot_bear_start_p=sp;state.pot_bear_end_p=tp;}

            // Kutu: bullish extreme takibi (maj_tr==1, maj_st==0, bx_phase==1)
            if(state.maj_st==0&&state.maj_tr==1&&state.bx_phase==1){
                if(state.bx_extreme&&tp<state.bx_swing_l){state.bx_phase=2;state.bx_extreme=false;}
                else state.bx_swing_l=tp;
            }
            // Kutu: bearish impuls aşaması (maj_tr==-1, maj_st==0)
            if(state.maj_st==0&&state.maj_tr==-1){
                if(state.bx_phase==0||state.bx_phase==2){
                    if(InpShowBox&&is_history)DoDrawBox(time,pfx,state,si,sp,tp,InpColorBoxBear,draw_ui);
                    state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=sp;state.bx_swing_l=tp;
                }else{if(tp<state.bx_swing_l){state.bx_extreme=true;state.bx_swing_l=tp;}}
            }

            state.st_l.Push(tp,ti);
            if(state.maj_tr==-1&&state.maj_st==0&&tp>state.tmp_l&&state.st_h.Size()>0)
                if(state.st_h.GetIdx(state.st_h.Size()-1)>state.bos_i)state.st_h.Pop();

            // CHoCH geçersizleştirme
            if(state.choch_dir==1&&state.t2_l!=0)state.choch_dir=0;
            if(state.choch_dir==-1&&state.t2_h!=0&&state.min_l>=state.d1_l)state.choch_dir=0;

            // Bullish CHoCH T1-D1-T2
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
                bool is_strong=(state.t2_h>state.t1_h);
                if(draw_ui){
                    static int ld1b=0;
                    if(state.maj_h_i!=g_current_maj_h_i){ResetBearishMemory();g_current_maj_h_i=state.maj_h_i;}
                    bool isn=(state.d1_i!=ld1b);
                    int tdx=-1;
                    if(isn){
                        bool vs=false;
                        if(g_trade_count_h==0)vs=true;
                        else if(g_trade_count_h<5){double pv=MathMax(g_trade_t1_h[g_trade_count_h-1],g_trade_t2_h[g_trade_count_h-1]);if(state.t2_h>pv)vs=true;}
                        if(vs&&g_trade_count_h<5){tdx=g_trade_count_h;g_trade_t1_h[tdx]=state.t1_h;g_trade_t2_h[tdx]=state.t2_h;g_trade_count_h++;}
                    }else{for(int x=0;x<g_trade_count_h;x++)if(g_trade_t1_h[x]==state.t1_h&&g_trade_t2_h[x]==state.t2_h){tdx=x;break;}}
                    if(isn&&tdx>=0&&InpShowChoch){
                        color sc=is_strong?InpColorChochStrong:InpColorChochWeak;
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t1_i),state.t1_h,GetTimeSafe(time,state.d1_i),state.d1_l,InpColorChochPath,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.d1_i),state.d1_l,GetTimeSafe(time,state.t2_i),state.t2_h,InpColorChochPath,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t2_i),state.t2_h,GetTimeSafe(time,i),state.d1_l,InpColorChochPath,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Signal_"),GetTimeSafe(time,i),state.d1_l,GetTimeSafe(time,i)+PeriodSeconds()*5,state.d1_l,sc,3,STYLE_SOLID);
                        string tn=GetUniqueName(pfx+"CHoCH_Text_");
                        ObjectCreate(0,tn,OBJ_TEXT,0,GetTimeSafe(time,i),state.d1_l);
                        ObjectSetString(0,tn,OBJPROP_TEXT,IntegerToString(tdx+1));
                        ObjectSetInteger(0,tn,OBJPROP_COLOR,sc);
                        ObjectSetInteger(0,tn,OBJPROP_FONTSIZE,10);
                        ObjectSetInteger(0,tn,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
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
                bool is_strong=(state.t2_l<state.t1_l);
                if(draw_ui){
                    static int ld1l=0;
                    if(state.maj_l_i!=g_current_maj_l_i){ResetBullishMemory();g_current_maj_l_i=state.maj_l_i;}
                    bool isn=(state.d1_i!=ld1l);
                    int tdx=-1;
                    if(isn){
                        bool vs=false;
                        if(g_trade_count_l==0)vs=true;
                        else if(g_trade_count_l<5){double pv=MathMin(g_trade_t1_l[g_trade_count_l-1],g_trade_t2_l[g_trade_count_l-1]);if(state.t2_l<pv)vs=true;}
                        if(vs&&g_trade_count_l<5){tdx=g_trade_count_l;g_trade_t1_l[tdx]=state.t1_l;g_trade_t2_l[tdx]=state.t2_l;g_trade_count_l++;}
                    }else{for(int x=0;x<g_trade_count_l;x++)if(g_trade_t1_l[x]==state.t1_l&&g_trade_t2_l[x]==state.t2_l){tdx=x;break;}}
                    if(isn&&tdx>=0&&InpShowChoch){
                        color sc=is_strong?InpColorChochStrong:InpColorChochWeak;
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t1_i),state.t1_l,GetTimeSafe(time,state.d1_i),state.d1_h,InpColorChochPath,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.d1_i),state.d1_h,GetTimeSafe(time,state.t2_i),state.t2_l,InpColorChochPath,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t2_i),state.t2_l,GetTimeSafe(time,i),state.d1_h,InpColorChochPath,1,STYLE_DOT);
                        DrawLine(GetUniqueName(pfx+"CHoCH_Signal_"),GetTimeSafe(time,i),state.d1_h,GetTimeSafe(time,i)+PeriodSeconds()*5,state.d1_h,sc,3,STYLE_SOLID);
                        string tn=GetUniqueName(pfx+"CHoCH_Text_");
                        ObjectCreate(0,tn,OBJ_TEXT,0,GetTimeSafe(time,i),state.d1_h);
                        ObjectSetString(0,tn,OBJPROP_TEXT,IntegerToString(tdx+1));
                        ObjectSetInteger(0,tn,OBJPROP_COLOR,sc);
                        ObjectSetInteger(0,tn,OBJPROP_FONTSIZE,10);
                        ObjectSetInteger(0,tn,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);
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
                BxAdvanceTrim(state.bmem, GetTimeSafe(time,state.maj_h_i), draw_ui);
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
                    BxAdvanceTrim(state.bmem, GetTimeSafe(time,state.tmp_h_i), draw_ui);
                    state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
                    if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
                    state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;state.maj_l=val_l;state.maj_l_i=i;
                    if(state.has_pot_bear_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint,draw_ui);
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
                    BxAdvanceTrim(state.bmem, GetTimeSafe(time,state.tmp_h_i), draw_ui);
                    state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
                    if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
                    state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;state.maj_l=val_l;state.maj_l_i=i;
                    if(state.has_pot_bear_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint,draw_ui);
                    BxReset(state,val_l,state.tmp_h);
                    CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
                }
            }
        }
    }else{ // maj_tr == -1
        if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
        if(state.maj_st==0){
            double act=state.st_h.Size()>0?state.st_h.GetVal(state.st_h.Size()-1):EMPTY_VALUE;
            if(act!=EMPTY_VALUE&&val_h>act){
                state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
                if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_l_i),state.maj_l,InpColorBear,2,STYLE_SOLID);
                BxAdvanceTrim(state.bmem, GetTimeSafe(time,state.maj_l_i), draw_ui);
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
                    BxAdvanceTrim(state.bmem, GetTimeSafe(time,state.tmp_l_i), draw_ui);
                    state.maj_tr=1;state.maj_st=0;state.bos_i=i;
                    if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
                    state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;state.maj_h=val_h;state.maj_h_i=i;
                    if(state.has_pot_bull_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint,draw_ui);
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
                    BxAdvanceTrim(state.bmem, GetTimeSafe(time,state.tmp_l_i), draw_ui);
                    state.maj_tr=1;state.maj_st=0;state.bos_i=i;
                    if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
                    state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;state.maj_h=val_h;state.maj_h_i=i;
                    if(state.has_pot_bull_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint,draw_ui);
                    BxReset(state,state.tmp_l,val_h);
                    CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
                }
            }
        }
    }
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
    BxClear(g_state_hist.bmem); BxClear(g_state_curr.bmem);
    Comment("");
}

// ─── OnCalculate ──────────────────────────────────────────────────

// ─── Kutu Analizi ve Bildirim ─────────────────────────────────────
string GetBoxInteraction(SBoxMem &bmem)
{
    string msg = "";
    int hit_cnt = 0;

    // Sadece en son oluşan 1 veya 2 kutuya bakabiliriz,
    // ama bmem'de aktif (state==1 veya state==2) kutuları tarayalım
    for(int k=bmem.cnt-1; k>=0; k--){
        if(bmem.state[k] == 0) continue; // Pasif kutu
        if(hit_cnt > 0) break; // Şimdilik sadece en son güncel kutuyu analiz edelim
        hit_cnt++;

        string durum = "Kutu İçi";
        int ts = bmem.touch_state[k];
        int ap = bmem.approach[k];

        if(ts == 0) {
            durum = "Kutuya degmedi";
        } else if(ts == 1) {
            if(ap == -1) durum = "altindan geldi kutu icinde";
            else if(ap == 1) durum = "ustunden geldi kutu icinde";
            else durum = "Kutu icinde";
        } else if(ts == 2) {
            if(ap == -1) durum = "altindan yukari deldi"; // came from below (-1), pierced up (ts=2 -> bu)
            else if(ap == 1) durum = "alti deldi"; // came from above (1), pierced down (ts=2 -> bd)
            else durum = "Kutudan cikti";
        } else if(ts == 3) {
            if(ap == 1) durum = "yukardan kutu icinden tepki aldi"; // came from above (1), bounced up (ts=3 -> bu)
            else if(ap == -1) durum = "assagi dan kutu icinden tepki aldi"; // came from below (-1), bounced down (ts=3 -> bd)
            else durum = "Kutudan tepki aldi";
        }

        msg = "Seviyeler: " + DoubleToString(bmem.top[k], 5) + " - " + DoubleToString(bmem.bot[k], 5) + " | Durum: " + durum;
    }

    if(msg == "") return "Aktif kutu bulunamadı.";
    return msg;
}

void CheckMTFBoxNotifications()
{
    static bool test_notif_sent = false;
    if(!InpNotifTest || test_notif_sent) return;

    ENUM_TIMEFRAMES tfs[] = {PERIOD_M15, PERIOD_M30, PERIOD_H1};
    string tfs_names[] = {"M15", "M30", "H1"};
    string msg = "KUTU TEST ANALİZİ:\n";

    for(int i=0; i<3; i++){
        ENUM_TIMEFRAMES tf = tfs[i];
        double tf_days = GetDaysForTF(tf);
        datetime anc_time = TimeCurrent() - (datetime)(tf_days*24.0*60.0*60.0);

        MqlRates rates[];
        ArraySetAsSeries(rates, false); // Eski bar 0
        int count = CopyRates(_Symbol, tf, anc_time, TimeCurrent(), rates);

        if(count > 0){
            SState tf_state;

            tf_state.bmem.Clear();
            tf_state.st_h.Clear(); tf_state.st_l.Clear();

            int si = 0;
            tf_state.min_h=rates[si].high; tf_state.min_h_i=si; tf_state.min_l=rates[si].low; tf_state.min_l_i=si;
            tf_state.trig_h=rates[si].high; tf_state.trig_l=rates[si].low;
            tf_state.tmp_h=rates[si].high; tf_state.tmp_h_i=si; tf_state.tmp_l=rates[si].low; tf_state.tmp_l_i=si;
            tf_state.min_tr=(rates[si].close>rates[si].open)?1:-1;
            tf_state.anc_i=si; tf_state.anc_v=rates[si].close; tf_state.lp_i=si; tf_state.lp_p=rates[si].close;
            tf_state.mb_h=rates[si].high; tf_state.mb_l=rates[si].low; tf_state.mb_i=si;
            tf_state.t1_h=0; tf_state.t1_l=0; tf_state.t1_i=0;
            tf_state.d1_h=0; tf_state.d1_l=0; tf_state.d1_i=0;
            tf_state.t2_h=0; tf_state.t2_l=0; tf_state.t2_i=0;
            tf_state.choch_dir=0; tf_state.last_choch_dir=0; tf_state.last_choch_level=0; tf_state.last_choch_time=0;

            double atr=rates[si].high-rates[si].low; if(atr==0)atr=Point()*10;
            tf_state.maj_h=rates[si].high+atr*0.1; tf_state.maj_l=rates[si].low-atr*0.1;
            tf_state.maj_tr=tf_state.min_tr; tf_state.maj_st=1;
            tf_state.bos_i=si; tf_state.maj_h_i=si; tf_state.maj_l_i=si;
            tf_state.cur_top_line=""; tf_state.cur_bot_line="";
            BxReset(tf_state,rates[si].low,rates[si].high);
            tf_state.has_pot_bull_minor=false; tf_state.has_pot_bear_minor=false;

            // Allocate double arrays for OHLCT
            double o[], h[], l[], c[];
            datetime t[];
            ArrayResize(o, count); ArrayResize(h, count); ArrayResize(l, count); ArrayResize(c, count); ArrayResize(t, count);
            for(int j=0; j<count; j++){
                o[j] = rates[j].open; h[j] = rates[j].high; l[j] = rates[j].low; c[j] = rates[j].close; t[j] = rates[j].time;
            }

            for(int j=1; j<count; j++){
                bool inside=(h[j]<=tf_state.mb_h)&&(l[j]>=tf_state.mb_l);
                if(!inside){
                    if(h[j]>tf_state.mb_h||l[j]<tf_state.mb_l)
                    {tf_state.mb_h=h[j]; tf_state.mb_l=l[j]; tf_state.mb_i=j;}
                    ProcessBar(j,o,h,l,c,t,tf_state,true,false);
                }else{
                    double pc=(j>0)?c[j-1]:c[j];
                    BxUpdateStats(tf_state.bmem, h[j],l[j],c[j],pc,t[j]);
                }
            }

            msg += tfs_names[i] + ": " + GetBoxInteraction(tf_state.bmem) + "\n";
        }
    }

    SendNotification(msg);
    Print(msg);
    test_notif_sent = true;
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
        BxClear(g_state_hist.bmem); BxClear(g_state_curr.bmem);

        int si=0;
        g_state_hist.min_h=high[si];g_state_hist.min_h_i=si;g_state_hist.min_l=low[si];g_state_hist.min_l_i=si;
        g_state_hist.trig_h=high[si];g_state_hist.trig_l=low[si];
        g_state_hist.tmp_h=high[si];g_state_hist.tmp_h_i=si;g_state_hist.tmp_l=low[si];g_state_hist.tmp_l_i=si;
        g_state_hist.min_tr=(close[si]>open[si])?1:-1;
        g_state_hist.anc_i=si;g_state_hist.anc_v=close[si];g_state_hist.lp_i=si;g_state_hist.lp_p=close[si];
        g_state_hist.mb_h=high[si];g_state_hist.mb_l=low[si];g_state_hist.mb_i=si;
        g_state_hist.t1_h=0;g_state_hist.t1_l=0;g_state_hist.t1_i=0;
        g_state_hist.d1_h=0;g_state_hist.d1_l=0;g_state_hist.d1_i=0;
        g_state_hist.t2_h=0;g_state_hist.t2_l=0;g_state_hist.t2_i=0;
        g_state_hist.choch_dir=0;g_state_hist.last_choch_dir=0;g_state_hist.last_choch_level=0;g_state_hist.last_choch_time=0;
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
            bool sd=(time[i]>=g_anchor_time);
            ProcessBar(i,open,high,low,close,time,g_state_hist,true,sd);
        }else{
            // Inside bar: kutu durumunu güncelle
            double pc=(i>0)?close[i-1]:close[i];
            BxUpdateStats(g_state_hist.bmem, high[i],low[i],close[i],pc,time[i]);
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
            bool sd=(time[li]>=g_anchor_time);
            ProcessBar(li,open,high,low,close,time,g_state_curr,false,sd);
        }else{
            double pc=(li>0)?close[li-1]:close[li];
            BxUpdateStats(g_state_curr.bmem, high[li],low[li],close[li],pc,time[li]);
        }
    }

    // Canlı minör bacak
    if(InpShowMin&&li>0){
        int lgi=(g_state_curr.min_tr==1)?g_state_curr.min_h_i:g_state_curr.min_l_i;
        double lgp=(g_state_curr.min_tr==1)?g_state_curr.min_h:g_state_curr.min_l;
        DrawLine("LiveLeg",GetTimeSafe(time,g_state_curr.lp_i),g_state_curr.lp_p,
                 GetTimeSafe(time,lgi),lgp,InpColorMin,1,STYLE_DOT);
    }


    CheckMTFBoxNotifications();

    return rates_total;
}
