//+------------------------------------------------------------------+
//|                                            manueltrademanuel.mq5 |
//|   Highly optimized structure, major/minor logic, IMB boxes       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "4.00"
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

//--- Yapı
input bool   InpShowMin   = true;
input bool   InpShowMaj   = true;
input color  InpColorMin  = clrRed;
input color  InpColorBull = clrGreen;
input color  InpColorBear = clrRed;

//--- Kutu (Sadece IMB Sonrası Kutu)
input bool   InpShowBox           = true;
input double InpMaxBoxPct         = 20.0;
input double InpWeakZonePct       = 50.0;
input color  InpColorBoxBull      = clrDodgerBlue;
input color  InpColorBoxBear      = clrRed;
input color  InpColorBoxBullFaint = C'0,40,90';
input color  InpColorBoxBearFaint = C'90,20,0';
input color  InpColorWeakBull     = C'0,25,55';
input color  InpColorWeakBear     = C'55,15,0';

input bool InpAlertPush = true;

int g_counter = 0;
datetime g_anchor_time = 0;
datetime g_last_yellow_time = 0;
datetime g_last_red_time = 0;

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

class CStringStack{
private:string m_v[];
public:
   CStringStack(){ArrayResize(m_v,0);}
   void   Clear(){ArrayResize(m_v,0);}
   int    Size(){return ArraySize(m_v);}
   void   Push(string v){int s=ArraySize(m_v);ArrayResize(m_v,s+1);m_v[s]=v;}
   string GetVal(int i){return m_v[i];}
   void   CopyFrom(CStringStack &s){ArrayCopy(m_v,s.m_v);}
};

struct SState{
   int    min_tr,maj_tr,maj_st;
   double min_h;int min_h_i;double min_l;int min_l_i;
   double trig_h,trig_l;int lp_i;double lp_p;
   double maj_h;int maj_h_i;double maj_l;int maj_l_i;
   double tmp_h;int tmp_h_i;double tmp_l;int tmp_l_i;
   int    anc_i;double anc_v;int bos_i;int bos_count;
   string cur_top_line,cur_bot_line;
   double mb_h,mb_l;int mb_i;

   int    bx_phase;bool bx_extreme;double bx_swing_h,bx_swing_l;
   bool   has_pot_bull_minor;int pot_bull_start_i;double pot_bull_start_p,pot_bull_end_p;
   bool   has_pot_bear_minor;int pot_bear_start_i;double pot_bear_start_p,pot_bear_end_p;
   CStack st_h,st_l;
   CStringStack active_boxes;
   void CopyFrom(SState &s){
      min_tr=s.min_tr;maj_tr=s.maj_tr;maj_st=s.maj_st;
      min_h=s.min_h;min_h_i=s.min_h_i;min_l=s.min_l;min_l_i=s.min_l_i;
      trig_h=s.trig_h;trig_l=s.trig_l;lp_i=s.lp_i;lp_p=s.lp_p;
      maj_h=s.maj_h;maj_h_i=s.maj_h_i;maj_l=s.maj_l;maj_l_i=s.maj_l_i;
      tmp_h=s.tmp_h;tmp_h_i=s.tmp_h_i;tmp_l=s.tmp_l;tmp_l_i=s.tmp_l_i;
      anc_i=s.anc_i;anc_v=s.anc_v;bos_i=s.bos_i;bos_count=s.bos_count;
      cur_top_line=s.cur_top_line;cur_bot_line=s.cur_bot_line;
      mb_h=s.mb_h;mb_l=s.mb_l;mb_i=s.mb_i;
      bx_phase=s.bx_phase;bx_extreme=s.bx_extreme;bx_swing_h=s.bx_swing_h;bx_swing_l=s.bx_swing_l;
      has_pot_bull_minor=s.has_pot_bull_minor;pot_bull_start_i=s.pot_bull_start_i;
      pot_bull_start_p=s.pot_bull_start_p;pot_bull_end_p=s.pot_bull_end_p;
      has_pot_bear_minor=s.has_pot_bear_minor;pot_bear_start_i=s.pot_bear_start_i;
      pot_bear_start_p=s.pot_bear_start_p;pot_bear_end_p=s.pot_bear_end_p;
      st_h.CopyFrom(s.st_h);st_l.CopyFrom(s.st_l);active_boxes.CopyFrom(s.active_boxes);}
};

SState g_state_hist,g_state_curr;
void BxReset(SState &s,double rl,double rh){s.bx_phase=0;s.bx_extreme=false;s.bx_swing_l=rl;s.bx_swing_h=rh;}


void BxAdvanceTrim(SState &s, datetime t)
{
   for(int k=0; k<s.active_boxes.Size(); k++){
      string nm = s.active_boxes.GetVal(k);
      if(ObjectFind(0, nm) >= 0) {
         ObjectSetInteger(0, nm, OBJPROP_TIME, 1, t);
      }
   }
   s.active_boxes.Clear();
}

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
   s.active_boxes.Push(nm); s.active_boxes.Push(wk_abv); s.active_boxes.Push(wk_blw);
}

void ProcessBar(int i,const double &open[],const double &high[],const double &low[],
                const double &close[],const datetime &time[],SState &state,bool is_history)
{
   double val_h=high[i],val_l=low[i],val_c=close[i];
   string pfx=is_history?"":"Live_";

   if(state.min_tr==1){
      double ob=state.trig_l;
      if(val_h>state.min_h){state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;}
      if(val_l<ob){
         int pi=state.min_h_i;double pp=state.min_h;int si=state.lp_i;double sp=state.lp_p;
         if(InpShowMin)DrawLine(GetUniqueName(pfx+"Minor_"),GetTimeSafe(time,si),sp,GetTimeSafe(time,pi),pp,InpColorMin,1,STYLE_SOLID);
         if(state.maj_tr==-1&&!state.has_pot_bull_minor&&si>=state.tmp_l_i)
         {state.has_pot_bull_minor=true;state.pot_bull_start_i=si;state.pot_bull_start_p=sp;state.pot_bull_end_p=pp;}
         if(is_history&&InpShowBox&&state.maj_st==0&&state.maj_tr==1){
            if(state.bx_phase==0||state.bx_phase==2){DoDrawBox(time,pfx,state,si,pp,sp,InpColorBoxBull);state.bx_phase=1;state.bx_extreme=false;state.bx_swing_l=sp;state.bx_swing_h=pp;}
            else if(pp>state.bx_swing_h){state.bx_extreme=true;state.bx_swing_h=pp;}
         }
         if(state.maj_st==0&&state.maj_tr==-1&&state.bx_phase==1){
            if(state.bx_extreme&&pp>state.bx_swing_h){state.bx_phase=2;state.bx_extreme=false;}else state.bx_swing_h=pp;}
         state.st_h.Push(pp,pi);
         if(state.maj_tr==1&&state.maj_st==0&&pp<state.tmp_h&&state.st_l.Size()>0)
            if(state.st_l.GetIdx(state.st_l.Size()-1)>state.bos_i)state.st_l.Pop();
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
         state.min_tr=1;state.lp_i=ti;state.lp_p=tp;state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;
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
            BxAdvanceTrim(state, GetTimeSafe(time, state.maj_h_i)); state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));
            if(InpShowMaj){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,GetTimeSafe(time,state.maj_h_i),state.maj_h,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_h,InpColorBull,1,STYLE_DASH,true);
               if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,GetTimeSafe(time,state.maj_l_i),state.maj_l,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_l,InpColorBull,1,STYLE_DASH,true);}}
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;state.maj_l_i=i;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         // BOS: Boğa → Ayı (maj_st==0)
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l){
            if(state.bos_count==0){
               if(!is_history && InpAlertPush && g_last_yellow_time != time[i]) {
                   string msg = StringFormat("🟡 Sarı Top: Ani Trend Dönüşü (Boğa -> Ayı) | %s | %s", Symbol(), EnumToString(Period()));
                   SendNotification(msg);
                   g_last_yellow_time = time[i];
               }
               double atr = (high[i]-low[i]) > 0 ? (high[i]-low[i]) : Point()*10;
               DrawDot(GetUniqueName(pfx+"YellowDot_"),GetTimeSafe(time,i),val_l - atr*0.5,clrYellow);
            }
            state.maj_tr=-1;state.maj_st=0;state.bos_i=i;state.bos_count=0;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            BxAdvanceTrim(state, GetTimeSafe(time, state.tmp_h_i)); state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            if(state.has_pot_bear_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
            BxReset(state,val_l,state.tmp_h);state.has_pot_bear_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }else if(state.maj_st==1){
         if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
         if(state.maj_h!=EMPTY_VALUE&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;state.maj_h_i=i;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         // BOS devam (bullish continuation): maj_st 1→0
         if(state.maj_h!=EMPTY_VALUE&&val_c>state.maj_h){
            BxAdvanceTrim(state, GetTimeSafe(time, state.tmp_l_i)); state.maj_l=state.tmp_l;state.bos_i=i;state.bos_count++;state.maj_l_i=state.tmp_l_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_l_i),state.maj_l,InpColorBull,2,STYLE_SOLID);
            state.st_h.Clear();state.maj_st=0;state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            BxReset(state,state.maj_l,val_h);
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;state.maj_l_i=i;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         // BOS: Boğa → Ayı (maj_st==1)
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l){
            if(state.bos_count==0){
               if(!is_history && InpAlertPush && g_last_yellow_time != time[i]) {
                   string msg = StringFormat("🟡 Sarı Top: Ani Trend Dönüşü (Boğa -> Ayı) | %s | %s", Symbol(), EnumToString(Period()));
                   SendNotification(msg);
                   g_last_yellow_time = time[i];
               }
               double atr = (high[i]-low[i]) > 0 ? (high[i]-low[i]) : Point()*10;
               DrawDot(GetUniqueName(pfx+"YellowDot_"),GetTimeSafe(time,i),val_l - atr*0.5,clrYellow);
            }
            state.maj_tr=-1;state.maj_st=0;state.bos_i=i;state.bos_count=0;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            BxAdvanceTrim(state, GetTimeSafe(time, state.tmp_h_i)); state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            if(state.has_pot_bear_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
            BxReset(state,val_l,state.tmp_h);state.has_pot_bear_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }else if(state.maj_tr==-1){
      if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
      if(state.maj_st==0){
         double act=state.st_h.Size()>0?state.st_h.GetVal(state.st_h.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_h>act){
            state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_l_i),state.maj_l,InpColorBear,2,STYLE_SOLID);
            BxAdvanceTrim(state, GetTimeSafe(time, state.maj_l_i)); state.st_h.Clear();state.st_l.Clear();state.maj_st=1;
            state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));
            if(InpShowMaj){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,GetTimeSafe(time,state.maj_l_i),state.maj_l,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_l,InpColorBear,1,STYLE_DASH,true);
               if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,GetTimeSafe(time,state.maj_h_i),state.maj_h,GetTimeSafe(time,i)+PeriodSeconds(),state.maj_h,InpColorBear,1,STYLE_DASH,true);}}
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;state.maj_h_i=i;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         // BOS: Ayı → Boğa (maj_st==0)
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h){
            if(state.bos_count==0){
               if(!is_history && InpAlertPush && g_last_yellow_time != time[i]) {
                   string msg = StringFormat("🟡 Sarı Top: Ani Trend Dönüşü (Ayı -> Boğa) | %s | %s", Symbol(), EnumToString(Period()));
                   SendNotification(msg);
                   g_last_yellow_time = time[i];
               }
               double atr = (high[i]-low[i]) > 0 ? (high[i]-low[i]) : Point()*10;
               DrawDot(GetUniqueName(pfx+"YellowDot_"),GetTimeSafe(time,i),val_h + atr*0.5,clrYellow);
            }
            state.maj_tr=1;state.maj_st=0;state.bos_i=i;state.bos_count=0;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            BxAdvanceTrim(state, GetTimeSafe(time, state.tmp_l_i)); state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(state.has_pot_bull_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
            BxReset(state,state.tmp_l,val_h);state.has_pot_bull_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }else if(state.maj_st==1){
         if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
         if(state.maj_l!=EMPTY_VALUE&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;state.maj_l_i=i;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         // BOS devam (bearish continuation): maj_st 1→0
         if(state.maj_l!=EMPTY_VALUE&&val_c<state.maj_l){
            BxAdvanceTrim(state, GetTimeSafe(time, state.tmp_h_i)); state.maj_h=state.tmp_h;state.bos_i=i;state.bos_count++;state.maj_h_i=state.tmp_h_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_h_i),state.maj_h,InpColorBear,2,STYLE_SOLID);
            state.st_l.Clear();state.maj_st=0;state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            BxReset(state,val_l,state.maj_h);
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;state.maj_h_i=i;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         // BOS: Ayı → Boğa (maj_st==1)
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h){
            if(state.bos_count==0){
               if(!is_history && InpAlertPush && g_last_yellow_time != time[i]) {
                   string msg = StringFormat("🟡 Sarı Top: Ani Trend Dönüşü (Ayı -> Boğa) | %s | %s", Symbol(), EnumToString(Period()));
                   SendNotification(msg);
                   g_last_yellow_time = time[i];
               }
               double atr = (high[i]-low[i]) > 0 ? (high[i]-low[i]) : Point()*10;
               DrawDot(GetUniqueName(pfx+"YellowDot_"),GetTimeSafe(time,i),val_h + atr*0.5,clrYellow);
            }
            state.maj_tr=1;state.maj_st=0;state.bos_i=i;state.bos_count=0;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            BxAdvanceTrim(state, GetTimeSafe(time, state.tmp_l_i)); state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(state.has_pot_bull_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
            BxReset(state,state.tmp_l,val_h);state.has_pot_bull_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }
}

int OnInit(){IndicatorSetString(INDICATOR_SHORTNAME,"manueltrademanuel");return INIT_SUCCEEDED;}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
   ObjectsDeleteAll(0,"Live_");
   ObjectsDeleteAll(0,"Box_");  ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");
   ObjectsDeleteAll(0,"YellowDot_");
   DeleteLine("LiveLeg");
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
      ObjectsDeleteAll(0,"Live_");
      ObjectsDeleteAll(0,"Box_");  ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");
      ObjectsDeleteAll(0,"YellowDot_");

      int si=0;for(int k=0;k<rates_total;k++)if(time[k]>=g_anchor_time){si=k;break;}
      g_state_hist.min_h=high[si];g_state_hist.min_h_i=si;g_state_hist.min_l=low[si];g_state_hist.min_l_i=si;
      g_state_hist.trig_h=high[si];g_state_hist.trig_l=low[si];
      g_state_hist.tmp_h=high[si];g_state_hist.tmp_h_i=si;g_state_hist.tmp_l=low[si];g_state_hist.tmp_l_i=si;
      g_state_hist.min_tr=(close[si]>open[si])?1:-1;
      g_state_hist.anc_i=si;g_state_hist.anc_v=close[si];g_state_hist.lp_i=si;g_state_hist.lp_p=close[si];
      g_state_hist.bos_i=si;g_state_hist.bos_count=0;g_state_hist.maj_h_i=si;g_state_hist.maj_l_i=si;
      g_state_hist.mb_h=high[si];g_state_hist.mb_l=low[si];g_state_hist.mb_i=si;

      double atr=high[si]-low[si];if(atr==0)atr=Point()*10;
      g_state_hist.maj_h=high[si]+atr*0.1;g_state_hist.maj_l=low[si]-atr*0.1;
      g_state_hist.maj_tr=g_state_hist.min_tr;g_state_hist.maj_st=1;
      g_state_hist.cur_top_line="";g_state_hist.cur_bot_line="";
      g_state_hist.st_h.Clear();g_state_hist.st_l.Clear();g_state_hist.active_boxes.Clear();
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
      }
   }

   ObjectsDeleteAll(0,"Live_");DeleteLine("LiveLeg");
   g_state_curr.CopyFrom(g_state_hist);
   int li=rates_total-1;
   if(li>0){
      bool il=(high[li]<=g_state_curr.mb_h)&&(low[li]>=g_state_curr.mb_l);
      if(!il)ProcessBar(li,open,high,low,close,time,g_state_curr,false);
   }

   if(InpShowMin&&li>0){
      int    lgi=(g_state_curr.min_tr==1)?g_state_curr.min_h_i:g_state_curr.min_l_i;
      double lgp=(g_state_curr.min_tr==1)?g_state_curr.min_h  :g_state_curr.min_l;
      DrawLine("LiveLeg",GetTimeSafe(time,g_state_curr.lp_i),g_state_curr.lp_p,GetTimeSafe(time,lgi),lgp,InpColorMin,1,STYLE_DOT);
   }
   return rates_total;
}
