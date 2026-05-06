//+------------------------------------------------------------------+
//|                                         smacv2_choch_box.mq5     |
//|   SMC v2  v30.02  –  M5 Paralel Golge State Machine             |
//|   M1 grafikte bildirim icin her sey M5 verisinden geliyor        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "30.02"
#property indicator_chart_window
#property indicator_plots 0

input group "--- ZAMAN ARALIĞI (Gün) ---"
input double InpDaysM1   = 1.0;
input double InpDaysM5   = 5.0;
input double InpDaysM15  = 15.0;
input double InpDaysM30  = 30.0;
input double InpDaysH1   = 60.0;
input double InpDaysH4   = 240.0;
input double InpDaysD1   = 1440.0;

input group "--- BİLDİRİM ---"
input bool   InpNotifTest    = false;
input bool   InpNotifSignal  = true;
input bool   InpSmartNotif   = true;
input int    InpNotifInterval= 60;

input group "--- GÖRSEL ---"
input bool   InpShowMin      = true;
input bool   InpShowMaj      = true;
input bool   InpShowVL       = true;
input bool   InpShowBox      = true;
input color  InpColorMin     = clrSilver;
input color  InpColorBull    = clrLime;
input color  InpColorBear    = clrRed;
input color  InpColorVLBull  = clrDodgerBlue;
input color  InpColorVLBear  = clrOrangeRed;
input color  InpColorBoxBull = clrDodgerBlue;
input color  InpColorBoxBear = clrRed;
input color  InpColorBoxBullFaint = C'0,40,90';
input color  InpColorBoxBearFaint = C'90,20,0';

input group "--- KUTU ---"
input double InpMaxBoxPct    = 20.0;
input double InpWeakZonePct  = 50.0;
input color  InpColorWeakBull = C'0,25,55';
input color  InpColorWeakBear = C'55,15,0';

input group "--- İSTATİSTİK ---"
input bool   InpShowStats   = true;
input color  InpColorStats  = clrWhite;
input int    InpStatsFontSz = 8;

int      g_counter     = 0;
datetime g_anchor_time = 0;

// ====================================================================
// M5 GOLGE MODU
// g_m5_mode=true  →  Bx*/Draw* fonksiyonlari M5 dizilerine yonlenir,
//                     hicbir grafik nesnesi olusturulmaz.
// ====================================================================
bool g_m5_mode = false;

#define M5_BOX_MAX 64
int      g_m5_bx_state[M5_BOX_MAX];
double   g_m5_bx_top[M5_BOX_MAX];
double   g_m5_bx_bot[M5_BOX_MAX];
double   g_m5_bx_wk_abv[M5_BOX_MAX];
double   g_m5_bx_wk_blw[M5_BOX_MAX];
int      g_m5_bx_ts[M5_BOX_MAX];
int      g_m5_bx_appr[M5_BOX_MAX];
int      g_m5_bx_cnt_in[M5_BOX_MAX];
datetime g_m5_bx_ev_t[M5_BOX_MAX];
int      g_m5_bx_wkt[M5_BOX_MAX];
datetime g_m5_bx_wk_t[M5_BOX_MAX];
int      g_m5_bx_cnt = 0;

// ====================================================================
// GRAFIK TF KUTU dizileri
// ====================================================================
#define BOX_MAX 512
string   g_bx_nm[BOX_MAX];
int      g_bx_state[BOX_MAX];
double   g_bx_top[BOX_MAX];
double   g_bx_bot[BOX_MAX];
string   g_bx_lbl[BOX_MAX];
int      g_bx_touch_state[BOX_MAX];
int      g_bx_approach[BOX_MAX];
int      g_bx_inside_cnt[BOX_MAX];
datetime g_bx_event_time[BOX_MAX];
string   g_bx_wk_abv_nm[BOX_MAX];
string   g_bx_wk_blw_nm[BOX_MAX];
double   g_bx_wk_abv_top[BOX_MAX];
double   g_bx_wk_blw_bot[BOX_MAX];
int      g_bx_wk_touch[BOX_MAX];
datetime g_bx_wk_time[BOX_MAX];
int      g_bx_cnt = 0;

// --------------------------------------------------------------------
double GetActiveDays()
{
   switch(Period())
   {
      case PERIOD_M1:  return InpDaysM1;
      case PERIOD_M5:  return InpDaysM5;
      case PERIOD_M15: return InpDaysM15;
      case PERIOD_M30: return InpDaysM30;
      case PERIOD_H1:  return InpDaysH1;
      case PERIOD_H4:  return InpDaysH4;
      case PERIOD_D1:  return InpDaysD1;
      default:         return InpDaysH1;
   }
}

// ====================================================================
// CIZIM YARDIMCILARI  –  g_m5_mode=true iken hepsi erken cikiyor
// ====================================================================
datetime ST(const datetime &t[],int idx)
{ int s=ArraySize(t);if(s<=0)return 0;if(idx<0)return t[0];if(idx>=s)return t[s-1];return t[idx]; }

string GetUniqueName(string p){ g_counter++; return p+IntegerToString(g_counter); }

void DrawLine(string nm,datetime t1,double p1,datetime t2,double p2,
              color clr,int w,ENUM_LINE_STYLE st,bool ray=false)
{
   if(g_m5_mode) return;
   if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_TREND,0,t1,p1,t2,p2);
   else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p1);
        ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2);ObjectSetDouble(0,nm,OBJPROP_PRICE,1,p2);}
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_WIDTH,w);
   ObjectSetInteger(0,nm,OBJPROP_STYLE,st);ObjectSetInteger(0,nm,OBJPROP_RAY_RIGHT,ray);
   ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void DrawVLine(string nm,datetime t,color clr,ENUM_LINE_STYLE st=STYLE_DASH,int w=2)
{
   if(g_m5_mode) return;
   if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_VLINE,0,t,0);
   else ObjectSetInteger(0,nm,OBJPROP_TIME,0,t);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_STYLE,st);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,w);ObjectSetInteger(0,nm,OBJPROP_BACK,true);
   ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void DrawRect(string nm,datetime t1,double top,datetime t2,double bot,color clr)
{
   if(g_m5_mode) return;
   if(top<bot){double tmp=top;top=bot;bot=tmp;}
   if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,top,t2,bot);
   else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,top);
        ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2);ObjectSetDouble(0,nm,OBJPROP_PRICE,1,bot);}
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);ObjectSetInteger(0,nm,OBJPROP_FILL,true);
   ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void DeleteLine(string n){if(g_m5_mode)return;if(ObjectFind(0,n)>=0)ObjectDelete(0,n);}
void CutLine(string n,datetime t){if(g_m5_mode)return;if(ObjectFind(0,n)>=0){ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,n,OBJPROP_TIME,1,t);}}
void UpdateLevel(string n,double v){if(g_m5_mode)return;if(ObjectFind(0,n)>=0){ObjectSetDouble(0,n,OBJPROP_PRICE,0,v);ObjectSetDouble(0,n,OBJPROP_PRICE,1,v);}}
void DrawSwingVLines(const datetime &time[],string pfx,int s_i,int e_i,color clr)
{ DrawVLine(GetUniqueName(pfx+"VL_"),ST(time,s_i),clr);DrawVLine(GetUniqueName(pfx+"VL_"),ST(time,e_i),clr); }

void _DrawWeakRect(string nm,datetime t1,double top,double bot,color clr)
{
   if(g_m5_mode) return;
   if(top<bot){double tmp=top;top=bot;bot=tmp;}
   if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,top,D'2099.12.31 00:00',bot);
   else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,top);
        ObjectSetInteger(0,nm,OBJPROP_TIME,1,D'2099.12.31 00:00');ObjectSetDouble(0,nm,OBJPROP_PRICE,1,bot);}
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);ObjectSetInteger(0,nm,OBJPROP_FILL,false);
   ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}

// ====================================================================
// BxAdd  –  g_m5_mode=true: M5 dizisi  /  false: grafik dizisi
// ====================================================================
void BxAdd(string nm,double top,double bot,color box_clr,
           const datetime &time[],int right_i)
{
   double wk_sz=(top-bot)*InpWeakZonePct/100.0;

   if(g_m5_mode)
   {
      if(g_m5_bx_cnt>=M5_BOX_MAX) return;
      g_m5_bx_state[g_m5_bx_cnt]=2;
      g_m5_bx_top[g_m5_bx_cnt]=top;   g_m5_bx_bot[g_m5_bx_cnt]=bot;
      g_m5_bx_wk_abv[g_m5_bx_cnt]=top+wk_sz;
      g_m5_bx_wk_blw[g_m5_bx_cnt]=bot-wk_sz;
      g_m5_bx_ts[g_m5_bx_cnt]=0;    g_m5_bx_appr[g_m5_bx_cnt]=0;
      g_m5_bx_cnt_in[g_m5_bx_cnt]=0; g_m5_bx_ev_t[g_m5_bx_cnt]=0;
      g_m5_bx_wkt[g_m5_bx_cnt]=0;   g_m5_bx_wk_t[g_m5_bx_cnt]=0;
      g_m5_bx_cnt++;
      return;
   }

   if(g_bx_cnt>=BOX_MAX) return;
   color wk_clr=(box_clr==InpColorBoxBull||box_clr==InpColorBoxBullFaint)?InpColorWeakBull:InpColorWeakBear;
   g_bx_nm[g_bx_cnt]=nm; g_bx_state[g_bx_cnt]=2;
   g_bx_top[g_bx_cnt]=top; g_bx_bot[g_bx_cnt]=bot;
   g_bx_lbl[g_bx_cnt]="BoxLbl_"+IntegerToString(g_bx_cnt);
   g_bx_touch_state[g_bx_cnt]=0; g_bx_approach[g_bx_cnt]=0;
   g_bx_inside_cnt[g_bx_cnt]=0;  g_bx_event_time[g_bx_cnt]=0;
   g_bx_wk_abv_nm[g_bx_cnt]="BoxWkAbv_"+IntegerToString(g_bx_cnt);
   g_bx_wk_blw_nm[g_bx_cnt]="BoxWkBlw_"+IntegerToString(g_bx_cnt);
   g_bx_wk_abv_top[g_bx_cnt]=top+wk_sz;
   g_bx_wk_blw_bot[g_bx_cnt]=bot-wk_sz;
   g_bx_wk_touch[g_bx_cnt]=0; g_bx_wk_time[g_bx_cnt]=0;
   datetime t_left=ST(time,right_i);
   _DrawWeakRect(g_bx_wk_abv_nm[g_bx_cnt],t_left,g_bx_wk_abv_top[g_bx_cnt],top,wk_clr);
   _DrawWeakRect(g_bx_wk_blw_nm[g_bx_cnt],t_left,bot,g_bx_wk_blw_bot[g_bx_cnt],wk_clr);
   g_bx_cnt++;
}

// ====================================================================
// BxUpdateStats  –  grafik TF kutulari
// ====================================================================
void BxUpdateStats(double h,double l,double c,double prev_c,datetime bar_time)
{
   for(int k=0;k<g_bx_cnt;k++)
   {
      if(g_bx_state[k]==0) continue;
      double top=g_bx_top[k],bot=g_bx_bot[k];
      double wa=g_bx_wk_abv_top[k],wb=g_bx_wk_blw_bot[k];
      bool im=(h>=bot)&&(l<=top);
      bool ia=(h>=top)&&(l<=wa)&&!im;
      bool ib=(h>=wb)&&(l<=bot)&&!im;
      int na; if(prev_c>top)na=1; else if(prev_c<bot)na=-1; else na=g_bx_approach[k];
      int ts=g_bx_touch_state[k];
      if(ts==0){if(im){g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;}}
      else if(ts==1){if(im){g_bx_inside_cnt[k]++;g_bx_event_time[k]=bar_time;}else{bool bd=(c<bot),bu=(c>top);int ap=g_bx_approach[k];if(ap==1){if(bd)g_bx_touch_state[k]=2;else if(bu)g_bx_touch_state[k]=3;}else{if(bu)g_bx_touch_state[k]=2;else if(bd)g_bx_touch_state[k]=3;}g_bx_event_time[k]=bar_time;}}
      else{if(im){g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;}}
      if(!im){if(ia){g_bx_wk_touch[k]=1;g_bx_wk_time[k]=bar_time;}else if(ib){g_bx_wk_touch[k]=2;g_bx_wk_time[k]=bar_time;}}
   }
}

// ====================================================================
// M5BxUpdateStats  –  M5 golge kutulari
// ====================================================================
void M5BxUpdateStats(double h,double l,double c,double prev_c,datetime bar_time)
{
   for(int k=0;k<g_m5_bx_cnt;k++)
   {
      if(g_m5_bx_state[k]==0) continue;
      double top=g_m5_bx_top[k],bot=g_m5_bx_bot[k];
      double wa=g_m5_bx_wk_abv[k],wb=g_m5_bx_wk_blw[k];
      bool im=(h>=bot)&&(l<=top);
      bool ia=(h>=top)&&(l<=wa)&&!im;
      bool ib=(h>=wb)&&(l<=bot)&&!im;
      int na; if(prev_c>top)na=1; else if(prev_c<bot)na=-1; else na=g_m5_bx_appr[k];
      int ts=g_m5_bx_ts[k];
      if(ts==0){if(im){g_m5_bx_appr[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_m5_bx_ts[k]=1;g_m5_bx_cnt_in[k]=1;g_m5_bx_ev_t[k]=bar_time;}}
      else if(ts==1){if(im){g_m5_bx_cnt_in[k]++;g_m5_bx_ev_t[k]=bar_time;}else{bool bd=(c<bot),bu=(c>top);int ap=g_m5_bx_appr[k];if(ap==1){if(bd)g_m5_bx_ts[k]=2;else if(bu)g_m5_bx_ts[k]=3;}else{if(bu)g_m5_bx_ts[k]=2;else if(bd)g_m5_bx_ts[k]=3;}g_m5_bx_ev_t[k]=bar_time;}}
      else{if(im){g_m5_bx_appr[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_m5_bx_ts[k]=1;g_m5_bx_cnt_in[k]=1;g_m5_bx_ev_t[k]=bar_time;}}
      if(!im){if(ia){g_m5_bx_wkt[k]=1;g_m5_bx_wk_t[k]=bar_time;}else if(ib){g_m5_bx_wkt[k]=2;g_m5_bx_wk_t[k]=bar_time;}}
   }
}

// --------------------------------------------------------------------
string FormatTimeDiff(datetime ev,datetime cur)
{
   if(ev==0)return "?";
   int ts=(int)(cur-ev);if(ts<0)ts=0;
   int tm=ts/60,th=tm/60,td=th/24,mo=td/30;
   int mins=tm%60,hrs=th%24,days=td%30;
   int candles=(PeriodSeconds()>0)?(int)((cur-ev)/PeriodSeconds()):0;
   string t="";
   if(mo>0)t+=IntegerToString(mo)+"ay ";
   if(days>0)t+=IntegerToString(days)+"g ";
   if(hrs>0)t+=IntegerToString(hrs)+"sa ";
   t+=IntegerToString(mins)+"dk";
   return t+"  +"+IntegerToString(candles)+" mum";
}

string BxGetStatusText(int k,datetime cur)
{
   int ts=g_bx_touch_state[k],ap=g_bx_approach[k],wkt=g_bx_wk_touch[k];
   string tm=FormatTimeDiff(g_bx_event_time[k],cur),tw=FormatTimeDiff(g_bx_wk_time[k],cur);
   string mt="";
   if(ts==0)mt="(bekleniyor)";
   else if(ts==1)mt=StringFormat("%s'dan geldi | Icinde: %d mum",(ap==1?"Yukari":"Asagi"),g_bx_inside_cnt[k]);
   else if(ts==2)mt=StringFormat("%s Deldi gecti | %s",(ap==1?"v":"^"),tm);
   else if(ts==3)mt=StringFormat("%s Kacti | %s",(ap==1?"^ Yukari":"v Asagi"),tm);
   string wt="";
   if(wkt==1)wt=StringFormat("\n   Zayif Degme (Ust) | %s",tw);
   else if(wkt==2)wt=StringFormat("\n   Zayif Degme (Alt) | %s",tw);
   return mt+wt;
}

void BxDrawLabels(datetime cur)
{
   if(!InpShowStats)return;
   int sorted[BOX_MAX],cnt=0;
   for(int k=0;k<g_bx_cnt;k++)if(g_bx_state[k]>0)sorted[cnt++]=k;
   for(int a=0;a<cnt-1;a++)for(int b=a+1;b<cnt;b++){
      datetime ta=g_bx_event_time[sorted[a]],tb=g_bx_event_time[sorted[b]];
      if(g_bx_wk_time[sorted[a]]>ta)ta=g_bx_wk_time[sorted[a]];
      if(g_bx_wk_time[sorted[b]]>tb)tb=g_bx_wk_time[sorted[b]];
      if(tb>ta){int tmp=sorted[a];sorted[a]=sorted[b];sorted[b]=tmp;}}
   for(int k=0;k<g_bx_cnt;k++)if(g_bx_state[k]==0&&ObjectFind(0,g_bx_lbl[k])>=0)ObjectDelete(0,g_bx_lbl[k]);
   for(int r=0;r<cnt;r++){
      int k=sorted[r];string lbl=g_bx_lbl[k];
      double mid=(g_bx_top[k]+g_bx_bot[k])/2.0;
      string txt=StringFormat("[%d] %s",r+1,BxGetStatusText(k,cur));
      if(ObjectFind(0,lbl)<0)ObjectCreate(0,lbl,OBJ_TEXT,0,cur,mid);
      ObjectSetInteger(0,lbl,OBJPROP_TIME,0,cur);ObjectSetDouble(0,lbl,OBJPROP_PRICE,0,mid);
      ObjectSetString(0,lbl,OBJPROP_TEXT,txt);ObjectSetInteger(0,lbl,OBJPROP_COLOR,InpColorStats);
      ObjectSetInteger(0,lbl,OBJPROP_FONTSIZE,InpStatsFontSz);ObjectSetString(0,lbl,OBJPROP_FONT,"Courier New");
      ObjectSetInteger(0,lbl,OBJPROP_ANCHOR,ANCHOR_LEFT);ObjectSetInteger(0,lbl,OBJPROP_BACK,false);
      ObjectSetInteger(0,lbl,OBJPROP_HIDDEN,true);}
}

// ====================================================================
// BxAdvanceTrim
// g_m5_mode=true  →  M5 dizisi trim (grafik nesnesi yok)
// g_m5_mode=false →  grafik TF trim
// ====================================================================
void BxAdvanceTrim(datetime t)
{
   if(g_m5_mode)
   {
      for(int k=0;k<g_m5_bx_cnt;k++){
         if(g_m5_bx_state[k]==1){if(g_m5_bx_ts[k]==1)continue;g_m5_bx_state[k]=0;}
         else if(g_m5_bx_state[k]==2)g_m5_bx_state[k]=1;}
      return;
   }
   for(int k=0;k<g_bx_cnt;k++){
      if(g_bx_state[k]==1&&ObjectFind(0,g_bx_nm[k])>=0){
         if(g_bx_touch_state[k]==1)continue;
         ObjectSetInteger(0,g_bx_nm[k],OBJPROP_TIME,1,t);g_bx_state[k]=0;
         if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_lbl[k])>=0)ObjectDelete(0,g_bx_lbl[k]);}
      else if(g_bx_state[k]==2)g_bx_state[k]=1;}
}

void BxDeleteAll(){
   for(int k=0;k<g_bx_cnt;k++){
      if(ObjectFind(0,g_bx_nm[k])>=0)ObjectDelete(0,g_bx_nm[k]);
      if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectDelete(0,g_bx_wk_abv_nm[k]);
      if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectDelete(0,g_bx_wk_blw_nm[k]);
      if(ObjectFind(0,g_bx_lbl[k])>=0)ObjectDelete(0,g_bx_lbl[k]);}
   g_bx_cnt=0;}
void BxClear(){g_bx_cnt=0;}

// ====================================================================
// CStack
// ====================================================================
class CStack{
private: double m_v[];int m_i[];
public:
   CStack(){ArrayResize(m_v,0);ArrayResize(m_i,0);}
   void   Clear()            {ArrayResize(m_v,0);ArrayResize(m_i,0);}
   int    Size()             {return ArraySize(m_v);}
   void   Push(double v,int i){int s=ArraySize(m_v);ArrayResize(m_v,s+1);ArrayResize(m_i,s+1);m_v[s]=v;m_i[s]=i;}
   void   Pop()              {int s=ArraySize(m_v);if(s>0){ArrayResize(m_v,s-1);ArrayResize(m_i,s-1);}}
   double GetVal(int i)      {return m_v[i];}
   int    GetIdx(int i)      {return m_i[i];}
   void   CopyFrom(CStack &s){ArrayCopy(m_v,s.m_v);ArrayCopy(m_i,s.m_i);}
};

// ====================================================================
// SState
// ====================================================================
struct SState{
   int    min_tr,maj_tr,maj_st;
   double min_h;int min_h_i;double min_l;int min_l_i;
   double trig_h,trig_l;int lp_i;double lp_p;
   double maj_h,maj_l;int maj_h_i,maj_l_i;
   double tmp_h;int tmp_h_i;double tmp_l;int tmp_l_i;
   int    anc_i;double anc_v;int bos_i;
   string cur_top_line,cur_bot_line;
   double mb_h,mb_l;int mb_i;
   CStack st_h,st_l;
   int    bx_phase;bool bx_extreme;double bx_swing_h,bx_swing_l;
   bool   has_pot_bull_minor;int pot_bull_start_i;double pot_bull_start_p,pot_bull_end_p;
   bool   has_pot_bear_minor;int pot_bear_start_i;double pot_bear_start_p,pot_bear_end_p;
   void CopyFrom(SState &s){
      min_tr=s.min_tr;maj_tr=s.maj_tr;maj_st=s.maj_st;
      min_h=s.min_h;min_h_i=s.min_h_i;min_l=s.min_l;min_l_i=s.min_l_i;
      trig_h=s.trig_h;trig_l=s.trig_l;lp_i=s.lp_i;lp_p=s.lp_p;
      maj_h=s.maj_h;maj_l=s.maj_l;maj_h_i=s.maj_h_i;maj_l_i=s.maj_l_i;
      tmp_h=s.tmp_h;tmp_h_i=s.tmp_h_i;tmp_l=s.tmp_l;tmp_l_i=s.tmp_l_i;
      anc_i=s.anc_i;anc_v=s.anc_v;bos_i=s.bos_i;
      cur_top_line=s.cur_top_line;cur_bot_line=s.cur_bot_line;
      mb_h=s.mb_h;mb_l=s.mb_l;mb_i=s.mb_i;
      st_h.CopyFrom(s.st_h);st_l.CopyFrom(s.st_l);
      bx_phase=s.bx_phase;bx_extreme=s.bx_extreme;bx_swing_h=s.bx_swing_h;bx_swing_l=s.bx_swing_l;
      has_pot_bull_minor=s.has_pot_bull_minor;pot_bull_start_i=s.pot_bull_start_i;pot_bull_start_p=s.pot_bull_start_p;pot_bull_end_p=s.pot_bull_end_p;
      has_pot_bear_minor=s.has_pot_bear_minor;pot_bear_start_i=s.pot_bear_start_i;pot_bear_start_p=s.pot_bear_start_p;pot_bear_end_p=s.pot_bear_end_p;}
};

SState g_state_hist,g_state_curr;
SState g_m5_state_hist,g_m5_state_curr;

void BxReset(SState &s,double rl,double rh){s.bx_phase=0;s.bx_extreme=false;s.bx_swing_l=rl;s.bx_swing_h=rh;}

// ====================================================================
// DoDrawBox  –  g_m5_mode=true: DrawRect atlanir, BxAdd M5'e yazar
// ====================================================================
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
         if(fl>0){bot=fl;left_i=fi;}else bot=top-maj_sz*InpMaxBoxPct/100.0;}}
   if(top<=bot)return;
   string nm=GetUniqueName(pfx+"Box_");
   DrawRect(nm,ST(time,left_i),top,D'2099.12.31 00:00',bot,clr);
   BxAdd(nm,top,bot,clr,time,left_i);
}

// ====================================================================
// ProcessBar
// g_m5_mode=true → tum Draw* no-op, BxUpdateStats→M5, BxAdvanceTrim→M5
// draw_ui=true olarak cagrılmalı ki DoDrawBox bloklari ateslensin
// ====================================================================
void ProcessBar(int i,
                const double &open[],const double &high[],
                const double &low[], const double &close[],
                const datetime &time[],
                SState &state,bool is_history,bool draw_ui=true)
{
   int rt=ArraySize(time);
   if(rt<=0||i<0||i>=rt)return;
   double val_h=high[i],val_l=low[i],val_c=close[i];
   double prev_c=(i>0)?close[i-1]:close[i];
   string pfx=is_history?"":"Live_";

   if(g_m5_mode)M5BxUpdateStats(val_h,val_l,val_c,prev_c,time[i]);
   else if(InpShowStats)BxUpdateStats(val_h,val_l,val_c,prev_c,time[i]);

   // MINOR
   if(state.min_tr==1){
      double ot=state.trig_l;
      if(val_h>state.min_h){state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;}
      if(val_l<ot){
         int pi=state.min_h_i;double pp=state.min_h;
         int si=state.lp_i;double sp=state.lp_p;
         if(draw_ui&&InpShowMin)DrawLine(GetUniqueName(pfx+"Minor_"),ST(time,si),sp,ST(time,pi),pp,InpColorMin,1,STYLE_SOLID);
         if(state.maj_tr==-1&&!state.has_pot_bull_minor&&si>=state.tmp_l_i){state.has_pot_bull_minor=true;state.pot_bull_start_i=si;state.pot_bull_start_p=sp;state.pot_bull_end_p=pp;}
         if((g_m5_mode||(draw_ui&&InpShowBox))&&state.maj_st==0&&state.maj_tr==1){
            if(state.bx_phase==0||state.bx_phase==2){if(is_history)DoDrawBox(time,pfx,state,si,pp,sp,InpColorBoxBull);state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=pp;state.bx_swing_l=sp;}
            else{if(pp>state.bx_swing_h){state.bx_extreme=true;state.bx_swing_h=pp;}}}
         if((g_m5_mode||(draw_ui&&InpShowBox))&&state.maj_st==0&&state.maj_tr==-1&&state.bx_phase==1){
            if(state.bx_extreme&&pp>state.bx_swing_h){state.bx_phase=2;state.bx_extreme=false;}else state.bx_swing_h=pp;}
         state.st_h.Push(pp,pi);
         if(state.maj_tr==1&&state.maj_st==0&&pp<state.tmp_h&&state.st_l.Size()>0)if(state.st_l.GetIdx(state.st_l.Size()-1)>state.bos_i)state.st_l.Pop();
         state.min_tr=-1;state.lp_i=pi;state.lp_p=pp;state.min_l=val_l;state.min_l_i=i;state.trig_h=val_h;}
   }else{
      double ot=state.trig_h;
      if(val_l<state.min_l){state.min_l=val_l;state.min_l_i=i;state.trig_h=val_h;}
      if(val_h>ot){
         int ti=state.min_l_i;double tp=state.min_l;
         int si=state.lp_i;double sp=state.lp_p;
         if(draw_ui&&InpShowMin)DrawLine(GetUniqueName(pfx+"Minor_"),ST(time,si),sp,ST(time,ti),tp,InpColorMin,1,STYLE_SOLID);
         if(state.maj_tr==1&&!state.has_pot_bear_minor&&si>=state.tmp_h_i){state.has_pot_bear_minor=true;state.pot_bear_start_i=si;state.pot_bear_start_p=sp;state.pot_bear_end_p=tp;}
         if((g_m5_mode||(draw_ui&&InpShowBox))&&state.maj_st==0&&state.maj_tr==1&&state.bx_phase==1){
            if(state.bx_extreme&&tp<state.bx_swing_l){state.bx_phase=2;state.bx_extreme=false;}else state.bx_swing_l=tp;}
         if((g_m5_mode||(draw_ui&&InpShowBox))&&state.maj_st==0&&state.maj_tr==-1){
            if(state.bx_phase==0||state.bx_phase==2){if(is_history)DoDrawBox(time,pfx,state,si,sp,tp,InpColorBoxBear);state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=sp;state.bx_swing_l=tp;}
            else{if(tp<state.bx_swing_l){state.bx_extreme=true;state.bx_swing_l=tp;}}}
         state.st_l.Push(tp,ti);
         if(state.maj_tr==-1&&state.maj_st==0&&tp>state.tmp_l&&state.st_h.Size()>0)if(state.st_h.GetIdx(state.st_h.Size()-1)>state.bos_i)state.st_h.Pop();
         state.min_tr=1;state.lp_i=ti;state.lp_p=tp;state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;}}

   // MAJOR
   if(state.maj_tr==0){state.maj_tr=1;state.anc_i=state.min_l_i;state.anc_v=state.min_l;state.maj_l_i=state.min_l_i;}

   if(state.maj_tr==1){
      if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
      if(state.maj_st==0){
         double act=state.st_l.Size()>0?state.st_l.GetVal(state.st_l.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_l<act){
            state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_h_i),state.maj_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.maj_h_i,InpColorVLBull);
            BxAdvanceTrim(ST(time,state.maj_h_i));
            state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);
            if(draw_ui&&InpShowMaj){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,ST(time,state.maj_h_i),state.maj_h,time[i]+PeriodSeconds(),state.maj_h,InpColorBull,1,STYLE_DASH,true);
               if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,ST(time,state.maj_l_i),state.maj_l,time[i]+PeriodSeconds(),state.maj_l,InpColorBull,1,STYLE_DASH,true);}}}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l){
            BxAdvanceTrim(ST(time,state.tmp_h_i));state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_h_i,InpColorVLBull);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;state.maj_l=val_l;state.maj_l_i=i;
            if(state.has_pot_bear_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
            BxReset(state,val_l,state.tmp_h);CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";}
      }else if(state.maj_st==1){
         if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
         if(val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(val_c>state.maj_h){
            state.bos_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_l_i),state.maj_l,InpColorBull,2,STYLE_SOLID);
            state.st_h.Clear();state.maj_st=0;state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            BxReset(state,state.maj_l,val_h);CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l){
            BxAdvanceTrim(ST(time,state.tmp_h_i));state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_h_i,InpColorVLBull);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;state.maj_l=val_l;state.maj_l_i=i;
            if(state.has_pot_bear_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
            BxReset(state,val_l,state.tmp_h);CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";}}}
   else{ // maj_tr==-1
      if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
      if(state.maj_st==0){
         double act=state.st_h.Size()>0?state.st_h.GetVal(state.st_h.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_h>act){
            state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_l_i),state.maj_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.maj_l_i,InpColorVLBear);
            BxAdvanceTrim(ST(time,state.maj_l_i));
            state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);
            if(draw_ui&&InpShowMaj){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,ST(time,state.maj_l_i),state.maj_l,time[i]+PeriodSeconds(),state.maj_l,InpColorBear,1,STYLE_DASH,true);
               if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,ST(time,state.maj_h_i),state.maj_h,time[i]+PeriodSeconds(),state.maj_h,InpColorBear,1,STYLE_DASH,true);}}}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h){
            BxAdvanceTrim(ST(time,state.tmp_l_i));state.maj_tr=1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_l_i,InpColorVLBear);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;state.maj_h=val_h;state.maj_h_i=i;
            if(state.has_pot_bull_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
            BxReset(state,state.tmp_l,val_h);CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";}
      }else if(state.maj_st==1){
         if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
         if(val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(val_c<state.maj_l){
            state.maj_h=state.tmp_h;state.bos_i=i;state.maj_h_i=state.tmp_h_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_h_i),state.maj_h,InpColorBear,2,STYLE_SOLID);
            state.st_l.Clear();state.maj_st=0;state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            BxReset(state,val_l,state.maj_h);CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h){
            BxAdvanceTrim(ST(time,state.tmp_l_i));state.maj_tr=1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_l_i,InpColorVLBear);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;state.maj_h=val_h;state.maj_h_i=i;
            if(state.has_pot_bull_minor&&is_history)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
            BxReset(state,state.tmp_l,val_h);CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";}}}
}

// ====================================================================
// M5ProcessAll
// M5 verisini isleterek g_m5_bx dizilerini doldurur.
// Her yeni M5 mumu kapanisinda cagirilir.
// ====================================================================
void M5ProcessAll()
{
   if(Period()!=PERIOD_M1){g_m5_bx_cnt=0;return;}
   MqlRates m5_r[];
   datetime anc=TimeCurrent()-(datetime)(InpDaysM5*86400.0);
   int n=CopyRates(Symbol(),PERIOD_M5,anc,TimeCurrent(),m5_r);
   if(n<10)return;
   double m5_o[],m5_h[],m5_l[],m5_c[];datetime m5_t[];
   ArrayResize(m5_o,n);ArrayResize(m5_h,n);ArrayResize(m5_l,n);ArrayResize(m5_c,n);ArrayResize(m5_t,n);
   for(int j=0;j<n;j++){m5_o[j]=m5_r[j].open;m5_h[j]=m5_r[j].high;m5_l[j]=m5_r[j].low;m5_c[j]=m5_r[j].close;m5_t[j]=m5_r[j].time;}
   g_m5_mode=true; g_m5_bx_cnt=0;
   int si=0;
   g_m5_state_hist.min_h=m5_h[si];g_m5_state_hist.min_h_i=si;g_m5_state_hist.min_l=m5_l[si];g_m5_state_hist.min_l_i=si;
   g_m5_state_hist.trig_h=m5_h[si];g_m5_state_hist.trig_l=m5_l[si];g_m5_state_hist.tmp_h=m5_h[si];g_m5_state_hist.tmp_h_i=si;
   g_m5_state_hist.tmp_l=m5_l[si];g_m5_state_hist.tmp_l_i=si;g_m5_state_hist.min_tr=(m5_c[si]>m5_o[si])?1:-1;
   g_m5_state_hist.anc_i=si;g_m5_state_hist.anc_v=m5_c[si];g_m5_state_hist.lp_i=si;g_m5_state_hist.lp_p=m5_c[si];
   g_m5_state_hist.bos_i=si;g_m5_state_hist.maj_h_i=si;g_m5_state_hist.maj_l_i=si;
   g_m5_state_hist.mb_h=m5_h[si];g_m5_state_hist.mb_l=m5_l[si];g_m5_state_hist.mb_i=si;
   double ig=m5_h[si]-m5_l[si];if(ig==0)ig=Point()*10;
   g_m5_state_hist.maj_h=m5_h[si]+ig*0.1;g_m5_state_hist.maj_l=m5_l[si]-ig*0.1;
   g_m5_state_hist.maj_tr=g_m5_state_hist.min_tr;g_m5_state_hist.maj_st=1;
   g_m5_state_hist.cur_top_line="";g_m5_state_hist.cur_bot_line="";
   g_m5_state_hist.st_h.Clear();g_m5_state_hist.st_l.Clear();
   BxReset(g_m5_state_hist,m5_l[si],m5_h[si]);
   g_m5_state_hist.has_pot_bull_minor=false;g_m5_state_hist.has_pot_bear_minor=false;
   for(int i=si+1;i<n-1;i++){
      bool inside=(m5_h[i]<=g_m5_state_hist.mb_h)&&(m5_l[i]>=g_m5_state_hist.mb_l);
      if(!inside){if(m5_h[i]>g_m5_state_hist.mb_h||m5_l[i]<g_m5_state_hist.mb_l){g_m5_state_hist.mb_h=m5_h[i];g_m5_state_hist.mb_l=m5_l[i];g_m5_state_hist.mb_i=i;}
         ProcessBar(i,m5_o,m5_h,m5_l,m5_c,m5_t,g_m5_state_hist,true,true);}
      else M5BxUpdateStats(m5_h[i],m5_l[i],m5_c[i],(i>0)?m5_c[i-1]:m5_c[i],m5_t[i]);}
   int li=n-1;
   g_m5_state_curr.CopyFrom(g_m5_state_hist);
   bool il=(m5_h[li]<=g_m5_state_curr.mb_h)&&(m5_l[li]>=g_m5_state_curr.mb_l);
   if(!il)ProcessBar(li,m5_o,m5_h,m5_l,m5_c,m5_t,g_m5_state_curr,false,true);
   else M5BxUpdateStats(m5_h[li],m5_l[li],m5_c[li],(li>0)?m5_c[li-1]:m5_c[li],m5_t[li]);
   g_m5_mode=false;
}

// ====================================================================
// AKILLI BILDIRIM
// M1 grafikte: trend + kutular → TAMAMI M5 verisinden
// Diger TF: trend + kutular → grafik TF verisinden
// ====================================================================
void CheckSmartMTFNotification()
{
   static datetime last_t=0;static string last_msg="";
   if(TimeCurrent()-last_t<InpNotifInterval)return;

   // M1, M5, M15, M30, H1, H4, D1 trend analizi
   ENUM_TIMEFRAMES tfs[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   int num_tfs = ArraySize(tfs);

   string msg = "SMACv2 Analiz Raporu:\n";
   bool trend_added = false;

   for(int i=0; i<num_tfs; i++) {
       ENUM_TIMEFRAMES tf = tfs[i];
       MqlRates r[];
       if(CopyRates(Symbol(), tf, 0, 15, r) < 10) continue;
       ArraySetAsSeries(r, true);
       int trend = (r[0].close > r[9].close) ? 1 : -1;
       string trend_str = (trend == 1) ? "YUKARI" : "ASAGI";
       string tf_lbl = EnumToString(tf);
       StringReplace(tf_lbl, "PERIOD_", "");
       msg += tf_lbl + " Trend: " + trend_str + "\n";
       trend_added = true;
   }

   if(!trend_added) return;

   bool use_m5=(Period()==PERIOD_M1);
   int  bx_cnt=use_m5?g_m5_bx_cnt:g_bx_cnt;
   if(bx_cnt>0){
       // --- En son etkilesimli kutuyu bul ---
       int best_k=-1;datetime best_t=0;
       for(int k=0;k<bx_cnt;k++){
          int st=use_m5?g_m5_bx_state[k]:g_bx_state[k];
          if(st==0)continue;
          datetime ev=use_m5?g_m5_bx_ev_t[k]:g_bx_event_time[k];
          datetime wt=use_m5?g_m5_bx_wk_t[k]:g_bx_wk_time[k];
          datetime t=(wt>ev)?wt:ev;
          if(t>best_t){best_t=t;best_k=k;}}

       if(best_k>=0){
           // --- Kutu degerlerini oku ---
           double bx_top,bx_bot,wk_abv,wk_blw;
           int    ts,appr,cnt_in,wkt;
           datetime t_main,t_wk;
           if(use_m5){
              bx_top=g_m5_bx_top[best_k];bx_bot=g_m5_bx_bot[best_k];
              wk_abv=g_m5_bx_wk_abv[best_k];wk_blw=g_m5_bx_wk_blw[best_k];
              ts=g_m5_bx_ts[best_k];appr=g_m5_bx_appr[best_k];
              cnt_in=g_m5_bx_cnt_in[best_k];wkt=g_m5_bx_wkt[best_k];
              t_main=g_m5_bx_ev_t[best_k];t_wk=g_m5_bx_wk_t[best_k];
           }else{
              bx_top=g_bx_top[best_k];bx_bot=g_bx_bot[best_k];
              wk_abv=g_bx_wk_abv_top[best_k];wk_blw=g_bx_wk_blw_bot[best_k];
              ts=g_bx_touch_state[best_k];appr=g_bx_approach[best_k];
              cnt_in=g_bx_inside_cnt[best_k];wkt=g_bx_wk_touch[best_k];
              t_main=g_bx_event_time[best_k];t_wk=g_bx_wk_time[best_k];}

           ENUM_TIMEFRAMES tf_trend=use_m5?PERIOD_M5:(ENUM_TIMEFRAMES)Period();
           MqlRates rr[];
           int trend_box = 1;
           if(CopyRates(Symbol(),tf_trend,0,15,rr)>=10){
               ArraySetAsSeries(rr,true);
               trend_box=(rr[0].close>rr[9].close)?1:-1;
           }

           bool wk_newer=(wkt>0)&&(t_wk>t_main);
           string giris=(appr==1)?"Yukaridan geldi":"Asagidan geldi";

           msg+="\n─────────────\n";
           msg+=use_m5?"M5 Kutu Etkilesimi:\n":"Kutu Etkilesimi:\n";
           msg+=StringFormat("Kutu: %.5f - %.5f\n",bx_top,bx_bot);
           if(wk_newer){
              string wy=(wkt==1)?"UST":"ALT";
              string wb=(wkt==1)?StringFormat("%.5f-%.5f",bx_top,wk_abv):StringFormat("%.5f-%.5f",wk_blw,bx_bot);
              string onc="";
              if(ts==2)onc="Onceki: "+(appr==1?"asagiya":"yukariya")+" delinmisti\n";
              else if(ts==3)onc="Onceki: tepki → "+(appr==1?"yukari":"asagi")+" kacti\n";
              msg+=onc+"Durum: GERI DONDU → "+wy+" ZAYIF BOLGE\n";
              msg+="Bant: "+wb+"\n";
              msg+="Sure: "+FormatTimeDiff(t_wk,TimeCurrent())+"\n";
              bool br=(wkt==2&&appr==1),bb=(wkt==1&&appr==-1);
              bool tu=(trend_box==1&&br)||(trend_box==-1&&bb);
              if(br||bb)msg+=tu?"Beklenti: GUVENLI RETEST!":"Beklenti: RISKLI RETEST.";
              else msg+="Beklenti: Yon teyidi bekleniyor.";
           }else if(ts==0){
              if(wkt==1){msg+="Durum: UST ZAYIF BOLGEYE degdi (ana kutu yok)\n";msg+=StringFormat("%.5f-%.5f",bx_top,wk_abv);}
              else if(wkt==2){msg+="Durum: ALT ZAYIF BOLGEYE degdi (ana kutu yok)\n";msg+=StringFormat("%.5f-%.5f",wk_blw,bx_bot);}
              else msg+="Durum: Kutuya henuz dokunulmadi.";
           }else if(ts==1){
              msg+="Durum: TAM ICINDE\n\nGiris: "+giris+"\n";
              msg+=IntegerToString(cnt_in)+" mum iceride\n";
              bool tu=(trend_box==1&&appr==1)||(trend_box==-1&&appr==-1);
              msg+=tu?"Beklenti: Trend uyumlu tepki gelebilir.":"Beklenti: Trende karsi giris, dikkat.";
           }else if(ts==2){
              string dy=(appr==1)?"ASAGIYA":"YUKARIYA";
              msg+="Durum: "+dy+" DELDI GECTI\n\nGiris: "+giris+"\n";
              msg+="Ne zaman: "+FormatTimeDiff(t_main,TimeCurrent())+"\n";
              bool tu=(trend_box==1&&appr==-1)||(trend_box==-1&&appr==1);
              msg+=tu?"Beklenti: TREND DEVAM.":"Beklenti: Trende karsi delinme, dikkat.";
           }else if(ts==3){
              string ky=(appr==1)?"YUKARI":"ASAGI";
              msg+="Durum: TEPKI ALDI → "+ky+"\n\nGiris: "+giris+"\n";
              msg+="Ne zaman: "+FormatTimeDiff(t_main,TimeCurrent())+"\n";
              bool tu=(trend_box==1&&appr==1)||(trend_box==-1&&appr==-1);
              msg+=tu?"Beklenti: GUVENLI - Trend + tepki!":"Beklenti: RISKLI - Trende karsi tepki.";}
       }
   }

   if(msg!=last_msg){SendNotification(msg);last_msg=msg;last_t=TimeCurrent();}
}

// ====================================================================
// OnCalculate
// ====================================================================
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   if(rates_total<2)return 0;
   static datetime last_bar_time=0;static int last_rates_tot=0;
   static datetime last_m5_bar=0;
   int vp=prev_calculated;
   if(prev_calculated==0&&last_bar_time==time[rates_total-1])vp=rates_total-1;
   if(last_rates_tot>0&&rates_total<last_rates_tot)vp=0;

   if(vp>0&&vp<rates_total-1){
      for(int i=vp;i<rates_total-1;i++){
         bool inside=(high[i]<=g_state_hist.mb_h)&&(low[i]>=g_state_hist.mb_l);
         if(!inside){if(high[i]>g_state_hist.mb_h||low[i]<g_state_hist.mb_l){g_state_hist.mb_h=high[i];g_state_hist.mb_l=low[i];g_state_hist.mb_i=i;}
            ProcessBar(i,open,high,low,close,time,g_state_hist,true,true);}
         else if(InpShowStats){double pc=(i>0)?close[i-1]:close[i];BxUpdateStats(high[i],low[i],close[i],pc,time[i]);}}}

   if(vp==0){
      last_bar_time=time[rates_total-1];
      g_anchor_time=TimeCurrent()-(datetime)(GetActiveDays()*86400.0);
      g_counter=0;
      ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
      ObjectsDeleteAll(0,"VL_");ObjectsDeleteAll(0,"Box_");ObjectsDeleteAll(0,"Live_");
      ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");ObjectsDeleteAll(0,"BoxLbl_");
      BxClear();
      int si=0;for(int k=0;k<rates_total;k++)if(time[k]>=g_anchor_time){si=k;break;}
      g_state_hist.min_h=high[si];g_state_hist.min_h_i=si;g_state_hist.min_l=low[si];g_state_hist.min_l_i=si;
      g_state_hist.trig_h=high[si];g_state_hist.trig_l=low[si];g_state_hist.tmp_h=high[si];g_state_hist.tmp_h_i=si;
      g_state_hist.tmp_l=low[si];g_state_hist.tmp_l_i=si;g_state_hist.min_tr=(close[si]>open[si])?1:-1;
      g_state_hist.anc_i=si;g_state_hist.anc_v=close[si];g_state_hist.lp_i=si;g_state_hist.lp_p=close[si];
      g_state_hist.bos_i=si;g_state_hist.maj_h_i=si;g_state_hist.maj_l_i=si;
      g_state_hist.mb_h=high[si];g_state_hist.mb_l=low[si];g_state_hist.mb_i=si;
      double ig=high[si]-low[si];if(ig==0)ig=Point()*10;
      g_state_hist.maj_h=high[si]+ig*0.1;g_state_hist.maj_l=low[si]-ig*0.1;
      g_state_hist.maj_tr=g_state_hist.min_tr;g_state_hist.maj_st=1;
      g_state_hist.cur_top_line="";g_state_hist.cur_bot_line="";
      g_state_hist.st_h.Clear();g_state_hist.st_l.Clear();
      BxReset(g_state_hist,low[si],high[si]);
      g_state_hist.has_pot_bull_minor=false;g_state_hist.has_pot_bear_minor=false;
      for(int i=si+1;i<rates_total-1;i++){
         bool inside=(high[i]<=g_state_hist.mb_h)&&(low[i]>=g_state_hist.mb_l);
         if(!inside){if(high[i]>g_state_hist.mb_h||low[i]<g_state_hist.mb_l){g_state_hist.mb_h=high[i];g_state_hist.mb_l=low[i];g_state_hist.mb_i=i;}
            ProcessBar(i,open,high,low,close,time,g_state_hist,true,true);}
         else if(InpShowStats){double pc=(i>0)?close[i-1]:close[i];BxUpdateStats(high[i],low[i],close[i],pc,time[i]);}}
      last_m5_bar=0;}

   ObjectsDeleteAll(0,"Live_");DeleteLine("LiveLeg");
   int li=rates_total-1;
   g_state_curr.CopyFrom(g_state_hist);
   if(li>0){
      bool il=(high[li]<=g_state_curr.mb_h)&&(low[li]>=g_state_curr.mb_l);
      if(!il)ProcessBar(li,open,high,low,close,time,g_state_curr,false,true);
      else if(InpShowStats){double pc=(li>0)?close[li-1]:close[li];BxUpdateStats(high[li],low[li],close[li],pc,time[li]);}}

   if(InpShowMin&&li>0){
      int lgi;double lgp;
      if(g_state_curr.min_tr==1){lgi=g_state_curr.min_h_i;lgp=g_state_curr.min_h;}
      else{lgi=g_state_curr.min_l_i;lgp=g_state_curr.min_l;}
      DrawLine("LiveLeg",ST(time,g_state_curr.lp_i),g_state_curr.lp_p,ST(time,lgi),lgp,InpColorMin,1,STYLE_DOT);}

   if(InpShowStats&&li>0)BxDrawLabels(time[li]+(datetime)(PeriodSeconds()*2));

   // M5 golge: yeni M5 mumu kapandikca yenile
   if(Period()==PERIOD_M1){
      datetime cm5[1];
      if(CopyTime(Symbol(),PERIOD_M5,0,1,cm5)==1&&cm5[0]!=last_m5_bar){
         M5ProcessAll();last_m5_bar=cm5[0];}}

   if(InpSmartNotif)CheckSmartMTFNotification();

   last_rates_tot=rates_total;
   return(rates_total);
}

int OnInit(){IndicatorSetString(INDICATOR_SHORTNAME,"SMACv2_v30.02");return INIT_SUCCEEDED;}
void OnDeinit(const int reason){
   ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
   ObjectsDeleteAll(0,"VL_");ObjectsDeleteAll(0,"Box_");ObjectsDeleteAll(0,"Live_");
   ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");ObjectsDeleteAll(0,"BoxLbl_");
   BxClear();Comment("");}
