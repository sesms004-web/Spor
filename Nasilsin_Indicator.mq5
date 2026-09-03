//+------------------------------------------------------------------+
//|                                                    Structure.mq5 |
//|   Minor + Major + CHoCH + Kutu + MTF + M1 Filtre + Kilit        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "3.00"
#property indicator_chart_window
#property indicator_plots 0

//--- Lookback
input double InpDaysM1  = 1.0;
input double InpDaysM5  = 5.0;
input double InpDaysM15 = 15.0;
input double InpDaysM30 = 30.0;
input double InpDaysH1  = 60.0;
input double InpDaysH4  = 240.0;
input double InpDaysD1  = 1440.0;

//--- CHoCH
input double InpMinPullbackPct   = 40.0;
input double InpMaxPullbackPct   = 100.0;
input color  InpColorChochStrong = clrPurple;
input color  InpColorChochWeak   = clrRed;
input color  InpColorChochPath   = clrGray;
input bool   InpShowChoch        = true;

//--- Yapı
input bool   InpShowMin   = true;
input bool   InpShowMaj   = true;
input color  InpColorMin  = clrRed;
input color  InpColorBull = clrGreen;
input color  InpColorBear = clrRed;

//--- Kutu
input bool   InpShowBox           = true;
input double InpMaxBoxPct         = 20.0;
input double InpWeakZonePct       = 50.0;
input color  InpColorBoxBull      = clrDodgerBlue;
input color  InpColorBoxBear      = clrRed;
input color  InpColorBoxBullFaint = C'0,40,90';
input color  InpColorBoxBearFaint = C'90,20,0';
input color  InpColorWeakBull     = C'0,25,55';
input color  InpColorWeakBear     = C'55,15,0';

input bool InpAlertPush = false;

//=====================================================================
// GLOBALS
//=====================================================================
#define BOX_MAX 512

int      g_counter     = 0;
datetime g_anchor_time = 0;


//--- Ana kutu
string   g_bx_nm[BOX_MAX];       string   g_bx_wk_abv_nm[BOX_MAX]; string   g_bx_wk_blw_nm[BOX_MAX];
int      g_bx_state[BOX_MAX];    double   g_bx_top[BOX_MAX];        double   g_bx_bot[BOX_MAX];
int      g_bx_touch_state[BOX_MAX]; int   g_bx_approach[BOX_MAX];  int      g_bx_inside_cnt[BOX_MAX];
datetime g_bx_event_time[BOX_MAX];  int   g_bx_break_up[BOX_MAX];  int      g_bx_break_dn[BOX_MAX];
bool     g_bx_is_ext[BOX_MAX];
bool     g_bx_notified[BOX_MAX];
int      g_bx_cnt=0;
datetime g_last_yellow_time = 0;
datetime g_last_red_time = 0;

//=====================================================================
// YARDIMCI
//=====================================================================
datetime GetTimeSafe(const datetime &t[],int idx)
{int s=ArraySize(t);if(s<=0)return 0;if(idx<0)return t[0];if(idx>=s)return t[s-1];return t[idx];}

string GetUniqueName(string p){g_counter++;return p+IntegerToString(g_counter);}

double GetDaysForTF(ENUM_TIMEFRAMES tf)
{
   if(tf==PERIOD_M15)return InpDaysM15; if(tf==PERIOD_M30)return InpDaysM30;
   if(tf==PERIOD_H1) return InpDaysH1;  if(tf==PERIOD_H4) return InpDaysH4;
   if(tf==PERIOD_D1) return InpDaysD1;  if(tf==PERIOD_M1) return InpDaysM1;  if(tf==PERIOD_M5) return InpDaysM5;
   return 15.0;
}

//=====================================================================
// ÇİZİM
//=====================================================================
void DrawLine(string nm,datetime t1,double p1,datetime t2,double p2,color clr,int w,ENUM_LINE_STYLE st,bool ray=false)
{
      if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_TREND,0,t1,p1,t2,p2);
   else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p1);
        ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2);ObjectSetDouble(0,nm,OBJPROP_PRICE,1,p2);}
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_WIDTH,w);
   ObjectSetInteger(0,nm,OBJPROP_STYLE,st);ObjectSetInteger(0,nm,OBJPROP_RAY_RIGHT,ray);
   ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void DrawDot(string nm,datetime t,double p,color clr)
{
      if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_ARROW,0,t,p);
   else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p);}
   ObjectSetInteger(0,nm,OBJPROP_ARROWCODE,159);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,nm,OBJPROP_BACK,false);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
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
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);ObjectSetInteger(0,nm,OBJPROP_FILL,true);
   ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void DrawWeakRect(string nm,datetime t1,double top,double bot,color clr)
{
      if(top<bot){double tmp=top;top=bot;bot=tmp;}
   if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,top,D'2099.12.31 00:00',bot);
   else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,top);
        ObjectSetInteger(0,nm,OBJPROP_TIME,1,D'2099.12.31 00:00');ObjectSetDouble(0,nm,OBJPROP_PRICE,1,bot);}
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);ObjectSetInteger(0,nm,OBJPROP_FILL,false);
   ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}

//=====================================================================
// KUTU YÖNETİMİ
//=====================================================================
void BxClear(){g_bx_cnt=0;}

void BxDeleteAll()
{
   for(int k=0;k<g_bx_cnt;k++){
      if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectDelete(0,g_bx_nm[k]);
      if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectDelete(0,g_bx_wk_abv_nm[k]);
      if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectDelete(0,g_bx_wk_blw_nm[k]);
   }
   g_bx_cnt=0;
}

void BxAdd(string nm,string wk_abv,string wk_blw,double top,double bot,bool is_ext=false)
{

   if(g_bx_cnt>=BOX_MAX)return;
   g_bx_nm[g_bx_cnt]=nm;g_bx_wk_abv_nm[g_bx_cnt]=wk_abv;g_bx_wk_blw_nm[g_bx_cnt]=wk_blw;
   g_bx_top[g_bx_cnt]=top;g_bx_bot[g_bx_cnt]=bot;
   g_bx_state[g_bx_cnt]=2;g_bx_touch_state[g_bx_cnt]=0;g_bx_approach[g_bx_cnt]=0;
   g_bx_inside_cnt[g_bx_cnt]=0;g_bx_event_time[g_bx_cnt]=0;
   g_bx_break_up[g_bx_cnt]=0;g_bx_break_dn[g_bx_cnt]=0;
   g_bx_is_ext[g_bx_cnt]=is_ext;
   g_bx_notified[g_bx_cnt]=false;
   g_bx_cnt++;
}

void BxAdvanceTrim(datetime t)
{

   for(int k=0;k<g_bx_cnt;k++){
      if(g_bx_state[k]==1){
         if(g_bx_touch_state[k]==1)continue;
         if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectSetInteger(0,g_bx_nm[k],       OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,t);
         g_bx_state[k]=0;
      }
      else if(g_bx_state[k]==2)g_bx_state[k]=1;
   }
}

void BxUpdateStats(double h,double l,double c,double prev_c,datetime bar_time,bool is_history=false)
{

   for(int k=0;k<g_bx_cnt;k++){
      if(g_bx_state[k]==0)continue;
      double top=g_bx_top[k],bot=g_bx_bot[k];
      bool im=(h>=bot)&&(l<=top);
      int na;if(prev_c>top)na=1;else if(prev_c<bot)na=-1;else na=g_bx_approach[k];
      int ts=g_bx_touch_state[k];
      if(ts==0){if(im){g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;}}
      else if(ts==1){
         bool bd=(c<bot),bu=(c>top);
         if(bd||bu){
            int ap=g_bx_approach[k];
            if(ap==1){
               if(bd){
                  if(!g_bx_notified[k] && g_bx_is_ext[k]){
                     DrawDot(g_bx_nm[k]+"_Dot",bar_time,bot,clrBlue);
                     if(!is_history && InpAlertPush) SendNotification("🔵 Mavi Top: Kutu İhlali (Aşağı Kırılım)");
                     g_bx_notified[k]=true;
                  }
                  g_bx_touch_state[k]=2;g_bx_break_dn[k]++;
               }else if(bu){
                  g_bx_touch_state[k]=3;
               }
            }
            else{
               if(bu){
                  if(!g_bx_notified[k] && g_bx_is_ext[k]){
                     DrawDot(g_bx_nm[k]+"_Dot",bar_time,top,clrBlue);
                     if(!is_history && InpAlertPush) SendNotification("🔵 Mavi Top: Kutu İhlali (Yukarı Kırılım)");
                     g_bx_notified[k]=true;
                  }
                  g_bx_touch_state[k]=2;g_bx_break_up[k]++;
               }else if(bd){
                  g_bx_touch_state[k]=3;
               }
            }
            g_bx_event_time[k]=bar_time;
         }else if(im){g_bx_inside_cnt[k]++;g_bx_event_time[k]=bar_time;}
      }
      else{if(im){g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;}}
   }
}

//=====================================================================
// CStack
//=====================================================================
class CStack{
private:double m_v[];int m_i[];
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

//=====================================================================
// SState
//=====================================================================
struct SState{
   int    min_tr,maj_tr,maj_st;
   double min_h;int min_h_i;double min_l;int min_l_i;
   double trig_h,trig_l;int lp_i;double lp_p;
   double maj_h;int maj_h_i;double maj_l;int maj_l_i;
   double tmp_h;int tmp_h_i;double tmp_l;int tmp_l_i;
   int    anc_i;double anc_v;int bos_i;int bos_count;
   string cur_top_line,cur_bot_line;
   double mb_h,mb_l;int mb_i;
   double t1_h,t1_l;int t1_i;
   double d1_h,d1_l;int d1_i;
   double t2_h,t2_l;int t2_i;
   int    choch_dir; bool swept_choch;
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
      anc_i=s.anc_i;anc_v=s.anc_v;bos_i=s.bos_i;bos_count=s.bos_count;
      cur_top_line=s.cur_top_line;cur_bot_line=s.cur_bot_line;
      mb_h=s.mb_h;mb_l=s.mb_l;mb_i=s.mb_i;
      t1_h=s.t1_h;t1_l=s.t1_l;t1_i=s.t1_i;
      d1_h=s.d1_h;d1_l=s.d1_l;d1_i=s.d1_i;
      t2_h=s.t2_h;t2_l=s.t2_l;t2_i=s.t2_i;
      choch_dir=s.choch_dir; swept_choch=s.swept_choch;
      bx_phase=s.bx_phase;bx_extreme=s.bx_extreme;bx_swing_h=s.bx_swing_h;bx_swing_l=s.bx_swing_l;
      has_pot_bull_minor=s.has_pot_bull_minor;pot_bull_start_i=s.pot_bull_start_i;
      pot_bull_start_p=s.pot_bull_start_p;pot_bull_end_p=s.pot_bull_end_p;
      has_pot_bear_minor=s.has_pot_bear_minor;pot_bear_start_i=s.pot_bear_start_i;
      pot_bear_start_p=s.pot_bear_start_p;pot_bear_end_p=s.pot_bear_end_p;
      st_h.CopyFrom(s.st_h);st_l.CopyFrom(s.st_l);}
};

SState g_state_hist,g_state_curr;
void BxReset(SState &s,double rl,double rh){s.bx_phase=0;s.bx_extreme=false;s.bx_swing_l=rl;s.bx_swing_h=rh;}

// CHoCH state'ini tamamen sıfırla (BOS noktalarında çağrılır)
void ResetChochState(SState &s){
   s.choch_dir=0; s.swept_choch=false;
   s.t1_h=0;s.t1_l=0;s.t1_i=0;
   s.d1_h=0;s.d1_l=0;s.d1_i=0;
   s.t2_h=0;s.t2_l=0;s.t2_i=0;
}

//=====================================================================
// DoDrawBox
//=====================================================================
void DoDrawBox(const datetime &time[],string pfx,SState &s,int left_i,double top,double bot,color clr)
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
   double wk_sz=(top-bot)*InpWeakZonePct/100.0;
   color  wk_clr=(clr==InpColorBoxBull||clr==InpColorBoxBullFaint)?InpColorWeakBull:InpColorWeakBear;
   string nm=GetUniqueName(pfx+"Box_");
   string wk_abv=GetUniqueName(pfx+"BoxWkAbv_");
   string wk_blw=GetUniqueName(pfx+"BoxWkBlw_");
   datetime t_left=GetTimeSafe(time,left_i);
   DrawRect(nm,t_left,top,D'2099.12.31 00:00',bot,clr);
   DrawWeakRect(wk_abv,t_left,top+wk_sz,top,wk_clr);
   DrawWeakRect(wk_blw,t_left,bot,bot-wk_sz,wk_clr);
   bool is_ext = (clr == InpColorBoxBullFaint || clr == InpColorBoxBearFaint);
   BxAdd(nm,wk_abv,wk_blw,top,bot,is_ext);
}

//=====================================================================
// ProcessBar
//=====================================================================
void ProcessBar(int i,const double &open[],const double &high[],const double &low[],
                const double &close[],const datetime &time[],SState &state,bool is_history)
{
   double val_h=high[i],val_l=low[i],val_c=close[i];
   string pfx=is_history?"":"Live_";
   double prev_c=(i>0)?close[i-1]:close[i];
   BxUpdateStats(val_h,val_l,val_c,prev_c,time[i],is_history);

   double ch_h=state.maj_h; double ch_l=state.maj_l;
   if(state.maj_st==0){
      if(state.maj_tr== 1&&state.tmp_h!=EMPTY_VALUE&&state.tmp_h!=0)ch_h=state.tmp_h;
      if(state.maj_tr==-1&&state.tmp_l!=EMPTY_VALUE&&state.tmp_l!=0)ch_l=state.tmp_l;
   }
   double p_pct=0;
   if(ch_h!=EMPTY_VALUE&&ch_l!=EMPTY_VALUE&&ch_h!=ch_l&&ch_h!=0&&ch_l!=0){
      double rng=ch_h-ch_l;
      if(rng>0){
         if(state.maj_tr== 1&&val_l>=ch_l)p_pct=((ch_h-val_l)/rng)*100.0;
         if(state.maj_tr==-1&&val_h<=ch_h)p_pct=((val_h-ch_l)/rng)*100.0;
      }
   }
   bool in_pb=(p_pct>=InpMinPullbackPct&&p_pct<=InpMaxPullbackPct);

   //--- MİNÖR
   if(state.min_tr==1){
      double ot=state.trig_l;
      if(val_h>state.min_h){state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;}
      if(val_l<ot){
         int pi=state.min_h_i;double pp=state.min_h;int si=state.lp_i;double sp=state.lp_p;
         if(InpShowMin)DrawLine(GetUniqueName(pfx+"Minor_"),GetTimeSafe(time,si),sp,GetTimeSafe(time,pi),pp,InpColorMin,1,STYLE_SOLID);
         if(state.maj_tr==-1&&!state.has_pot_bull_minor&&si>=state.tmp_l_i)
         {state.has_pot_bull_minor=true;state.pot_bull_start_i=si;state.pot_bull_start_p=sp;state.pot_bull_end_p=pp;}
         if(is_history&&InpShowBox&&state.maj_st==0&&state.maj_tr==1){
            if(state.bx_phase==0||state.bx_phase==2){DoDrawBox(time,pfx,state,si,pp,sp,InpColorBoxBull);state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=pp;state.bx_swing_l=sp;}
            else if(pp>state.bx_swing_h){state.bx_extreme=true;state.bx_swing_h=pp;}
         }
         if(state.maj_st==0&&state.maj_tr==-1&&state.bx_phase==1){
            if(state.bx_extreme&&pp>state.bx_swing_h){state.bx_phase=2;state.bx_extreme=false;}else state.bx_swing_h=pp;}
         state.st_h.Push(pp,pi);
         if(state.maj_tr==1&&state.maj_st==0&&pp<state.tmp_h&&state.st_l.Size()>0)
            if(state.st_l.GetIdx(state.st_l.Size()-1)>state.bos_i)state.st_l.Pop();
         if(state.choch_dir==-1&&state.t2_h!=0)state.choch_dir=0;
         if(state.choch_dir== 1&&state.t2_l!=0&&state.min_h<=state.d1_h)state.choch_dir=0;
         if(state.choch_dir!=0&&!in_pb)state.choch_dir=0;
         if(state.maj_tr==-1&&in_pb){
            if(state.choch_dir==0||state.choch_dir==1)
            {state.t1_h=state.min_h;state.t1_l=state.min_l;state.t1_i=state.min_h_i;state.d1_h=0;state.d1_l=0;state.d1_i=0;state.t2_h=0;state.t2_l=0;state.t2_i=0;state.choch_dir=-1;}
            else if(state.choch_dir==-1){
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
         int ti=state.min_l_i;double tp=state.min_l;int si=state.lp_i;double sp=state.lp_p;
         if(InpShowMin)DrawLine(GetUniqueName(pfx+"Minor_"),GetTimeSafe(time,si),sp,GetTimeSafe(time,ti),tp,InpColorMin,1,STYLE_SOLID);
         if(state.maj_tr==1&&!state.has_pot_bear_minor&&si>=state.tmp_h_i)
         {state.has_pot_bear_minor=true;state.pot_bear_start_i=si;state.pot_bear_start_p=sp;state.pot_bear_end_p=tp;}
         if(is_history&&InpShowBox&&state.maj_st==0&&state.maj_tr==-1){
            if(state.bx_phase==0||state.bx_phase==2){DoDrawBox(time,pfx,state,si,sp,tp,InpColorBoxBear);state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=sp;state.bx_swing_l=tp;}
            else if(tp<state.bx_swing_l){state.bx_extreme=true;state.bx_swing_l=tp;}
         }
         if(state.maj_st==0&&state.maj_tr==1&&state.bx_phase==1){
            if(state.bx_extreme&&tp<state.bx_swing_l){state.bx_phase=2;state.bx_extreme=false;}else state.bx_swing_l=tp;}
         state.st_l.Push(tp,ti);
         if(state.maj_tr==-1&&state.maj_st==0&&tp>state.tmp_l&&state.st_h.Size()>0)
            if(state.st_h.GetIdx(state.st_h.Size()-1)>state.bos_i)state.st_h.Pop();
         if(state.choch_dir== 1&&state.t2_l!=0)state.choch_dir=0;
         if(state.choch_dir==-1&&state.t2_h!=0&&state.min_l>=state.d1_l)state.choch_dir=0;
         if(state.choch_dir!=0&&!in_pb)state.choch_dir=0;
         if(state.maj_tr==1&&in_pb){
            if(state.choch_dir==0||state.choch_dir==-1)
            {state.t1_l=state.min_l;state.t1_h=state.min_h;state.t1_i=state.min_l_i;state.d1_l=0;state.d1_h=0;state.d1_i=0;state.t2_l=0;state.t2_h=0;state.t2_i=0;state.choch_dir=1;}
            else if(state.choch_dir==1){
               if(state.d1_h==0){state.d1_h=state.min_h;state.d1_i=state.min_h_i;}
               if(state.d1_h!=0&&state.t2_l==0){state.t2_l=state.min_l;state.t2_i=state.min_l_i;}
            }
         }
         state.min_tr=1;state.lp_i=ti;state.lp_p=tp;state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;
      }
   }

   //--- CHoCH TETİK — SELL
   if(state.choch_dir==-1&&state.t2_h!=0&&state.d1_l!=0){
      if(val_c<state.d1_l&&in_pb){
         bool is_strong=(state.t2_h>state.t1_h);
         if(InpShowChoch){
            color sc=is_strong?InpColorChochStrong:InpColorChochWeak;
            DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t1_i),state.t1_h,GetTimeSafe(time,state.d1_i),state.d1_l,InpColorChochPath,1,STYLE_DOT);
            DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.d1_i),state.d1_l,GetTimeSafe(time,state.t2_i),state.t2_h,InpColorChochPath,1,STYLE_DOT);
            DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t2_i),state.t2_h,GetTimeSafe(time,i),state.d1_l,InpColorChochPath,1,STYLE_DOT);
            DrawLine(GetUniqueName(pfx+"CHoCH_Signal_"),GetTimeSafe(time,i),state.d1_l,GetTimeSafe(time,i)+PeriodSeconds()*5,state.d1_l,sc,3,STYLE_SOLID);
         }


         state.choch_dir=0;
      }
   }
   //--- CHoCH TETİK — BUY
   else if(state.choch_dir==1&&state.t2_l!=0&&state.d1_h!=0){
      if(val_c>state.d1_h&&in_pb){
         bool is_strong=(state.t2_l<state.t1_l);
         if(InpShowChoch){
            color sc=is_strong?InpColorChochStrong:InpColorChochWeak;
            DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t1_i),state.t1_l,GetTimeSafe(time,state.d1_i),state.d1_h,InpColorChochPath,1,STYLE_DOT);
            DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.d1_i),state.d1_h,GetTimeSafe(time,state.t2_i),state.t2_l,InpColorChochPath,1,STYLE_DOT);
            DrawLine(GetUniqueName(pfx+"CHoCH_Path_"),GetTimeSafe(time,state.t2_i),state.t2_l,GetTimeSafe(time,i),state.d1_h,InpColorChochPath,1,STYLE_DOT);
            DrawLine(GetUniqueName(pfx+"CHoCH_Signal_"),GetTimeSafe(time,i),state.d1_h,GetTimeSafe(time,i)+PeriodSeconds()*5,state.d1_h,sc,3,STYLE_SOLID);
         }

         state.choch_dir=0;
      }
   }

   //--- MAJÖR YAPI
   if(state.maj_tr==0){state.maj_tr=1;state.anc_i=state.min_l_i;state.anc_v=state.min_l;state.maj_l_i=state.min_l_i;}

   if(state.maj_tr==1){
      if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
      if(state.maj_st==0){
         double act=state.st_l.Size()>0?state.st_l.GetVal(state.st_l.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_l<act){
            state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_h_i),state.maj_h,InpColorBull,2,STYLE_SOLID);
            BxAdvanceTrim(GetTimeSafe(time,state.maj_h_i));
            state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));
            if(InpShowMaj){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,GetTimeSafe(time,state.maj_h_i),state.maj_h,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_h,InpColorBull,1,STYLE_DASH,true);
               if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,GetTimeSafe(time,state.maj_l_i),state.maj_l,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_l,InpColorBull,1,STYLE_DASH,true);}}
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;state.maj_l_i=i;state.swept_choch=true;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         // BOS: Boğa → Ayı (maj_st==0)
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l){
            ResetChochState(state); // CHoCH setup eski swing'e ait, sıfırla
            BxAdvanceTrim(GetTimeSafe(time,state.tmp_h_i));

            if(state.bos_count==0){
               if(!is_history && InpAlertPush && g_last_yellow_time != time[i]) { SendNotification("🟡 Sarı Top: Ani Trend Dönüşü (Boğa -> Ayı)"); g_last_yellow_time = time[i]; }
               DrawDot(GetUniqueName(pfx+"YellowDot_"),GetTimeSafe(time,i),val_l,clrYellow);
            }

            state.maj_tr=-1;state.maj_st=0;state.bos_i=i;state.bos_count=0;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            BxReset(state,val_l,state.tmp_h);state.has_pot_bear_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }else if(state.maj_st==1){
         if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
         if(state.maj_h!=EMPTY_VALUE&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;state.maj_h_i=i;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         // BOS devam (bullish continuation): maj_st 1→0
         if(val_c>state.maj_h){
            if(state.swept_choch){
               if(!is_history && InpAlertPush && g_last_red_time != time[i]) { SendNotification("🔴 Kırmızı Top: Likidite Alınarak Trend Devamı (Boğa)"); g_last_red_time = time[i]; }
               DrawDot(GetUniqueName(pfx+"RedDot_"),GetTimeSafe(time,i),val_h,clrRed);
            }
            ResetChochState(state); // Yeni trend bacağı, CHoCH sıfırla
            state.bos_i=i;state.bos_count++;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_l_i),state.maj_l,InpColorBull,2,STYLE_SOLID);
            state.st_h.Clear();state.maj_st=0;state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            BxReset(state,state.maj_l,val_h);
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;state.maj_l_i=i;state.swept_choch=true;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         // BOS: Boğa → Ayı (maj_st==1)
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l){
            ResetChochState(state); // CHoCH setup eski swing'e ait, sıfırla
            BxAdvanceTrim(GetTimeSafe(time,state.tmp_h_i));

            if(state.bos_count==0){
               if(!is_history && InpAlertPush && g_last_yellow_time != time[i]) { SendNotification("🟡 Sarı Top: Ani Trend Dönüşü (Boğa -> Ayı)"); g_last_yellow_time = time[i]; }
               DrawDot(GetUniqueName(pfx+"YellowDot_"),GetTimeSafe(time,i),val_l,clrYellow);
            }

            state.maj_tr=-1;state.maj_st=0;state.bos_i=i;state.bos_count=0;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            BxReset(state,val_l,state.tmp_h);state.has_pot_bear_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }else{
      if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
      if(state.maj_st==0){
         double act=state.st_h.Size()>0?state.st_h.GetVal(state.st_h.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_h>act){
            state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_l_i),state.maj_l,InpColorBear,2,STYLE_SOLID);
            BxAdvanceTrim(GetTimeSafe(time,state.maj_l_i));
            state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));
            if(InpShowMaj){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,GetTimeSafe(time,state.maj_l_i),state.maj_l,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_l,InpColorBear,1,STYLE_DASH,true);
               if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,GetTimeSafe(time,state.maj_h_i),state.maj_h,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_h,InpColorBear,1,STYLE_DASH,true);}}
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;state.maj_h_i=i;state.swept_choch=true;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         // BOS: Ayı → Boğa (maj_st==0)
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h){
            ResetChochState(state); // CHoCH setup eski swing'e ait, sıfırla
            BxAdvanceTrim(GetTimeSafe(time,state.tmp_l_i));

            if(state.bos_count==0){
               if(!is_history && InpAlertPush && g_last_yellow_time != time[i]) { SendNotification("🟡 Sarı Top: Ani Trend Dönüşü (Ayı -> Boğa)"); g_last_yellow_time = time[i]; }
               DrawDot(GetUniqueName(pfx+"YellowDot_"),GetTimeSafe(time,i),val_h,clrYellow);
            }

            state.maj_tr=1;state.maj_st=0;state.bos_i=i;state.bos_count=0;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            BxReset(state,state.tmp_l,val_h);state.has_pot_bull_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }else if(state.maj_st==1){
         if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
         if(state.maj_l!=EMPTY_VALUE&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;state.maj_l_i=i;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         // BOS devam (bearish continuation): maj_st 1→0
         if(state.maj_l!=EMPTY_VALUE&&val_c<state.maj_l){
            if(state.swept_choch){
               if(!is_history && InpAlertPush && g_last_red_time != time[i]) { SendNotification("🔴 Kırmızı Top: Likidite Alınarak Trend Devamı (Ayı)"); g_last_red_time = time[i]; }
               DrawDot(GetUniqueName(pfx+"RedDot_"),GetTimeSafe(time,i),val_l,clrRed);
            }
            ResetChochState(state); // Yeni trend bacağı, CHoCH sıfırla
            state.maj_h=state.tmp_h;state.bos_i=i;state.bos_count++;state.maj_h_i=state.tmp_h_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_h_i),state.maj_h,InpColorBear,2,STYLE_SOLID);
            state.st_l.Clear();state.maj_st=0;state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            BxReset(state,val_l,state.maj_h);
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;state.maj_h_i=i;state.swept_choch=true;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         // BOS: Ayı → Boğa (maj_st==1)
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h){
            ResetChochState(state); // CHoCH setup eski swing'e ait, sıfırla
            BxAdvanceTrim(GetTimeSafe(time,state.tmp_l_i));

            if(state.bos_count==0){
               if(!is_history && InpAlertPush && g_last_yellow_time != time[i]) { SendNotification("🟡 Sarı Top: Ani Trend Dönüşü (Ayı -> Boğa)"); g_last_yellow_time = time[i]; }
               DrawDot(GetUniqueName(pfx+"YellowDot_"),GetTimeSafe(time,i),val_h,clrYellow);
            }

            state.maj_tr=1;state.maj_st=0;state.bos_i=i;state.bos_count=0;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            BxReset(state,state.tmp_l,val_h);state.has_pot_bull_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }
}

//+------------------------------------------------------------------+
int OnInit(){IndicatorSetString(INDICATOR_SHORTNAME,"Structure_IMB");return INIT_SUCCEEDED;}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
   ObjectsDeleteAll(0,"Live_"); ObjectsDeleteAll(0,"CHoCH_Path_");ObjectsDeleteAll(0,"CHoCH_Signal_");
   ObjectsDeleteAll(0,"Box_");  ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");
   DeleteLine("LiveLeg");BxClear();
}

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],const double &high[],
                const double &low[],const double &close[],
                const long &tick_volume[],const long &volume[],const int &spread[])
{
   if(rates_total<2)return 0;


   int limit;
   if(prev_calculated==0){
      double chart_days=GetDaysForTF(_Period);
      g_anchor_time=TimeCurrent()-(datetime)(chart_days*86400.0);g_counter=0;
      ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
      ObjectsDeleteAll(0,"Live_"); ObjectsDeleteAll(0,"CHoCH_Path_");ObjectsDeleteAll(0,"CHoCH_Signal_");
      ObjectsDeleteAll(0,"Box_");  ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");BxClear();

      int si=0;for(int k=0;k<rates_total;k++)if(time[k]>=g_anchor_time){si=k;break;}
      g_state_hist.min_h=high[si];g_state_hist.min_h_i=si;g_state_hist.min_l=low[si];g_state_hist.min_l_i=si;
      g_state_hist.trig_h=high[si];g_state_hist.trig_l=low[si];
      g_state_hist.tmp_h=high[si];g_state_hist.tmp_h_i=si;g_state_hist.tmp_l=low[si];g_state_hist.tmp_l_i=si;
      g_state_hist.min_tr=(close[si]>open[si])?1:-1;
      g_state_hist.anc_i=si;g_state_hist.anc_v=close[si];g_state_hist.lp_i=si;g_state_hist.lp_p=close[si];
      g_state_hist.bos_i=si;g_state_hist.bos_count=0;g_state_hist.maj_h_i=si;g_state_hist.maj_l_i=si;
      g_state_hist.mb_h=high[si];g_state_hist.mb_l=low[si];g_state_hist.mb_i=si;
      g_state_hist.t1_h=0;g_state_hist.t1_l=0;g_state_hist.t1_i=0;
      g_state_hist.d1_h=0;g_state_hist.d1_l=0;g_state_hist.d1_i=0;
      g_state_hist.t2_h=0;g_state_hist.t2_l=0;g_state_hist.t2_i=0;g_state_hist.choch_dir=0;
      double atr=high[si]-low[si];if(atr==0)atr=Point()*10;
      g_state_hist.maj_h=high[si]+atr*0.1;g_state_hist.maj_l=low[si]-atr*0.1;
      g_state_hist.maj_tr=g_state_hist.min_tr;g_state_hist.maj_st=1;
      g_state_hist.cur_top_line="";g_state_hist.cur_bot_line="";
      g_state_hist.st_h.Clear();g_state_hist.st_l.Clear();
      BxReset(g_state_hist,low[si],high[si]);
      g_state_hist.has_pot_bull_minor=false;g_state_hist.has_pot_bear_minor=false;
      g_state_hist.pot_bull_start_i=0;g_state_hist.pot_bull_start_p=0;g_state_hist.pot_bull_end_p=0;
      g_state_hist.pot_bear_start_i=0;g_state_hist.pot_bear_start_p=0;g_state_hist.pot_bear_end_p=0;
      limit=si+1;
      if(limit<rates_total){g_state_hist.mb_h=high[limit-1];g_state_hist.mb_l=low[limit-1];g_state_hist.mb_i=limit-1;}
   }else{limit=prev_calculated-1;}

   for(int i=limit;i<rates_total-1;i++){
      bool inside=(high[i]<=g_state_hist.mb_h)&&(low[i]>=g_state_hist.mb_l);
      if(!inside){
         if(high[i]>g_state_hist.mb_h||low[i]<g_state_hist.mb_l){g_state_hist.mb_h=high[i];g_state_hist.mb_l=low[i];g_state_hist.mb_i=i;}
         ProcessBar(i,open,high,low,close,time,g_state_hist,true);
      }else{double pc=(i>0)?close[i-1]:close[i];BxUpdateStats(high[i],low[i],close[i],pc,time[i],true);}
   }

   ObjectsDeleteAll(0,"Live_");DeleteLine("LiveLeg");
   g_state_curr.CopyFrom(g_state_hist);
   int li=rates_total-1;
   if(li>0){
      bool il=(high[li]<=g_state_curr.mb_h)&&(low[li]>=g_state_curr.mb_l);
      if(!il)ProcessBar(li,open,high,low,close,time,g_state_curr,false);
      else{double pc=(li>0)?close[li-1]:close[li];BxUpdateStats(high[li],low[li],close[li],pc,time[li],false);}
   }

   if(InpShowMin&&li>0){
      int    lgi=(g_state_curr.min_tr==1)?g_state_curr.min_h_i:g_state_curr.min_l_i;
      double lgp=(g_state_curr.min_tr==1)?g_state_curr.min_h  :g_state_curr.min_l;
      DrawLine("LiveLeg",GetTimeSafe(time,g_state_curr.lp_i),g_state_curr.lp_p,GetTimeSafe(time,lgi),lgp,InpColorMin,1,STYLE_DOT);
   }
   return rates_total;
}