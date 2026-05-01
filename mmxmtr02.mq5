//+------------------------------------------------------------------+
//|                                         smacv2_choch_box.mq5     |
//|   SMC v2 – Temiz Yeniden Yazım                                   |
//+------------------------------------------------------------------+
//
//  KUTU KURALI (bull majör için, bear simetrik):
//  Phase 0 → İlk bull minor → KUTU çiz → phase=1
//  Phase 1 → İzle:
//    Bull minor: peak > bx_swing_h → bx_extreme=true, bx_swing_h=peak
//    Bear minor: bx_extreme VE trough < bx_swing_l → CHoCH! phase=2
//               değilse → bx_swing_l=trough
//  Phase 2 → Sonraki bull minor → KUTU çiz → phase=1
//
//  Majör konfirmasyon → BxTrimAll (sağ VLine'da kes)
//  Trend flip         → BxDeleteAll (tamamen sil)
//  BoS devam          → BxReset (phase=0, yeni impuls)
//
//  Kutu boyutu > InpMaxBoxPct → st_h/st_l'den en yakın iç seviyeye çek
//    Bull: bot sabit, top'u en küçük iç minor high'a çek
//    Bear: top sabit, bot'u en büyük iç minor low'a çek
//
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "23.00"
#property indicator_chart_window
#property indicator_plots 0

input double InpDaysM1       = 3.0;

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
input color  InpColorBoxBull = C'0,70,160';
input color  InpColorBoxBear = C'160,50,0';

input group "--- KUTU ---"
input double InpMaxBoxPct    = 20.0;

int      g_counter     = 0;
datetime g_anchor_time = 0;

//--------------------------------------------------------------------
//  Kutu takip
//--------------------------------------------------------------------
#define BOX_MAX 512
string g_bx_nm[BOX_MAX];
bool   g_bx_op[BOX_MAX];
int    g_bx_cnt = 0;

void BxAdd(string nm)
{ if(g_bx_cnt<BOX_MAX){g_bx_nm[g_bx_cnt]=nm;g_bx_op[g_bx_cnt]=true;g_bx_cnt++;} }

void BxTrimAll(datetime t)
{ for(int k=0;k<g_bx_cnt;k++) if(g_bx_op[k]&&ObjectFind(0,g_bx_nm[k])>=0){ObjectSetInteger(0,g_bx_nm[k],OBJPROP_TIME,1,t);g_bx_op[k]=false;} }

void BxDeleteAll()
{ for(int k=0;k<g_bx_cnt;k++) if(ObjectFind(0,g_bx_nm[k])>=0)ObjectDelete(0,g_bx_nm[k]); g_bx_cnt=0; }

void BxClear() { g_bx_cnt=0; }

//--------------------------------------------------------------------
//  Çizim yardımcıları
//--------------------------------------------------------------------
datetime ST(const datetime &t[],int idx)
{ int s=ArraySize(t);if(s<=0)return 0;if(idx<0)return t[0];if(idx>=s)return t[s-1];return t[idx]; }

string GetUniqueName(string p){g_counter++;return p+IntegerToString(g_counter);}

void DrawLine(string nm,datetime t1,double p1,datetime t2,double p2,
              color clr,int w,ENUM_LINE_STYLE st,bool ray=false)
{
   if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_TREND,0,t1,p1,t2,p2);
   else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p1);
        ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2);ObjectSetDouble(0,nm,OBJPROP_PRICE,1,p2);}
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_WIDTH,w);
   ObjectSetInteger(0,nm,OBJPROP_STYLE,st);ObjectSetInteger(0,nm,OBJPROP_RAY_RIGHT,ray);
   ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}

void DrawVLine(string nm,datetime t,color clr,ENUM_LINE_STYLE st=STYLE_DASH,int w=2)
{
   if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_VLINE,0,t,0);
   else ObjectSetInteger(0,nm,OBJPROP_TIME,0,t);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_STYLE,st);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,w);ObjectSetInteger(0,nm,OBJPROP_BACK,true);
   ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}

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

void DeleteLine(string n){if(ObjectFind(0,n)>=0)ObjectDelete(0,n);}
void CutLine(string n,datetime t){if(ObjectFind(0,n)>=0){ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,n,OBJPROP_TIME,1,t);}}
void UpdateLevel(string n,double v){if(ObjectFind(0,n)>=0){ObjectSetDouble(0,n,OBJPROP_PRICE,0,v);ObjectSetDouble(0,n,OBJPROP_PRICE,1,v);}}

void DrawSwingVLines(const datetime &time[],string pfx,int s_i,int e_i,color clr)
{ DrawVLine(GetUniqueName(pfx+"VL_"),ST(time,s_i),clr);DrawVLine(GetUniqueName(pfx+"VL_"),ST(time,e_i),clr); }

//--------------------------------------------------------------------
//  CStack
//--------------------------------------------------------------------
class CStack
{
private: double m_v[]; int m_i[];
public:
   CStack(){ArrayResize(m_v,0);ArrayResize(m_i,0);}
   void   Clear()             {ArrayResize(m_v,0);ArrayResize(m_i,0);}
   int    Size()              {return ArraySize(m_v);}
   void   Push(double v,int i){int s=ArraySize(m_v);ArrayResize(m_v,s+1);ArrayResize(m_i,s+1);m_v[s]=v;m_i[s]=i;}
   void   Pop()               {int s=ArraySize(m_v);if(s>0){ArrayResize(m_v,s-1);ArrayResize(m_i,s-1);}}
   double GetVal(int i)       {return m_v[i];}
   int    GetIdx(int i)       {return m_i[i];}
   void   CopyFrom(CStack &s) {ArrayCopy(m_v,s.m_v);ArrayCopy(m_i,s.m_i);}
};

//--------------------------------------------------------------------
//  SState
//--------------------------------------------------------------------
struct SState
{
   int    min_tr,maj_tr,maj_st;
   double min_h;int min_h_i;double min_l;int min_l_i;
   double trig_h,trig_l;
   int    lp_i;double lp_p;
   double maj_h,maj_l;int maj_h_i,maj_l_i;
   double tmp_h;int tmp_h_i;double tmp_l;int tmp_l_i;
   int    anc_i;double anc_v;int bos_i;
   string cur_top_line,cur_bot_line;
   double mb_h,mb_l;int mb_i;
   CStack st_h,st_l;

   // Kutu state
   int    bx_phase;    // 0=ilk kutu bekle, 1=CHoCH izle, 2=CHoCH oldu sonraki kutu çiz
   bool   bx_extreme;  // bull: HH görüldü / bear: LL görüldü
   double bx_swing_h;  // referans high
   double bx_swing_l;  // referans low

   void CopyFrom(SState &s)
   {
      min_tr=s.min_tr;maj_tr=s.maj_tr;maj_st=s.maj_st;
      min_h=s.min_h;min_h_i=s.min_h_i;min_l=s.min_l;min_l_i=s.min_l_i;
      trig_h=s.trig_h;trig_l=s.trig_l;lp_i=s.lp_i;lp_p=s.lp_p;
      maj_h=s.maj_h;maj_l=s.maj_l;maj_h_i=s.maj_h_i;maj_l_i=s.maj_l_i;
      tmp_h=s.tmp_h;tmp_h_i=s.tmp_h_i;tmp_l=s.tmp_l;tmp_l_i=s.tmp_l_i;
      anc_i=s.anc_i;anc_v=s.anc_v;bos_i=s.bos_i;
      cur_top_line=s.cur_top_line;cur_bot_line=s.cur_bot_line;
      mb_h=s.mb_h;mb_l=s.mb_l;mb_i=s.mb_i;
      st_h.CopyFrom(s.st_h);st_l.CopyFrom(s.st_l);
      bx_phase=s.bx_phase;bx_extreme=s.bx_extreme;
      bx_swing_h=s.bx_swing_h;bx_swing_l=s.bx_swing_l;
   }
};

SState g_state_hist;
SState g_state_curr;

void BxReset(SState &s,double ref_l,double ref_h)
{ s.bx_phase=0;s.bx_extreme=false;s.bx_swing_l=ref_l;s.bx_swing_h=ref_h; }

//--------------------------------------------------------------------
//  Kutu çiz – boyut filtresi dahil
//--------------------------------------------------------------------
void DoDrawBox(const datetime &time[],string pfx,SState &s,
               int left_i,double top,double bot,color clr)
{
   // Sol kenar anchor'dan önceye gidemez
   if(left_i < s.anc_i) left_i = s.anc_i;

   // Boyut filtresi
   double maj_sz = s.maj_h - s.maj_l;
   if(maj_sz > 0 && (top-bot)/maj_sz*100.0 > InpMaxBoxPct)
   {
      if(clr == InpColorBoxBull)
      {
         // Bull: bot sabit, top'u en küçük iç minor high'a çek
         double fh = -1;
         int    fi = left_i;
         for(int k=0;k<s.st_h.Size();k++)
         {
            double mh=s.st_h.GetVal(k);
            if(mh>bot && mh<top && (fh<0 || mh<fh))
            { fh=mh; fi=s.st_h.GetIdx(k); }
         }
         if(fh>0){ top=fh; left_i=fi; }
         else     top=bot+maj_sz*InpMaxBoxPct/100.0;
      }
      else
      {
         // Bear: top sabit, bot'u en büyük iç minor low'a çek
         double fl = -1;
         int    fi = left_i;
         for(int k=0;k<s.st_l.Size();k++)
         {
            double ml=s.st_l.GetVal(k);
            if(ml<top && ml>bot && (fl<0 || ml>fl))
            { fl=ml; fi=s.st_l.GetIdx(k); }
         }
         if(fl>0){ bot=fl; left_i=fi; }
         else     bot=top-maj_sz*InpMaxBoxPct/100.0;
      }
   }

   if(top <= bot) return;
   string nm=GetUniqueName(pfx+"Box_");
   DrawRect(nm,ST(time,left_i),top,D'2099.12.31 00:00',bot,clr);
   BxAdd(nm);
}

//--------------------------------------------------------------------
//  ProcessBar
//--------------------------------------------------------------------
void ProcessBar(int i,
                const double &open[],const double &high[],
                const double &low[], const double &close[],
                const datetime &time[],
                SState &state,bool is_history,bool draw_ui=true)
{
   int rt=ArraySize(time);
   if(rt<=0||i<0||i>=rt)return;
   double val_h=high[i],val_l=low[i],val_c=close[i];
   string pfx=is_history?"":"Live_";

   //================================================================
   //  MİNÖR
   //================================================================
   if(state.min_tr==1)   // HIGH onaylanacak
   {
      double old_trig=state.trig_l;
      if(val_h>state.min_h){state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;}

      if(val_l<old_trig)  // BULL minor onaylandı
      {
         int    peak_i  = state.min_h_i;
         double peak_p  = state.min_h;
         int    start_i = state.lp_i;
         double start_lp= state.lp_p;

         if(draw_ui&&InpShowMin)
            DrawLine(GetUniqueName(pfx+"Minor_"),ST(time,start_i),start_lp,ST(time,peak_i),peak_p,InpColorMin,1,STYLE_SOLID);

         //--- Bull majör: bull minor geldi
         if(draw_ui&&InpShowBox&&state.maj_st==0&&state.maj_tr==1)
         {
            if(state.bx_phase==0||state.bx_phase==2)
            {
               // İlk veya CHoCH sonrası → KUTU ÇİZ
               if(is_history)
                  DoDrawBox(time,pfx,state,start_i,peak_p,start_lp,InpColorBoxBull);
               // Phase ve referansları güncelle
               state.bx_phase=1;
               state.bx_extreme=false;
               state.bx_swing_h=peak_p;
               state.bx_swing_l=start_lp;
            }
            else // phase==1: CHoCH izliyoruz
            {
               if(peak_p>state.bx_swing_h)
               {
                  state.bx_extreme=true;
                  state.bx_swing_h=peak_p;
               }
            }
         }

         //--- Bear majör: bull minor HH → CHoCH tespiti
         if(draw_ui&&InpShowBox&&state.maj_st==0&&state.maj_tr==-1&&state.bx_phase==1)
         {
            if(state.bx_extreme&&peak_p>state.bx_swing_h)
            {
               // CHoCH → bir sonraki bear minor'a kutu çizilecek
               state.bx_phase=2;
               state.bx_extreme=false;
            }
            else
               state.bx_swing_h=peak_p;
         }

         state.st_h.Push(peak_p,peak_i);
         if(state.maj_tr==1&&state.maj_st==0&&peak_p<state.tmp_h&&state.st_l.Size()>0)
            if(state.st_l.GetIdx(state.st_l.Size()-1)>state.bos_i)state.st_l.Pop();
         state.min_tr=-1;
         state.lp_i=peak_i;state.lp_p=peak_p;
         state.min_l=val_l;state.min_l_i=i;state.trig_h=val_h;
      }
   }
   else   // LOW onaylanacak
   {
      double old_trig=state.trig_h;
      if(val_l<state.min_l){state.min_l=val_l;state.min_l_i=i;state.trig_h=val_h;}

      if(val_h>old_trig)  // BEAR minor onaylandı
      {
         int    trough_i = state.min_l_i;
         double trough_p = state.min_l;
         int    start_i  = state.lp_i;
         double start_hp = state.lp_p;

         if(draw_ui&&InpShowMin)
            DrawLine(GetUniqueName(pfx+"Minor_"),ST(time,start_i),start_hp,ST(time,trough_i),trough_p,InpColorMin,1,STYLE_SOLID);

         //--- Bull majör: bear minor LL → CHoCH tespiti
         if(draw_ui&&InpShowBox&&state.maj_st==0&&state.maj_tr==1&&state.bx_phase==1)
         {
            if(state.bx_extreme&&trough_p<state.bx_swing_l)
            {
               // CHoCH → bir sonraki bull minor'a kutu çizilecek
               state.bx_phase=2;
               state.bx_extreme=false;
            }
            else
               state.bx_swing_l=trough_p;
         }

         //--- Bear majör: bear minor geldi
         if(draw_ui&&InpShowBox&&state.maj_st==0&&state.maj_tr==-1)
         {
            if(state.bx_phase==0||state.bx_phase==2)
            {
               // İlk veya CHoCH sonrası → KUTU ÇİZ
               if(is_history)
                  DoDrawBox(time,pfx,state,start_i,start_hp,trough_p,InpColorBoxBear);
               state.bx_phase=1;
               state.bx_extreme=false;
               state.bx_swing_h=start_hp;
               state.bx_swing_l=trough_p;
            }
            else // phase==1: CHoCH izliyoruz
            {
               if(trough_p<state.bx_swing_l)
               {
                  state.bx_extreme=true;
                  state.bx_swing_l=trough_p;
               }
            }
         }

         state.st_l.Push(trough_p,trough_i);
         if(state.maj_tr==-1&&state.maj_st==0&&trough_p>state.tmp_l&&state.st_h.Size()>0)
            if(state.st_h.GetIdx(state.st_h.Size()-1)>state.bos_i)state.st_h.Pop();
         state.min_tr=1;
         state.lp_i=trough_i;state.lp_p=trough_p;
         state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;
      }
   }

   //================================================================
   //  MAJÖR
   //================================================================
   if(state.maj_tr==0){state.maj_tr=1;state.anc_i=state.min_l_i;state.anc_v=state.min_l;state.maj_l_i=state.min_l_i;}

   if(state.maj_tr==1)
   {
      if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;}
      if(state.maj_st==0)
      {
         double act=state.st_l.Size()>0?state.st_l.GetVal(state.st_l.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_l<act)
         {
            // Bull majör HIGH onaylandı → BxTrimAll
            state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_h_i),state.maj_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.maj_h_i,InpColorVLBull);
            if(draw_ui&&InpShowBox)BxTrimAll(time[state.maj_h_i]);
            state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);
            if(draw_ui&&InpShowMaj){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,ST(time,state.maj_h_i),state.maj_h,time[i]+PeriodSeconds(),state.maj_h,InpColorBull,1,STYLE_DASH,true);if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,ST(time,state.maj_l_i),state.maj_l,time[i]+PeriodSeconds(),state.maj_l,InpColorBull,1,STYLE_DASH,true);}}
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l)
         {
            // FLIP bull→bear → BxTrimAll and Draw VL
            if(draw_ui&&InpShowBox)BxTrimAll(time[state.tmp_h_i]);
            state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_h_i,InpColorVLBull);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            state.maj_l=val_l;state.maj_l_i=i;
            BxReset(state,val_l,state.tmp_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
      }
      else if(state.maj_st==1)
      {
         if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;}
         if(val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(val_c>state.maj_h)
         {
            // BoS yükseliş → yeni bull impuls
            state.bos_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_l_i),state.maj_l,InpColorBull,2,STYLE_SOLID);
            state.st_h.Clear();state.maj_st=0;state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            BxReset(state,state.maj_l,val_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l)
         {
            // FLIP bull→bear → BxTrimAll and Draw VL
            if(draw_ui&&InpShowBox)BxTrimAll(time[state.tmp_h_i]);
            state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_h_i,InpColorVLBull);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            state.maj_l=val_l;state.maj_l_i=i;
            BxReset(state,val_l,state.tmp_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }
   else   // maj_tr==-1
   {
      if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;}
      if(state.maj_st==0)
      {
         double act=state.st_h.Size()>0?state.st_h.GetVal(state.st_h.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_h>act)
         {
            // Bear majör LOW onaylandı → BxTrimAll
            state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_l_i),state.maj_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.maj_l_i,InpColorVLBear);
            if(draw_ui&&InpShowBox)BxTrimAll(time[state.maj_l_i]);
            state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);
            if(draw_ui&&InpShowMaj){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,ST(time,state.maj_l_i),state.maj_l,time[i]+PeriodSeconds(),state.maj_l,InpColorBear,1,STYLE_DASH,true);if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,ST(time,state.maj_h_i),state.maj_h,time[i]+PeriodSeconds(),state.maj_h,InpColorBear,1,STYLE_DASH,true);}}
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h)
         {
            // FLIP bear→bull
            if(draw_ui&&InpShowBox)BxTrimAll(time[state.tmp_l_i]);
            state.maj_tr=1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_l_i,InpColorVLBear);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            state.maj_h=val_h;state.maj_h_i=i;
            BxReset(state,state.tmp_l,val_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
      }
      else if(state.maj_st==1)
      {
         if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;}
         if(val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(val_c<state.maj_l)
         {
            // BoS düşüş → yeni bear impuls
            state.maj_h=state.tmp_h;state.bos_i=i;state.maj_h_i=state.tmp_h_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_h_i),state.maj_h,InpColorBear,2,STYLE_SOLID);
            state.st_l.Clear();state.maj_st=0;state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            BxReset(state,val_l,state.maj_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h)
         {
            // FLIP bear→bull
            if(draw_ui&&InpShowBox)BxTrimAll(time[state.tmp_l_i]);
            state.maj_tr=1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_l_i,InpColorVLBear);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            state.maj_h=val_h;state.maj_h_i=i;
            BxReset(state,state.tmp_l,val_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }
}

//--------------------------------------------------------------------
int OnInit(){IndicatorSetString(INDICATOR_SHORTNAME,"SMACv2_v23");return INIT_SUCCEEDED;}
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
   ObjectsDeleteAll(0,"VL_");ObjectsDeleteAll(0,"Box_");ObjectsDeleteAll(0,"Live_");
   BxClear();Comment("");
}

//--------------------------------------------------------------------
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[], const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   if(rates_total<2)return 0;
   static datetime last_bar_time=0;static int last_rates_tot=0;
   int vp=prev_calculated;
   if(prev_calculated==0&&last_bar_time==time[rates_total-1])vp=rates_total-1;
   if(last_rates_tot>0&&rates_total<last_rates_tot)vp=0;

   if(vp==0)
   {
      last_bar_time=time[rates_total-1];
      g_anchor_time=TimeCurrent()-(datetime)(InpDaysM1*86400.0);
      g_counter=0;
      ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
      ObjectsDeleteAll(0,"VL_");ObjectsDeleteAll(0,"Box_");ObjectsDeleteAll(0,"Live_");
      BxClear();

      int si=0;
      for(int k=0;k<rates_total;k++)if(time[k]>=g_anchor_time){si=k;break;}

      g_state_hist.min_h=high[si];g_state_hist.min_h_i=si;
      g_state_hist.min_l=low[si]; g_state_hist.min_l_i=si;
      g_state_hist.trig_h=high[si];g_state_hist.trig_l=low[si];
      g_state_hist.tmp_h=high[si]; g_state_hist.tmp_h_i=si;
      g_state_hist.tmp_l=low[si];  g_state_hist.tmp_l_i=si;
      g_state_hist.min_tr=(close[si]>open[si])?1:-1;
      g_state_hist.anc_i=si;g_state_hist.anc_v=close[si];
      g_state_hist.lp_i=si;g_state_hist.lp_p=close[si];
      g_state_hist.bos_i=si;g_state_hist.maj_h_i=si;g_state_hist.maj_l_i=si;
      g_state_hist.mb_h=high[si];g_state_hist.mb_l=low[si];g_state_hist.mb_i=si;
      double ig=high[si]-low[si];if(ig==0)ig=Point()*10;
      g_state_hist.maj_h=high[si]+ig*0.1;g_state_hist.maj_l=low[si]-ig*0.1;
      g_state_hist.maj_tr=g_state_hist.min_tr;g_state_hist.maj_st=1;
      g_state_hist.cur_top_line="";g_state_hist.cur_bot_line="";
      g_state_hist.st_h.Clear();g_state_hist.st_l.Clear();
      BxReset(g_state_hist,low[si],high[si]);

      for(int i=si+1;i<rates_total-1;i++)
      {
         bool inside=(high[i]<=g_state_hist.mb_h)&&(low[i]>=g_state_hist.mb_l);
         if(!inside)
         {
            if(high[i]>g_state_hist.mb_h||low[i]<g_state_hist.mb_l)
               {g_state_hist.mb_h=high[i];g_state_hist.mb_l=low[i];g_state_hist.mb_i=i;}
            ProcessBar(i,open,high,low,close,time,g_state_hist,true,true);
         }
      }
   }

   ObjectsDeleteAll(0,"Live_");DeleteLine("LiveLeg");
   int li=rates_total-1;
   g_state_curr.CopyFrom(g_state_hist);
   if(li>0){bool il=(high[li]<=g_state_curr.mb_h)&&(low[li]>=g_state_curr.mb_l);if(!il)ProcessBar(li,open,high,low,close,time,g_state_curr,false,true);}
   if(InpShowMin&&li>0)
   {
      int lgi;double lgp;
      if(g_state_curr.min_tr==1){lgi=g_state_curr.min_h_i;lgp=g_state_curr.min_h;}
      else{lgi=g_state_curr.min_l_i;lgp=g_state_curr.min_l;}
      DrawLine("LiveLeg",ST(time,g_state_curr.lp_i),g_state_curr.lp_p,ST(time,lgi),lgp,InpColorMin,1,STYLE_DOT);
   }
   last_rates_tot=rates_total;
   return(rates_total);
}
//+------------------------------------------------------------------+
