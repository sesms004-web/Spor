//+------------------------------------------------------------------+
//|                                              Structure_BT.mq5    |
//|   Minor + Major + CHoCH + Kutu + MTF + BT Overlay               |
//|   Backtest: SL=Swing/4  TP=3R (2R swing dışında)                |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "3.01"
#property indicator_chart_window
#property indicator_plots 0

//--- Lookback
input double InpDaysM1  = 1.0;
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

//--- MTF Cascade TF
input group "--- MTF AKTIF TF ---"
input bool InpEnableM15 = true;
input bool InpEnableM30 = true;
input bool InpEnableH1  = true;
input bool InpEnableH4  = true;
input bool InpEnableD1  = true;

//--- Yatay
input group "--- YATAY BOLGE ---"
input int InpExhaustionCount = 3;

//--- İşlem & Bildirim
input group "--- ISLEM & BILDIRIM ---"
input int  InpMaxTrades    = 2;
input bool InpNotifInvalid = true;
input bool InpAlertPush    = true;
input bool InpAlertPopup   = false;

//--- BACKTEST
input group "--- BACKTEST ---"
input bool   InpShowBT       = true;   // BT görsel aktif
input int    InpBTMaxBars    = 500;    // Sinyal başına max tarama (bar)
input bool   InpBTOnlyPB     = true;   // Sadece >=40% pb sinyalleri (filtre)
input double InpBTRR         = 3.0;   // Hedef R:R (örn. 2.5, 3.0)
input double InpBTSLPct      = 25.0;  // SL büyüklüğü swing'in yüzdesi (örn. 25.0)
input double InpRiskUSD      = 10.0;  // İşlem başına riske edilecek dolar ($)
input bool   InpTestMode     = false; // Test: lot 0.01 sabit gönder (bağlantı kontrolü)
input double InpTestLot      = 0.01;  // Test lot büyüklüğü

//=====================================================================
// DEFINES & BT STRUCT
//=====================================================================
#define TRADE_MAX     10
#define SHD_BOX_MAX  128
#define BOX_MAX      512
#define CASCADE_TF_COUNT 5
#define BT_MAX       500

struct BTSignal
{
   int      dir;         // -1=SELL  +1=BUY
   int      bar_i;       // CHoCH ateşlendiği bar indeksi
   int      outcome_i;   // Sonuç barı
   double   entry;       // d1_l (SELL) veya d1_h (BUY) seviyesi
   double   sl;          // Stop-Loss seviyesi
   double   tp;          // Take-Profit seviyesi
   bool     use_2r;      // TP = 2R (3R swing dışına taşıdı)
   double   maj_h;       // Swing high (CHoCH anındaki)
   double   maj_l;       // Swing low  (CHoCH anındaki)
   int      outcome;     // 0=açık  1=kâr  -1=zarar
   bool     is_strong;
   bool     skip;        // aynı swing'de 3.+ sinyal ise atla
   datetime time_open;
};

BTSignal g_bt[BT_MAX];
int      g_bt_cnt  = 0;
bool     g_bt_mode = false;   // true → ProcessBar BT koleksiyonu yapar

//=====================================================================
// GLOBALS (orijinalin aynısı)
//=====================================================================
int      g_counter     = 0;
datetime g_anchor_time = 0;
bool     g_shadow_mode = false;

double g_trade_t1_h[TRADE_MAX]; double g_trade_t2_h[TRADE_MAX];
int    g_trade_count_h=0; int g_current_maj_h_i=0;
double g_trade_t1_l[TRADE_MAX]; double g_trade_t2_l[TRADE_MAX];
int    g_trade_count_l=0; int g_current_maj_l_i=0;
int    g_last_notif_d1i_sell=-1; int g_last_notif_d1i_buy=-1;
int    g_last_sltp_d1i_sell =-1; int g_last_sltp_d1i_buy =-1;

double g_m1_sell_locked_top=0; double g_m1_sell_locked_bot=0;
double g_m1_buy_locked_top =0; double g_m1_buy_locked_bot =0;

void ResetBearishMemory(){
   g_trade_count_h=0;
   for(int i=0;i<TRADE_MAX;i++){g_trade_t1_h[i]=0;g_trade_t2_h[i]=0;}
   g_m1_sell_locked_top=0; g_m1_sell_locked_bot=0;
}
void ResetBullishMemory(){
   g_trade_count_l=0;
   for(int i=0;i<TRADE_MAX;i++){g_trade_t1_l[i]=0;g_trade_t2_l[i]=0;}
   g_m1_buy_locked_top=0; g_m1_buy_locked_bot=0;
}

//--- Shadow box
int      g_shd_state[SHD_BOX_MAX]; double g_shd_top[SHD_BOX_MAX];  double g_shd_bot[SHD_BOX_MAX];
int      g_shd_touch[SHD_BOX_MAX]; int    g_shd_appr[SHD_BOX_MAX]; int    g_shd_cnt_in[SHD_BOX_MAX];
datetime g_shd_ev_t[SHD_BOX_MAX];  int    g_shd_break_up[SHD_BOX_MAX]; int g_shd_break_dn[SHD_BOX_MAX];
int      g_shd_cnt=0;

//--- Ana kutu
string   g_bx_nm[BOX_MAX];       string   g_bx_wk_abv_nm[BOX_MAX]; string   g_bx_wk_blw_nm[BOX_MAX];
int      g_bx_state[BOX_MAX];    double   g_bx_top[BOX_MAX];        double   g_bx_bot[BOX_MAX];
int      g_bx_touch_state[BOX_MAX]; int   g_bx_approach[BOX_MAX];  int      g_bx_inside_cnt[BOX_MAX];
datetime g_bx_event_time[BOX_MAX];  int   g_bx_break_up[BOX_MAX];  int      g_bx_break_dn[BOX_MAX];
int      g_bx_cnt=0;

bool     g_bx_notified[BOX_MAX];      // kutu bildirim tekrar engeli
bool     g_live_bar_processing=false; // sadece canli bar islenir

struct TFBoxResult{
   ENUM_TIMEFRAMES tf;
   bool     has_box;
   int      touch_state,approach,cnt_in;
   datetime ev_t;
   int      break_up,break_dn;
   double   box_top,box_bot;
};

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
   if(tf==PERIOD_D1) return InpDaysD1;  if(tf==PERIOD_M1) return InpDaysM1;
   return 15.0;
}

bool IsGecersiz(int touch,int cnt_in,datetime ev_t,ENUM_TIMEFRAMES tf)
{
   if(touch==0)return true;
   int ps=PeriodSeconds(tf);
   if(touch==1)return(cnt_in>25);
   return(ps>0&&(int)((TimeCurrent()-ev_t)/ps)>25);
}

bool IsApproved(int choch_dir,int ts,int appr,int break_up,int break_dn)
{
   if(ts==0)return false;
   int total=break_up+break_dn;
   if((InpExhaustionCount>0)&&(break_up>=1)&&(break_dn>=1)&&(total>=InpExhaustionCount))return false;
   if(choch_dir==-1){if(ts==1&&appr==-1)return true;if(ts==2&&appr==1)return true;if(ts==3&&appr==-1)return true;}
   else             {if(ts==1&&appr== 1)return true;if(ts==2&&appr==-1)return true;if(ts==3&&appr== 1)return true;}
   return false;
}

string GetBoxStatusShort(int ts,int appr,int break_up,int break_dn)
{
   int total=break_up+break_dn;
   if((InpExhaustionCount>0)&&(break_up>=1)&&(break_dn>=1)&&(total>=InpExhaustionCount))
      return StringFormat("YATAY(U:%d A:%d)",break_up,break_dn);
   if(ts==0)return "Temas Yok";
   if(ts==1)return(appr==-1)?"Alttan->Ici"         :"Ustten->Ici";
   if(ts==2)return(appr==-1)?"Alttan->Yukari Deldi" :"Ustten->Asagi Deldi";
   if(ts==3)return(appr==-1)?"Alttan->Asagi Tepki"  :"Ustten->Yukari Tepki";
   return"?";
}

bool IsYatay(int touch,int break_up,int break_dn)
{
   if(touch==0)return false;
   int total=break_up+break_dn;
   return(InpExhaustionCount>0)&&(break_up>=1)&&(break_dn>=1)&&(total>=InpExhaustionCount);
}

//=====================================================================
// ÇİZİM
//=====================================================================
void DrawLine(string nm,datetime t1,double p1,datetime t2,double p2,color clr,int w,ENUM_LINE_STYLE st,bool ray=false)
{
   if(g_shadow_mode)return;
   if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_TREND,0,t1,p1,t2,p2);
   else{ObjectSetInteger(0,nm,OBJPROP_TIME,0,t1);ObjectSetDouble(0,nm,OBJPROP_PRICE,0,p1);
        ObjectSetInteger(0,nm,OBJPROP_TIME,1,t2);ObjectSetDouble(0,nm,OBJPROP_PRICE,1,p2);}
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_WIDTH,w);
   ObjectSetInteger(0,nm,OBJPROP_STYLE,st);ObjectSetInteger(0,nm,OBJPROP_RAY_RIGHT,ray);
   ObjectSetInteger(0,nm,OBJPROP_BACK,true);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}
void DeleteLine(string n){if(!g_shadow_mode&&ObjectFind(0,n)>=0)ObjectDelete(0,n);}
void CutLine(string n,datetime t){if(!g_shadow_mode&&ObjectFind(0,n)>=0){ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,n,OBJPROP_TIME,1,t);}}
void UpdateLineLevel(string n,double v){if(!g_shadow_mode&&ObjectFind(0,n)>=0){ObjectSetDouble(0,n,OBJPROP_PRICE,0,v);ObjectSetDouble(0,n,OBJPROP_PRICE,1,v);}}

void DrawRect(string nm,datetime t1,double top,datetime t2,double bot,color clr)
{
   if(g_shadow_mode)return;
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
   if(g_shadow_mode)return;
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
void BxClear(){if(g_shadow_mode){g_shd_cnt=0;return;}g_bx_cnt=0;}

void BxDeleteAll()
{
   for(int k=0;k<g_bx_cnt;k++){
      if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectDelete(0,g_bx_nm[k]);
      if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectDelete(0,g_bx_wk_abv_nm[k]);
      if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectDelete(0,g_bx_wk_blw_nm[k]);
   }
   g_bx_cnt=0;
}

void BxAdd(string nm,string wk_abv,string wk_blw,double top,double bot)
{
   if(g_shadow_mode){
      if(g_shd_cnt>=SHD_BOX_MAX)return;
      g_shd_state[g_shd_cnt]=2;g_shd_top[g_shd_cnt]=top;g_shd_bot[g_shd_cnt]=bot;
      g_shd_touch[g_shd_cnt]=0;g_shd_appr[g_shd_cnt]=0;g_shd_cnt_in[g_shd_cnt]=0;
      g_shd_ev_t[g_shd_cnt]=0;g_shd_break_up[g_shd_cnt]=0;g_shd_break_dn[g_shd_cnt]=0;
      g_shd_cnt++;return;
   }
   if(g_bx_cnt>=BOX_MAX)return;
   g_bx_nm[g_bx_cnt]=nm;g_bx_wk_abv_nm[g_bx_cnt]=wk_abv;g_bx_wk_blw_nm[g_bx_cnt]=wk_blw;
   g_bx_top[g_bx_cnt]=top;g_bx_bot[g_bx_cnt]=bot;
   g_bx_state[g_bx_cnt]=2;g_bx_touch_state[g_bx_cnt]=0;g_bx_approach[g_bx_cnt]=0;
   g_bx_inside_cnt[g_bx_cnt]=0;g_bx_event_time[g_bx_cnt]=0;
   g_bx_break_up[g_bx_cnt]=0;g_bx_break_dn[g_bx_cnt]=0;
   g_bx_notified[g_bx_cnt]=false;
   g_bx_cnt++;
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
         if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectSetInteger(0,g_bx_nm[k],       OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,t);
         g_bx_state[k]=0;
      }
      else if(g_bx_state[k]==2)g_bx_state[k]=1;
   }
}

void ShdBxUpdateStats(double h,double l,double c,double prev_c,datetime bar_time)
{
   for(int k=0;k<g_shd_cnt;k++){
      if(g_shd_state[k]==0)continue;
      double top=g_shd_top[k],bot=g_shd_bot[k];
      bool im=(h>=bot)&&(l<=top);
      int na;if(prev_c>top)na=1;else if(prev_c<bot)na=-1;else na=g_shd_appr[k];
      int ts=g_shd_touch[k];
      if(ts==0){if(im){g_shd_appr[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_shd_touch[k]=1;g_shd_cnt_in[k]=1;g_shd_ev_t[k]=bar_time;}}
      else if(ts==1){
         if(im){g_shd_cnt_in[k]++;g_shd_ev_t[k]=bar_time;}
         else{bool bd=(c<bot),bu=(c>top);int ap=g_shd_appr[k];
            if(ap==1){if(bd){g_shd_touch[k]=2;g_shd_break_dn[k]++;}else if(bu)g_shd_touch[k]=3;}
            else{if(bu){g_shd_touch[k]=2;g_shd_break_up[k]++;}else if(bd)g_shd_touch[k]=3;}
            g_shd_ev_t[k]=bar_time;}
      }
      else{if(im){g_shd_appr[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_shd_touch[k]=1;g_shd_cnt_in[k]=1;g_shd_ev_t[k]=bar_time;}}
   }
}

void BxUpdateStats(double h,double l,double c,double prev_c,datetime bar_time)
{
   if(g_shadow_mode){ShdBxUpdateStats(h,l,c,prev_c,bar_time);return;}
   for(int k=0;k<g_bx_cnt;k++){
      if(g_bx_state[k]==0)continue;
      double top=g_bx_top[k],bot=g_bx_bot[k];
      bool im=(h>=bot)&&(l<=top);
      int na;if(prev_c>top)na=1;else if(prev_c<bot)na=-1;else na=g_bx_approach[k];
      int ts=g_bx_touch_state[k];
      if(ts==0){
         if(im){
            int appr=(na!=0)?na:(c>(top+bot)/2.0?1:-1);
            g_bx_approach[k]=appr;g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;
            // --- KUTU TEMAS BİLDİRİMİ ---
            if(g_live_bar_processing&&!g_bx_notified[k]){
               g_bx_notified[k]=true;
               string tf_lbl=EnumToString(Period());StringReplace(tf_lbl,"PERIOD_","");
               string yon_emoji=(appr==1)?"🔴":"🟢";
               string yon_lbl =(appr==1)?"Yukaridan -> SELL Bolgesi":"Asagidan -> BUY Bolgesi";
               string sep="━━━━━━━━━━━━━━━━━━";
               string msg=StringFormat(
                  "📦 %s %s Kutu Temas!\n"
                  "⏰ %s\n"
                  "%s %s\n"
                  "📍 Ust: %s\n"
                  "📍 Alt: %s\n"
                  "%s",
                  Symbol(),tf_lbl,
                  TimeToString(bar_time,TIME_DATE|TIME_MINUTES),
                  yon_emoji,yon_lbl,
                  DoubleToString(top,_Digits),
                  DoubleToString(bot,_Digits),
                  sep);
               Print(msg);
               if(InpAlertPush)SendNotification(msg);
               if(InpAlertPopup)Alert(msg);
            }
         }
      }
      else if(ts==1){
         if(im){g_bx_inside_cnt[k]++;g_bx_event_time[k]=bar_time;}
         else{bool bd=(c<bot),bu=(c>top);int ap=g_bx_approach[k];
            if(ap==1){if(bd){g_bx_touch_state[k]=2;g_bx_break_dn[k]++;}else if(bu)g_bx_touch_state[k]=3;}
            else{if(bu){g_bx_touch_state[k]=2;g_bx_break_up[k]++;}else if(bd)g_bx_touch_state[k]=3;}
            g_bx_event_time[k]=bar_time;}
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
   int    anc_i;double anc_v;int bos_i;
   string cur_top_line,cur_bot_line;
   double mb_h,mb_l;int mb_i;
   double t1_h,t1_l;int t1_i;
   double d1_h,d1_l;int d1_i;
   double t2_h,t2_l;int t2_i;
   int    choch_dir;
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
      bx_phase=s.bx_phase;bx_extreme=s.bx_extreme;bx_swing_h=s.bx_swing_h;bx_swing_l=s.bx_swing_l;
      has_pot_bull_minor=s.has_pot_bull_minor;pot_bull_start_i=s.pot_bull_start_i;
      pot_bull_start_p=s.pot_bull_start_p;pot_bull_end_p=s.pot_bull_end_p;
      has_pot_bear_minor=s.has_pot_bear_minor;pot_bear_start_i=s.pot_bear_start_i;
      pot_bear_start_p=s.pot_bear_start_p;pot_bear_end_p=s.pot_bear_end_p;
      st_h.CopyFrom(s.st_h);st_l.CopyFrom(s.st_l);}
};

SState g_state_hist,g_state_curr;
void BxReset(SState &s,double rl,double rh){s.bx_phase=0;s.bx_extreme=false;s.bx_swing_l=rl;s.bx_swing_h=rh;}

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
   BxAdd(nm,wk_abv,wk_blw,top,bot);
}

//=====================================================================
// MTF — Shadow Analiz
//=====================================================================
void ProcessBar(int i,const double &open[],const double &high[],const double &low[],
                const double &close[],const datetime &time[],SState &state,bool is_history);

bool AnalyzeTFBoxResult(ENUM_TIMEFRAMES tf,double days_inp,TFBoxResult &res)
{
   res.tf=tf;res.has_box=false;res.touch_state=0;res.approach=0;
   res.cnt_in=0;res.ev_t=0;res.break_up=0;res.break_dn=0;res.box_top=0;res.box_bot=0;

   MqlRates r[];
   datetime anc=TimeCurrent()-(datetime)(days_inp*86400.0);
   int n=CopyRates(Symbol(),tf,anc,TimeCurrent(),r);
   if(n<5)return false;

   double o[],h[],l[],c[];datetime t[];
   ArrayResize(o,n);ArrayResize(h,n);ArrayResize(l,n);ArrayResize(c,n);ArrayResize(t,n);
   for(int j=0;j<n;j++){o[j]=r[j].open;h[j]=r[j].high;l[j]=r[j].low;c[j]=r[j].close;t[j]=r[j].time;}

   g_shadow_mode=true;g_shd_cnt=0;
   SState st;int si=0;
   st.min_h=h[si];st.min_h_i=si;st.min_l=l[si];st.min_l_i=si;
   st.trig_h=h[si];st.trig_l=l[si];st.tmp_h=h[si];st.tmp_h_i=si;
   st.tmp_l=l[si];st.tmp_l_i=si;st.min_tr=(c[si]>o[si])?1:-1;
   st.anc_i=si;st.anc_v=c[si];st.lp_i=si;st.lp_p=c[si];st.bos_i=si;
   st.maj_h_i=si;st.maj_l_i=si;st.mb_h=h[si];st.mb_l=l[si];st.mb_i=si;
   st.t1_h=0;st.t1_l=0;st.t1_i=0;st.d1_h=0;st.d1_l=0;st.d1_i=0;
   st.t2_h=0;st.t2_l=0;st.t2_i=0;st.choch_dir=0;
   double ig=h[si]-l[si];if(ig==0)ig=Point()*10;
   st.maj_h=h[si]+ig*0.1;st.maj_l=l[si]-ig*0.1;st.maj_tr=st.min_tr;st.maj_st=1;
   st.cur_top_line="";st.cur_bot_line="";st.st_h.Clear();st.st_l.Clear();
   BxReset(st,l[si],h[si]);
   st.has_pot_bull_minor=false;st.has_pot_bear_minor=false;
   st.pot_bull_start_i=0;st.pot_bull_start_p=0;st.pot_bull_end_p=0;
   st.pot_bear_start_i=0;st.pot_bear_start_p=0;st.pot_bear_end_p=0;

   for(int i=si+1;i<n-1;i++){
      bool inside=(h[i]<=st.mb_h)&&(l[i]>=st.mb_l);
      if(!inside){if(h[i]>st.mb_h||l[i]<st.mb_l){st.mb_h=h[i];st.mb_l=l[i];st.mb_i=i;}ProcessBar(i,o,h,l,c,t,st,true);}
      else{double pc=(i>0)?c[i-1]:c[i];BxUpdateStats(h[i],l[i],c[i],pc,t[i]);}
   }
   int li=n-1;SState sc;sc.CopyFrom(st);
   bool il=(h[li]<=sc.mb_h)&&(l[li]>=sc.mb_l);
   if(!il)ProcessBar(li,o,h,l,c,t,sc,true);
   else{double pc=(li>0)?c[li-1]:c[li];BxUpdateStats(h[li],l[li],c[li],pc,t[li]);}
   g_shadow_mode=false;

   int bk=-1;datetime bt=0;
   for(int k=0;k<g_shd_cnt;k++){if(g_shd_state[k]==0)continue;if(g_shd_touch[k]>0&&g_shd_ev_t[k]>bt){bt=g_shd_ev_t[k];bk=k;}}
   if(bk<0){for(int k=g_shd_cnt-1;k>=0;k--){if(g_shd_state[k]>0){bk=k;break;}}}
   if(bk<0)return false;

   res.has_box=true;res.touch_state=g_shd_touch[bk];res.approach=g_shd_appr[bk];
   res.cnt_in=g_shd_cnt_in[bk];res.ev_t=g_shd_ev_t[bk];
   res.break_up=g_shd_break_up[bk];res.break_dn=g_shd_break_dn[bk];
   res.box_top=g_shd_top[bk];res.box_bot=g_shd_bot[bk];
   return true;
}

//=====================================================================
// Bildirim
//=====================================================================
string BuildRowStr(int num,ENUM_TIMEFRAMES tf,const TFBoxResult &res,bool enabled,
                   int choch_dir,bool &appr_out,bool &gec_out)
{
   string tf_lbl=EnumToString(tf);StringReplace(tf_lbl,"PERIOD_","");
   appr_out=false;gec_out=false;
   if(!enabled){gec_out=true;return StringFormat("%d. %-4s ➖  Devre Disi\n",num,tf_lbl);}
   bool gec=IsGecersiz(res.touch_state,res.cnt_in,res.ev_t,tf);
   bool yat=IsYatay(res.touch_state,res.break_up,res.break_dn);
   bool appr=(!gec&&!yat)&&IsApproved(choch_dir,res.touch_state,res.approach,res.break_up,res.break_dn);
   gec_out=gec;appr_out=appr;
   string emoji;
   if(gec)emoji="⚫";else if(yat)emoji="🟡";else if(appr)emoji="🟢";else emoji="🔴";
   string time_str;
   if(gec)time_str="25+ mum     ";
   else if(res.touch_state==1)time_str=StringFormat("%d mum icinde",res.cnt_in);
   else{int ps=PeriodSeconds(tf);int mu=(ps>0)?(int)((TimeCurrent()-res.ev_t)/ps):0;time_str=StringFormat("%d mum once  ",mu);}
   string status;
   if(gec)status="Gecersiz";
   else if(yat)status=StringFormat("YATAY(U:%d A:%d)",res.break_up,res.break_dn);
   else status=GetBoxStatusShort(res.touch_state,res.approach,res.break_up,res.break_dn);
   return StringFormat("%d. %-4s %s  %-14s  %s\n",num,tf_lbl,emoji,time_str,status);
}

void SendChochNotif(int choch_dir,bool is_strong,double pb_pct,
                    datetime choch_time,ENUM_TIMEFRAMES signal_tf,int tdx)
{
   string ds=(choch_dir==-1)?"SELL":"BUY";
   string edir=(choch_dir==-1)?"🔴":"🟢";
   string str=is_strong?"GUCLU":"ZAYIF";
   string tf_lbl=EnumToString(signal_tf);StringReplace(tf_lbl,"PERIOD_","");
   string sep="━━━━━━━━━━━━━━━━━━";
   string header=StringFormat("🚨 %s %s | %s %s #%d | %s %%%d\n⏰ %s\n%s",
      Symbol(),tf_lbl,edir,ds,tdx+1,str,(int)MathRound(pb_pct),
      TimeToString(choch_time,TIME_DATE|TIME_MINUTES),sep);

   TFBoxResult m1_res;
   AnalyzeTFBoxResult(PERIOD_M1,InpDaysM1,m1_res);
   bool m1_gec=IsGecersiz(m1_res.touch_state,m1_res.cnt_in,m1_res.ev_t,PERIOD_M1);
   bool m1_yat=IsYatay(m1_res.touch_state,m1_res.break_up,m1_res.break_dn);
   bool m1_appr=(!m1_gec&&!m1_yat)&&IsApproved(choch_dir,m1_res.touch_state,m1_res.approach,m1_res.break_up,m1_res.break_dn);
   string m1_status,m1_emoji;
   if(m1_gec){m1_status="Temas Yok / Gecersiz";m1_emoji="⚫";}
   else if(m1_yat){m1_status="YATAY";m1_emoji="🟡";}
   else if(m1_appr){m1_status=GetBoxStatusShort(m1_res.touch_state,m1_res.approach,m1_res.break_up,m1_res.break_dn);m1_emoji="✅";}
   else{m1_status=GetBoxStatusShort(m1_res.touch_state,m1_res.approach,m1_res.break_up,m1_res.break_dn);m1_emoji="❌";}
   string m1_line=StringFormat("📍 M1 → %s %s",m1_status,m1_emoji);
   if(!m1_appr){
      if(InpNotifInvalid){string msg=header+"\n"+m1_line+"\n"+sep+"\n❌ M1 Desteklemiyor → Islem Yok";Print(msg);if(InpAlertPopup)Alert(msg);if(InpAlertPush)SendNotification(msg);}
      return;
   }
   double locked_top=(choch_dir==-1)?g_m1_sell_locked_top:g_m1_buy_locked_top;
   double locked_bot=(choch_dir==-1)?g_m1_sell_locked_bot:g_m1_buy_locked_bot;
   bool same_box=(locked_top!=0&&MathAbs(m1_res.box_top-locked_top)<Point()*10&&MathAbs(m1_res.box_bot-locked_bot)<Point()*10);
   if(same_box){
      if(InpNotifInvalid){string msg=header+"\n📍 M1 → Kutu Kilitli 🔒\n"+sep+"\n🔕 Onceki Kutu Kullanımda → Islem Yok";Print(msg);if(InpAlertPopup)Alert(msg);if(InpAlertPush)SendNotification(msg);}
      return;
   }
   m1_line=StringFormat("📍 M1 → %s %s (Yeni Kutu)",m1_status,m1_emoji);
   ENUM_TIMEFRAMES tfs[CASCADE_TF_COUNT]={PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H4,PERIOD_D1};
   double days[CASCADE_TF_COUNT]={InpDaysM15,InpDaysM30,InpDaysH1,InpDaysH4,InpDaysD1};
   bool ena[CASCADE_TF_COUNT]={InpEnableM15,InpEnableM30,InpEnableH1,InpEnableH4,InpEnableD1};
   TFBoxResult results[CASCADE_TF_COUNT];bool row_appr[CASCADE_TF_COUNT];bool row_gec[CASCADE_TF_COUNT];
   string rows="";
   for(int i=0;i<CASCADE_TF_COUNT;i++){
      if(ena[i])AnalyzeTFBoxResult(tfs[i],days[i],results[i]);
      else{results[i].tf=tfs[i];results[i].has_box=false;results[i].touch_state=0;}
      results[i].tf=tfs[i];
      rows+=BuildRowStr(i+1,tfs[i],results[i],ena[i],choch_dir,row_appr[i],row_gec[i]);
   }
   bool trade_ok=false;string trade_reason="Islem Yok";
   if(!row_gec[0]){
      if(row_appr[0]){trade_ok=true;trade_reason="✅ 1. Guncelse & Onayli → GIR!";}
      else{trade_reason="❌ 1. Onaylamadi → Islem Yok";}
   }else{
      int t2_gec=0,t2_appr=0;string appr_list="";
      for(int i=1;i<=3;i++){
         if(row_gec[i])t2_gec++;
         else if(row_appr[i]){t2_appr++;if(appr_list!="")appr_list+="+";appr_list+=IntegerToString(i+1)+".";}
      }
      if(t2_gec>=2)trade_reason="❌ 2+ Gecersiz → Islem Yok";
      else if(t2_appr>=2){trade_ok=true;trade_reason="✅ "+appr_list+" Onayli → GIR!";}
      else trade_reason="❌ Yeterli Onay Yok → Islem Yok";
   }
   string msg=header+"\n"+m1_line+"\n"+sep+"\n"+rows+sep+"\n>>> "+trade_reason;
   Print(msg);if(InpAlertPopup)Alert(msg);if(InpAlertPush)SendNotification(msg);
   if(trade_ok){
      if(choch_dir==-1){g_m1_sell_locked_top=m1_res.box_top;g_m1_sell_locked_bot=m1_res.box_bot;}
      else             {g_m1_buy_locked_top =m1_res.box_top;g_m1_buy_locked_bot =m1_res.box_bot;}
   }
}

//=====================================================================
// ProcessBar  (BT koleksiyonu eklendi — *** BT *** etiketli bölümler)
//=====================================================================
void ProcessBar(int i,const double &open[],const double &high[],const double &low[],
                const double &close[],const datetime &time[],SState &state,bool is_history)
{
   double val_h=high[i],val_l=low[i],val_c=close[i];
   string pfx=is_history?"":"Live_";
   double prev_c=(i>0)?close[i-1]:close[i];
   BxUpdateStats(val_h,val_l,val_c,prev_c,time[i]);

   double p_pct=0;
   if(state.maj_h!=EMPTY_VALUE&&state.maj_l!=EMPTY_VALUE&&state.maj_h!=state.maj_l){
      double rng=state.maj_h-state.maj_l;
      if(state.maj_tr== 1&&val_l>=state.maj_l)p_pct=((state.maj_h-val_l)/rng)*100.0;
      if(state.maj_tr==-1&&val_h<=state.maj_h)p_pct=((val_h-state.maj_l)/rng)*100.0;
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
         if(!g_shadow_mode&&!is_history){
            static int ld1b=-1;
            int max_t=MathMin(InpMaxTrades,TRADE_MAX);
            if(state.maj_h_i!=g_current_maj_h_i){ResetBearishMemory();g_current_maj_h_i=state.maj_h_i;ld1b=-1;}
            bool isn=(state.d1_i!=ld1b);
            int tdx=-1; bool vs=false;
            if(isn){
               if(g_trade_count_h==0)vs=true;
               else if(g_trade_count_h<max_t){double pv=MathMax(g_trade_t1_h[g_trade_count_h-1],g_trade_t2_h[g_trade_count_h-1]);if(state.t2_h>pv)vs=true;}
               if(vs&&g_trade_count_h<max_t){tdx=g_trade_count_h;g_trade_t1_h[tdx]=state.t1_h;g_trade_t2_h[tdx]=state.t2_h;g_trade_count_h++;}
            }else{for(int x=0;x<g_trade_count_h;x++)if(g_trade_t1_h[x]==state.t1_h&&g_trade_t2_h[x]==state.t2_h){tdx=x;break;}}
            if(isn)ld1b=state.d1_i;
            // SL/TP kutusu + bildirim: sadece gecerli islem (vs=yeni, tdx>=0=onceden onaylanmis)
            if(InpShowBT&&(vs||tdx>=0)){
               double sw=state.maj_h-state.maj_l;
               if(sw>0){
                  double sd=sw*InpBTSLPct/100.0;
                  double rr=MathMax(InpBTRR,1.1);
                  double entry=state.d1_l;
                  double sl   =entry+sd;
                  double tp_main=entry-rr*sd;
                  double tp_alt =entry-2.0*sd;
                  bool   use2r  =(tp_main<state.maj_l);
                  double tp     =use2r?tp_alt:tp_main;
                  datetime t1=time[i];
                  datetime t2=t1+(datetime)(PeriodSeconds()*InpBTMaxBars);
                  DrawRect("Live_BT_SL",   t1,sl,   t2,entry,C'160,30,30');
                  DrawRect("Live_BT_TP",   t1,entry, t2,tp,   C'30,160,30');
                  DrawLine("Live_BT_Entry",t1,entry,    t2,entry,clrOrange,1,STYLE_DASH);
                  if(vs&&state.d1_i!=g_last_sltp_d1i_sell){
                     g_last_sltp_d1i_sell=state.d1_i;
                     string tf_lbl=EnumToString(Period());StringReplace(tf_lbl,"PERIOD_","");
                     double pip=Point()*((Digits()==3||Digits()==5)?10:1);
                     int sl_pip=(int)MathRound((sl-entry)/pip);
                     int tp_pip=(int)MathRound((entry-tp)/pip);
                     string sep="━━━━━━━━━━━━━━━━━━";
                     string msg=StringFormat(
                        "🔴 %s %s  SELL\n⏰ %s\n%s\n"
                        "📍 Giris : %s\n"
                        "🛑 SL    : %s  (%d pip)\n"
                        "🎯 TP    : %s  (%d pip)  %s\n%s",
                        Symbol(),tf_lbl,TimeToString(t1,TIME_DATE|TIME_MINUTES),sep,
                        DoubleToString(entry,_Digits),
                        DoubleToString(sl,_Digits),sl_pip,
                        DoubleToString(tp,_Digits),tp_pip,
                        use2r?"2R":"3R",sep);
                     Print(msg);
                     if(InpAlertPush)SendNotification(msg);
                     if(InpAlertPopup)Alert(msg);
                     WriteBTSignal(-1,entry,sl,tp);
                  }
               }
            }
         }
         if(is_history&&g_bt_mode&&!g_shadow_mode&&g_bt_cnt<BT_MAX){
            double sw=state.maj_h-state.maj_l;
            if(sw>0){
               double sd=sw*InpBTSLPct/100.0;
               double rr=MathMax(InpBTRR,1.1);
               g_bt[g_bt_cnt].dir      =-1;
               g_bt[g_bt_cnt].bar_i    =i;
               g_bt[g_bt_cnt].outcome_i=i;
               g_bt[g_bt_cnt].entry    =state.d1_l;
               g_bt[g_bt_cnt].sl       =state.d1_l+sd;
               double tp_main=state.d1_l-rr*sd;
               double tp_alt =state.d1_l-2.0*sd;
               g_bt[g_bt_cnt].use_2r   =(tp_main<state.maj_l);
               g_bt[g_bt_cnt].tp       =g_bt[g_bt_cnt].use_2r?tp_alt:tp_main;
               g_bt[g_bt_cnt].maj_h    =state.maj_h;
               g_bt[g_bt_cnt].maj_l    =state.maj_l;
               g_bt[g_bt_cnt].outcome  =0;
               g_bt[g_bt_cnt].is_strong=is_strong;
               g_bt[g_bt_cnt].time_open=time[i];
               g_bt_cnt++;
            }
         }
         // *** BT end ***
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
         if(!g_shadow_mode&&!is_history){
            static int ld1l=-1;
            int max_t=MathMin(InpMaxTrades,TRADE_MAX);
            if(state.maj_l_i!=g_current_maj_l_i){ResetBullishMemory();g_current_maj_l_i=state.maj_l_i;ld1l=-1;}
            bool isn=(state.d1_i!=ld1l);
            int tdx=-1; bool vs=false;
            if(isn){
               if(g_trade_count_l==0)vs=true;
               else if(g_trade_count_l<max_t){double pv=MathMin(g_trade_t1_l[g_trade_count_l-1],g_trade_t2_l[g_trade_count_l-1]);if(state.t2_l<pv)vs=true;}
               if(vs&&g_trade_count_l<max_t){tdx=g_trade_count_l;g_trade_t1_l[tdx]=state.t1_l;g_trade_t2_l[tdx]=state.t2_l;g_trade_count_l++;}
            }else{for(int x=0;x<g_trade_count_l;x++)if(g_trade_t1_l[x]==state.t1_l&&g_trade_t2_l[x]==state.t2_l){tdx=x;break;}}
            if(isn)ld1l=state.d1_i;
            // SL/TP kutusu + bildirim: sadece gecerli islem
            if(InpShowBT&&(vs||tdx>=0)){
               double sw=state.maj_h-state.maj_l;
               if(sw>0){
                  double sd=sw*InpBTSLPct/100.0;
                  double rr=MathMax(InpBTRR,1.1);
                  double entry=state.d1_h;
                  double sl   =entry-sd;
                  double tp_main=entry+rr*sd;
                  double tp_alt =entry+2.0*sd;
                  bool   use2r  =(tp_main>state.maj_h);
                  double tp     =use2r?tp_alt:tp_main;
                  datetime t1=time[i];
                  datetime t2=t1+(datetime)(PeriodSeconds()*InpBTMaxBars);
                  DrawRect("Live_BT_SL",   t1,entry,t2,sl,   C'160,30,30');
                  DrawRect("Live_BT_TP",   t1,tp,   t2,entry,C'30,160,30');
                  DrawLine("Live_BT_Entry",t1,entry,    t2,entry,clrOrange,1,STYLE_DASH);
                  if(vs&&state.d1_i!=g_last_sltp_d1i_buy){
                     g_last_sltp_d1i_buy=state.d1_i;
                     string tf_lbl=EnumToString(Period());StringReplace(tf_lbl,"PERIOD_","");
                     double pip=Point()*((Digits()==3||Digits()==5)?10:1);
                     int sl_pip=(int)MathRound((entry-sl)/pip);
                     int tp_pip=(int)MathRound((tp-entry)/pip);
                     string sep="━━━━━━━━━━━━━━━━━━";
                     string msg=StringFormat(
                        "🟢 %s %s  BUY\n⏰ %s\n%s\n"
                        "📍 Giris : %s\n"
                        "🛑 SL    : %s  (%d pip)\n"
                        "🎯 TP    : %s  (%d pip)  %s\n%s",
                        Symbol(),tf_lbl,TimeToString(t1,TIME_DATE|TIME_MINUTES),sep,
                        DoubleToString(entry,_Digits),
                        DoubleToString(sl,_Digits),sl_pip,
                        DoubleToString(tp,_Digits),tp_pip,
                        use2r?"2R":"3R",sep);
                     Print(msg);
                     if(InpAlertPush)SendNotification(msg);
                     if(InpAlertPopup)Alert(msg);
                     WriteBTSignal(1,entry,sl,tp);
                  }
               }
            }
         }
         if(is_history&&g_bt_mode&&!g_shadow_mode&&g_bt_cnt<BT_MAX){
            double sw=state.maj_h-state.maj_l;
            if(sw>0){
               double sd=sw*InpBTSLPct/100.0;
               double rr=MathMax(InpBTRR,1.1);
               g_bt[g_bt_cnt].dir      =1;
               g_bt[g_bt_cnt].bar_i    =i;
               g_bt[g_bt_cnt].outcome_i=i;
               g_bt[g_bt_cnt].entry    =state.d1_h;
               g_bt[g_bt_cnt].sl       =state.d1_h-sd;
               double tp_main=state.d1_h+rr*sd;
               double tp_alt =state.d1_h+2.0*sd;
               g_bt[g_bt_cnt].use_2r   =(tp_main>state.maj_h);
               g_bt[g_bt_cnt].tp       =g_bt[g_bt_cnt].use_2r?tp_alt:tp_main;
               g_bt[g_bt_cnt].maj_h    =state.maj_h;
               g_bt[g_bt_cnt].maj_l    =state.maj_l;
               g_bt[g_bt_cnt].outcome  =0;
               g_bt[g_bt_cnt].is_strong=is_strong;
               g_bt[g_bt_cnt].time_open=time[i];
               g_bt_cnt++;
            }
         }
         // *** BT end ***
         state.choch_dir=0;
      }
   }

   //--- MAJÖR YAPI (orijinalin aynısı)
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
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l){
            BxAdvanceTrim(GetTimeSafe(time,state.tmp_h_i));state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            if(is_history&&state.has_pot_bear_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
            BxReset(state,val_l,state.tmp_h);state.has_pot_bear_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }else if(state.maj_st==1){
         if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
         if(state.maj_h!=EMPTY_VALUE&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         if(val_c>state.maj_h){
            state.bos_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_l_i),state.maj_l,InpColorBull,2,STYLE_SOLID);
            state.st_h.Clear();state.maj_st=0;state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            BxReset(state,state.maj_l,val_h);
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l){
            BxAdvanceTrim(GetTimeSafe(time,state.tmp_h_i));state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            if(is_history&&state.has_pot_bear_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
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
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h){
            BxAdvanceTrim(GetTimeSafe(time,state.tmp_l_i));state.maj_tr=1;state.maj_st=0;state.bos_i=i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(is_history&&state.has_pot_bull_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
            BxReset(state,state.tmp_l,val_h);state.has_pot_bull_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }else if(state.maj_st==1){
         if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
         if(state.maj_l!=EMPTY_VALUE&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(InpShowMaj)UpdateLineLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&val_c<state.maj_l){
            state.maj_h=state.tmp_h;state.bos_i=i;state.maj_h_i=state.tmp_h_i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.maj_h_i),state.maj_h,InpColorBear,2,STYLE_SOLID);
            state.st_l.Clear();state.maj_st=0;state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            BxReset(state,val_l,state.maj_h);
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(InpShowMaj)UpdateLineLevel(state.cur_top_line,state.maj_h);}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h){
            BxAdvanceTrim(GetTimeSafe(time,state.tmp_l_i));state.maj_tr=1;state.maj_st=0;state.bos_i=i;
            if(InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),GetTimeSafe(time,state.anc_i),state.anc_v,GetTimeSafe(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(is_history&&state.has_pot_bull_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
            BxReset(state,state.tmp_l,val_h);state.has_pot_bull_minor=false;
            CutLine(state.cur_top_line,GetTimeSafe(time,i));CutLine(state.cur_bot_line,GetTimeSafe(time,i));state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }
}

//=====================================================================
// *** BT FONKSİYONLARI ***
//=====================================================================

//--- O anki aktif kutulardan herhangi biri price seviyesini kapsıyor mu?
bool BxHasActiveAtLevel(double price)
{
   for(int k=0;k<g_bx_cnt;k++){
      if(g_bx_state[k]==0)continue;
      if(price>=g_bx_bot[k]&&price<=g_bx_top[k])return true;
   }
   return false;
}

//--- Dolar risk miktarina gore lot hesapla
double CalcLot(string sym,double entry,double sl)
{
   double sl_dist=MathAbs(entry-sl);
   if(sl_dist<=0)return SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
   double tick_sz =SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_SIZE);
   double tick_val=SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_VALUE);
   if(tick_sz<=0||tick_val<=0)return SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
   double risk_per_lot=(sl_dist/tick_sz)*tick_val;
   if(risk_per_lot<=0)return SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
   double lot=InpRiskUSD/risk_per_lot;
   double step=SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP);
   double vmin=SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
   double vmax=SymbolInfoDouble(sym,SYMBOL_VOLUME_MAX);
   lot=MathFloor(lot/step)*step;
   return MathMax(MathMin(lot,vmax),vmin);
}

//--- Common klasorune sinyal dosyasi yaz (slave EA okur)
void WriteBTSignal(int dir,double entry,double sl,double tp)
{
   double lot=InpTestMode?InpTestLot:CalcLot(Symbol(),entry,sl);
   string fname="CHoCH_Trade_Signal.csv";
   int fh=FileOpen(fname,FILE_WRITE|FILE_COMMON|FILE_CSV|FILE_ANSI,';');
   if(fh==INVALID_HANDLE){Print("Signal dosyasi yazilamadi: ",GetLastError());return;}
   FileWrite(fh,Symbol(),IntegerToString(dir),
             DoubleToString(entry,8),
             DoubleToString(sl,8),
             DoubleToString(tp,8),
             DoubleToString(lot,3),
             IntegerToString((long)TimeCurrent()));
   FileClose(fh);
   Print(">>> Signal yazildi: ",(dir==-1?"SELL":"BUY"),
         (InpTestMode?" [TEST 0.01 lot]":""),
         " Lot:",DoubleToString(lot,3),
         " SL:",DoubleToString(sl,_Digits),
         " TP:",DoubleToString(tp,_Digits));
}

//--- Swing basi max 2 sinyal filtresi + sonuc taramasi
void EvaluateBT(const double &high[],const double &low[],
                const datetime &time[],int rates_total)
{
   // Gecis 1: ayni swing icerisinde 3.+ sinyal → skip=true
   double tol=Point()*20;
   for(int s=0;s<g_bt_cnt;s++){
      g_bt[s].skip=false;
      int count=0;
      for(int p=0;p<s;p++){
         if(g_bt[p].skip)continue;
         if(g_bt[p].dir==g_bt[s].dir &&
            MathAbs(g_bt[p].maj_h-g_bt[s].maj_h)<tol &&
            MathAbs(g_bt[p].maj_l-g_bt[s].maj_l)<tol)
            count++;
      }
      if(count>=2)g_bt[s].skip=true;
   }

   // Gecis 2: skip olmayanlarda SL/TP taramasi
   for(int s=0;s<g_bt_cnt;s++){
      if(g_bt[s].skip)continue;
      if(g_bt[s].outcome!=0)continue;
      int end_i=MathMin(g_bt[s].bar_i+InpBTMaxBars,rates_total-2);
      for(int j=g_bt[s].bar_i+1;j<=end_i;j++){
         if(g_bt[s].dir==-1){
            if(high[j]>=g_bt[s].sl){g_bt[s].outcome=-1;g_bt[s].outcome_i=j;break;}
            if(low[j] <=g_bt[s].tp){g_bt[s].outcome= 1;g_bt[s].outcome_i=j;break;}
         }else{
            if(low[j] <=g_bt[s].sl){g_bt[s].outcome=-1;g_bt[s].outcome_i=j;break;}
            if(high[j]>=g_bt[s].tp){g_bt[s].outcome= 1;g_bt[s].outcome_i=j;break;}
         }
      }
      if(g_bt[s].outcome==0)
         g_bt[s].outcome_i=MathMin(g_bt[s].bar_i+InpBTMaxBars,rates_total-2);
   }
}

//--- SL (kırmızı) ve TP (yeşil) kutularını çiz
void DrawBTResults(const datetime &time[],int rates_total)
{
   ObjectsDeleteAll(0,"BT_SL_");
   ObjectsDeleteAll(0,"BT_TP_");
   ObjectsDeleteAll(0,"BT_LBL_");
   if(!InpShowBT||g_bt_cnt==0)return;

   int ps=PeriodSeconds();
   for(int s=0;s<g_bt_cnt;s++){
      if(g_bt[s].skip)continue;                         // max 2/swing filtresi
      if(g_bt[s].bar_i>=rates_total)continue;

      datetime t1=time[g_bt[s].bar_i];
      int oi=(g_bt[s].outcome_i<rates_total)?g_bt[s].outcome_i:(rates_total-1);
      datetime t2=time[oi]+(datetime)(ps*3);

      string sl_nm ="BT_SL_" +IntegerToString(s);
      string tp_nm ="BT_TP_" +IntegerToString(s);
      string lbl_nm="BT_LBL_"+IntegerToString(s);

      //--- SL kutu rengi
      color sl_clr;
      if(g_bt[s].outcome==-1)     sl_clr=C'210,30,30';
      else if(g_bt[s].outcome==1) sl_clr=C'60,10,10';
      else                        sl_clr=C'130,25,25';

      //--- TP kutu rengi
      color tp_clr;
      if(g_bt[s].outcome==1)       tp_clr=C'30,210,30';
      else if(g_bt[s].outcome==-1) tp_clr=C'10,60,10';
      else                         tp_clr=C'25,130,25';

      //--- SL kutusu: entry → sl arası risk bölgesi
      if(g_bt[s].dir==-1)
         DrawRect(sl_nm,t1,g_bt[s].sl,   t2,g_bt[s].entry,sl_clr);
      else
         DrawRect(sl_nm,t1,g_bt[s].entry,t2,g_bt[s].sl,   sl_clr);

      //--- TP kutusu: entry → tp arası hedef bölgesi
      if(g_bt[s].dir==-1)
         DrawRect(tp_nm,t1,g_bt[s].entry,t2,g_bt[s].tp,   tp_clr);
      else
         DrawRect(tp_nm,t1,g_bt[s].tp,   t2,g_bt[s].entry,tp_clr);

      //--- Etiket: TP seviyesinde W/L/? yaz
      string lbl_txt; color lbl_clr;
      if     (g_bt[s].outcome== 1){lbl_txt=(g_bt[s].use_2r?"W2R":"W3R");lbl_clr=clrLime;}
      else if(g_bt[s].outcome==-1){lbl_txt="L";                          lbl_clr=clrRed;}
      else                        {lbl_txt="?";                          lbl_clr=clrGray;}

      if(ObjectFind(0,lbl_nm)<0)
         ObjectCreate(0,lbl_nm,OBJ_TEXT,0,t1,g_bt[s].tp);
      ObjectSetInteger(0,lbl_nm,OBJPROP_TIME,     t1);
      ObjectSetDouble (0,lbl_nm,OBJPROP_PRICE,    g_bt[s].tp);
      ObjectSetString (0,lbl_nm,OBJPROP_TEXT,     lbl_txt);
      ObjectSetInteger(0,lbl_nm,OBJPROP_COLOR,    lbl_clr);
      ObjectSetInteger(0,lbl_nm,OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0,lbl_nm,OBJPROP_ANCHOR,   ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0,lbl_nm,OBJPROP_HIDDEN,   true);
      ObjectSetInteger(0,lbl_nm,OBJPROP_SELECTABLE,false);
   }
}

//--- Kompakt panel - sag ust kose
void DrawBTPanel()
{
   ObjectsDeleteAll(0,"BT_Panel_");
   if(!InpShowBT)return;

   int wins=0,losses=0,open_cnt=0;
   int wins_2r=0,wins_3r=0;
   int s_wins=0,s_dec=0,w_wins=0,w_dec=0;

   for(int s=0;s<g_bt_cnt;s++){
      if(g_bt[s].skip)continue;
      if     (g_bt[s].outcome== 1){wins++;if(g_bt[s].use_2r)wins_2r++;else wins_3r++;}
      else if(g_bt[s].outcome==-1) losses++;
      else                         open_cnt++;
      bool dec=(g_bt[s].outcome!=0);
      if(g_bt[s].is_strong){if(dec)s_dec++;if(g_bt[s].outcome==1)s_wins++;}
      else                  {if(dec)w_dec++;if(g_bt[s].outcome==1)w_wins++;}
   }

   int decided=wins+losses;
   int total=wins+losses+open_cnt;
   double wr =(decided>0)?(100.0*wins/decided):0.0;
   double swr=(s_dec>0)  ?(100.0*s_wins/s_dec):0.0;
   double wwr=(w_dec>0)  ?(100.0*w_wins/w_dec):0.0;

   string L[5];
   L[0]=StringFormat("CHoCH BT | %s | SL:%.0f%%  TP:%.1fR",Symbol(),InpBTSLPct,InpBTRR);
   L[1]=StringFormat("Sinyal: %d  (W:%d  L:%d  ?:%d)",total,wins,losses,open_cnt);
   L[2]=StringFormat("Kazanma: %.1f%%   %.1fR:%d  2R:%d",wr,InpBTRR,wins_3r,wins_2r);
   L[3]=StringFormat("Guclu:  %.1f%% (%d/%d)",swr,s_wins,s_dec);
   L[4]=StringFormat("Zayif:  %.1f%% (%d/%d)",wwr,w_wins,w_dec);

   // --- Arka plan ---
   // CORNER_RIGHT_UPPER + ANCHOR_RIGHT_UPPER:
   //   XDISTANCE = sagdan mesafe, metin soldan saga degil sagdan sola uzar
   int right_pad = 8;   // sag kenardan ic bosluk
   int top_pad   = 30;  // ustten baslangic
   int line_h    = 19;  // satir yuksekligi
   int bw        = 280; // dikdortgen genisligi
   int bh        = 5*line_h+10;

   string bg="BT_Panel_BG";
   if(ObjectFind(0,bg)<0)ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0);
   // Dikdortgenin sag kenari right_pad px icerde, sol kenari bw px daha sol
   ObjectSetInteger(0,bg,OBJPROP_CORNER,     CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,  right_pad);
   ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,  top_pad-4);
   ObjectSetInteger(0,bg,OBJPROP_XSIZE,      bw);
   ObjectSetInteger(0,bg,OBJPROP_YSIZE,      bh);
   ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,    C'10,10,10');
   ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,bg,OBJPROP_COLOR,      C'55,55,55');
   ObjectSetInteger(0,bg,OBJPROP_WIDTH,      1);
   ObjectSetInteger(0,bg,OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0,bg,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,bg,OBJPROP_ZORDER,     0);

   // Metin: ANCHOR_RIGHT_UPPER → anchor sagda, metin sola uzar → dikdortgen icinde kalir
   color wr_clr=(wr>=55.0)?C'80,220,80':(wr>=45.0)?C'220,200,50':C'220,80,80';
   for(int i=0;i<5;i++){
      string nm="BT_Panel_"+IntegerToString(i+1);
      if(ObjectFind(0,nm)<0)ObjectCreate(0,nm,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,nm,OBJPROP_CORNER,    CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,nm,OBJPROP_XDISTANCE, right_pad+6);
      ObjectSetInteger(0,nm,OBJPROP_YDISTANCE, top_pad+i*line_h);
      ObjectSetInteger(0,nm,OBJPROP_ANCHOR,    ANCHOR_RIGHT_UPPER);
      ObjectSetString (0,nm,OBJPROP_TEXT,      L[i]);
      ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,  8);
      ObjectSetString (0,nm,OBJPROP_FONT,      "Courier New");
      ObjectSetInteger(0,nm,OBJPROP_COLOR,     (i==2)?wr_clr:C'195,195,195');
      ObjectSetInteger(0,nm,OBJPROP_HIDDEN,    true);
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,nm,OBJPROP_ZORDER,    1);
   }

   Print("========== CHoCH BT ==========");
   for(int i=0;i<5;i++)Print(L[i]);
   Print("===============================");
}

//=====================================================================
// OnInit / OnDeinit / OnCalculate
//=====================================================================
int OnInit(){IndicatorSetString(INDICATOR_SHORTNAME,"Structure_BT");return INIT_SUCCEEDED;}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
   ObjectsDeleteAll(0,"Live_"); ObjectsDeleteAll(0,"CHoCH_Path_");ObjectsDeleteAll(0,"CHoCH_Signal_");
   ObjectsDeleteAll(0,"Box_");  ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");
   ObjectsDeleteAll(0,"BT_");   // *** BT temizle ***
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
      ObjectsDeleteAll(0,"Box_");  ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");
      ObjectsDeleteAll(0,"BT_");   // *** BT temizle ***
      BxClear();

      // *** BT reset ***
      g_bt_cnt=0;
      g_last_sltp_d1i_sell=-1;
      g_last_sltp_d1i_buy =-1;

      int si=0;for(int k=0;k<rates_total;k++)if(time[k]>=g_anchor_time){si=k;break;}
      g_state_hist.min_h=high[si];g_state_hist.min_h_i=si;g_state_hist.min_l=low[si];g_state_hist.min_l_i=si;
      g_state_hist.trig_h=high[si];g_state_hist.trig_l=low[si];
      g_state_hist.tmp_h=high[si];g_state_hist.tmp_h_i=si;g_state_hist.tmp_l=low[si];g_state_hist.tmp_l_i=si;
      g_state_hist.min_tr=(close[si]>open[si])?1:-1;
      g_state_hist.anc_i=si;g_state_hist.anc_v=close[si];g_state_hist.lp_i=si;g_state_hist.lp_p=close[si];
      g_state_hist.bos_i=si;g_state_hist.maj_h_i=si;g_state_hist.maj_l_i=si;
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

      // *** BT modu aç ***
      g_bt_mode=true;

      for(int i=limit;i<rates_total-1;i++){
         bool inside=(high[i]<=g_state_hist.mb_h)&&(low[i]>=g_state_hist.mb_l);
         if(!inside){
            if(high[i]>g_state_hist.mb_h||low[i]<g_state_hist.mb_l){g_state_hist.mb_h=high[i];g_state_hist.mb_l=low[i];g_state_hist.mb_i=i;}
            ProcessBar(i,open,high,low,close,time,g_state_hist,true);
         }else{double pc=(i>0)?close[i-1]:close[i];BxUpdateStats(high[i],low[i],close[i],pc,time[i]);}
      }

      // *** BT modu kapat ***
      g_bt_mode=false;

      // *** BT değerlendirme & çizim ***
      if(InpShowBT){
         EvaluateBT(high,low,time,rates_total);
         DrawBTResults(time,rates_total);
         DrawBTPanel();
      }

   }else{limit=prev_calculated-1;}

   // Canlı bar
   ObjectsDeleteAll(0,"Live_");DeleteLine("LiveLeg");
   g_state_curr.CopyFrom(g_state_hist);
   int li=rates_total-1;
   if(li>0){
      g_live_bar_processing=true;
      bool il=(high[li]<=g_state_curr.mb_h)&&(low[li]>=g_state_curr.mb_l);
      if(!il)ProcessBar(li,open,high,low,close,time,g_state_curr,false);
      else{double pc=(li>0)?close[li-1]:close[li];BxUpdateStats(high[li],low[li],close[li],pc,time[li]);}
      g_live_bar_processing=false;
   }

   if(InpShowMin&&li>0){
      int    lgi=(g_state_curr.min_tr==1)?g_state_curr.min_h_i:g_state_curr.min_l_i;
      double lgp=(g_state_curr.min_tr==1)?g_state_curr.min_h  :g_state_curr.min_l;
      DrawLine("LiveLeg",GetTimeSafe(time,g_state_curr.lp_i),g_state_curr.lp_p,GetTimeSafe(time,lgi),lgp,InpColorMin,1,STYLE_DOT);
   }
   return rates_total;
}
