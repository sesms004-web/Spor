//+------------------------------------------------------------------+
//|                                         smacv2_choch_box.mq5     |
//|   SMC v2 – Temiz Yeniden Yazım                                   |
//+------------------------------------------------------------------+
//
//  ZAYIF BÖLGE KURALI:
//    Her kutunun hem üstüne hem altına (box_height * InpWeakZonePct/100)
//    kadar zayıf bölge eklenir.
//
//    Etkileşim tespiti (her bar):
//      Ana kutu [bot, top]            → normal etkileşim (mevcut mantık)
//      Zayıf üst [top, top+wk]        → "Zayıf Değme (Üst)"
//      Zayıf alt [bot-wk, bot]        → "Zayıf Değme (Alt)"
//
//    Durum metni örnekleri:
//      "[1] Yukaridan geldi | Icinde: 5 mum"
//      "[1] v Deldi gecti | 12 dk once"
//      "[1] ^ Yukari kacti | 3 dk once"
//      "   Zayif Degme (Ust) | 2 dk once"   ← üst weak zone
//      "   Zayif Degme (Alt) | 7 dk once"   ← alt weak zone
//
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "29.00"
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
input bool   InpNotifTest    = false;  // Test bildirimi gönder (açınca çalışır)
input bool   InpNotifSignal  = true;   // Sinyal değişince bildirim gönder

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
input double InpWeakZonePct  = 50.0;   // Zayıf bölge genişliği (kutu yüksekliğinin %'si)
input color  InpColorWeakBull = C'0,25,55';  // Bull zayıf bölge rengi
input color  InpColorWeakBear = C'55,15,0';  // Bear zayıf bölge rengi

input group "--- İSTATİSTİK ---"
input bool   InpShowStats   = true;
input color  InpColorStats  = clrWhite;
input int    InpStatsFontSz = 8;

int      g_counter     = 0;
datetime g_anchor_time = 0;

//--------------------------------------------------------------------
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

//--------------------------------------------------------------------
//  Kutu + Zayıf Bölge Takip
//--------------------------------------------------------------------
#define BOX_MAX 512

// --- Ana kutu ---
string   g_bx_nm[BOX_MAX];
int      g_bx_state[BOX_MAX];      // 2=Yeni, 1=İşaretli, 0=Kesildi
double   g_bx_top[BOX_MAX];
double   g_bx_bot[BOX_MAX];
string   g_bx_lbl[BOX_MAX];        // Etiket

// --- Durum makinesi (ana kutu) ---
int      g_bx_touch_state[BOX_MAX];// 0=dokunulmadı,1=içinde,2=deldi,3=kaçtı
int      g_bx_approach[BOX_MAX];   // +1=yukarıdan,-1=aşağıdan
int      g_bx_inside_cnt[BOX_MAX]; // içinde geçirilen mum sayısı
datetime g_bx_event_time[BOX_MAX]; // son ana olay zamanı

// --- Zayıf bölge ---
string   g_bx_wk_abv_nm[BOX_MAX]; // Üst zayıf bölge nesne adı  [top, top+wk]
string   g_bx_wk_blw_nm[BOX_MAX]; // Alt zayıf bölge nesne adı  [bot-wk, bot]
double   g_bx_wk_abv_top[BOX_MAX];// Üst zayıf bölge üst fiyat
double   g_bx_wk_blw_bot[BOX_MAX];// Alt zayıf bölge alt fiyat
// Zayıf bölge durum: 0=dokunulmadı, 1=üst zayıf dokunuldu, 2=alt zayıf dokunuldu
int      g_bx_wk_touch[BOX_MAX];
datetime g_bx_wk_time[BOX_MAX];   // Zayıf bölge dokunma zamanı

int g_bx_cnt = 0;

//--------------------------------------------------------------------
void BxAdd(string nm, double top, double bot, color box_clr,
           const datetime &time[], int right_i)
{
   if(g_bx_cnt >= BOX_MAX) return;

   double wk_sz = (top - bot) * InpWeakZonePct / 100.0;
   color  wk_clr= (box_clr==InpColorBoxBull||box_clr==InpColorBoxBullFaint)
                   ? InpColorWeakBull : InpColorWeakBear;

   g_bx_nm[g_bx_cnt]          = nm;
   g_bx_state[g_bx_cnt]       = 2;
   g_bx_top[g_bx_cnt]         = top;
   g_bx_bot[g_bx_cnt]         = bot;
   g_bx_lbl[g_bx_cnt]         = "BoxLbl_" + IntegerToString(g_bx_cnt);
   g_bx_touch_state[g_bx_cnt] = 0;
   g_bx_approach[g_bx_cnt]    = 0;
   g_bx_inside_cnt[g_bx_cnt]  = 0;
   g_bx_event_time[g_bx_cnt]  = 0;

   // Zayıf bölge nesne adları
   g_bx_wk_abv_nm[g_bx_cnt]  = "BoxWkAbv_" + IntegerToString(g_bx_cnt);
   g_bx_wk_blw_nm[g_bx_cnt]  = "BoxWkBlw_" + IntegerToString(g_bx_cnt);
   g_bx_wk_abv_top[g_bx_cnt] = top + wk_sz;
   g_bx_wk_blw_bot[g_bx_cnt] = bot - wk_sz;
   g_bx_wk_touch[g_bx_cnt]   = 0;
   g_bx_wk_time[g_bx_cnt]    = 0;

   // Zayıf bölgeleri çiz (üst)
   datetime t_left = ST(time, right_i);
   _DrawWeakRect(g_bx_wk_abv_nm[g_bx_cnt], t_left,
                 g_bx_wk_abv_top[g_bx_cnt], top, wk_clr);
   // Zayıf bölgeleri çiz (alt)
   _DrawWeakRect(g_bx_wk_blw_nm[g_bx_cnt], t_left,
                 bot, g_bx_wk_blw_bot[g_bx_cnt], wk_clr);

   g_bx_cnt++;
}

//--------------------------------------------------------------------
//  Zayıf bölge dikdörtgeni (kenarlıklı, dolgusuz)
//--------------------------------------------------------------------
void _DrawWeakRect(string nm, datetime t1, double top, double bot, color clr)
{
   if(top < bot){ double tmp=top; top=bot; bot=tmp; }
   if(ObjectFind(0,nm)<0)
      ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,top,D'2099.12.31 00:00',bot);
   else
   {
      ObjectSetInteger(0,nm,OBJPROP_TIME, 0,t1);
      ObjectSetDouble (0,nm,OBJPROP_PRICE,0,top);
      ObjectSetInteger(0,nm,OBJPROP_TIME, 1,D'2099.12.31 00:00');
      ObjectSetDouble (0,nm,OBJPROP_PRICE,1,bot);
   }
   ObjectSetInteger(0,nm,OBJPROP_COLOR,  clr);
   ObjectSetInteger(0,nm,OBJPROP_STYLE,  STYLE_DOT);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,  1);
   ObjectSetInteger(0,nm,OBJPROP_FILL,   false); // Sadece kenarlık
   ObjectSetInteger(0,nm,OBJPROP_BACK,   true);
   ObjectSetInteger(0,nm,OBJPROP_HIDDEN, true);
}

//--------------------------------------------------------------------
//  Yön bazlı kutu + zayıf bölge durum güncelleme
//--------------------------------------------------------------------
void BxUpdateStats(double h, double l, double c, double prev_c, datetime bar_time)
{
   for(int k = 0; k < g_bx_cnt; k++)
   {
      if(g_bx_state[k] == 0) continue;

      double top     = g_bx_top[k];
      double bot     = g_bx_bot[k];
      double wk_atop = g_bx_wk_abv_top[k]; // üst zayıf üst sınır
      double wk_bbot = g_bx_wk_blw_bot[k]; // alt zayıf alt sınır

      bool in_main = (h >= bot)     && (l <= top);     // ana kutu teması
      bool in_wk_a = (h >= top)     && (l <= wk_atop)  // üst zayıf bölge teması
                   && !in_main;                          // ama ana kutuda değil
      bool in_wk_b = (h >= wk_bbot) && (l <= bot)      // alt zayıf bölge teması
                   && !in_main;

      //--- Ana kutu durum makinesi ---
      int ts = g_bx_touch_state[k];

      // Yön tespiti: zayıf bölgenin DIŞ sınırını geçip gelmişse o yönden sayılır
      // prev_c > wk_atop  → yukarıdan geldi (+1)
      // prev_c < wk_bbot  → aşağıdan geldi (-1)
      // İkisi arasındaysa → mevcut yön korunur (zaten zone içindeydi)
      int new_appr;
      if(prev_c > wk_atop)       new_appr =  1;
      else if(prev_c < wk_bbot)  new_appr = -1;
      else                        new_appr =  g_bx_approach[k]; // zone içindeydi, yön değişmez

      if(ts == 0) // Henüz dokunulmadı
      {
         if(in_main)
         {
            g_bx_approach[k]    = (new_appr != 0) ? new_appr
                                   : (c > (top+bot)/2.0 ? -1 : 1);
            g_bx_touch_state[k] = 1;
            g_bx_inside_cnt[k]  = 1;
            g_bx_event_time[k]  = bar_time;
         }
      }
      else if(ts == 1) // İçinde
      {
         if(in_main)
         {
            g_bx_inside_cnt[k]++;
            g_bx_event_time[k] = bar_time;
         }
         else
         {
            bool broke_down = (c < bot);
            bool broke_up   = (c > top);
            int  appr       = g_bx_approach[k];
            if(appr==1){ if(broke_down) g_bx_touch_state[k]=2; else if(broke_up) g_bx_touch_state[k]=3; }
            else        { if(broke_up)  g_bx_touch_state[k]=2; else if(broke_down) g_bx_touch_state[k]=3; }
            g_bx_event_time[k] = bar_time;
         }
      }
      else // Deldi veya Kaçtı → yeni yaklaşım?
      {
         if(in_main)
         {
            // Yeni yaklaşımda sadece dış sınırdan geliyorsa yönü güncelle
            g_bx_approach[k]    = (new_appr != 0) ? new_appr
                                   : (c > (top+bot)/2.0 ? -1 : 1);
            g_bx_touch_state[k] = 1;
            g_bx_inside_cnt[k]  = 1;
            g_bx_event_time[k]  = bar_time;
         }
      }

      //--- Zayıf bölge takibi ---
      // Yalnızca ana kutuda değilken zayıf bölge sayılır
      if(!in_main)
      {
         if(in_wk_a)
         {
            g_bx_wk_touch[k] = 1;  // üst zayıf bölge dokunuldu
            g_bx_wk_time[k]  = bar_time;
         }
         else if(in_wk_b)
         {
            g_bx_wk_touch[k] = 2;  // alt zayıf bölge dokunuldu
            g_bx_wk_time[k]  = bar_time;
         }
      }
   }
}

//--------------------------------------------------------------------
//  Zaman farkı formatlı metin: Xay Xg Xsa Xdk + kaç mum önce
//--------------------------------------------------------------------
string FormatTimeDiff(datetime event_time, datetime cur_time)
{
   if(event_time == 0) return "?";
   int total_secs = (int)(cur_time - event_time);
   if(total_secs < 0) total_secs = 0;

   int total_mins  = total_secs / 60;
   int total_hours = total_mins  / 60;
   int total_days  = total_hours / 24;
   int months      = total_days  / 30;

   int mins  = total_mins  % 60;
   int hours = total_hours % 24;
   int days  = total_days  % 30;

   // Kaç mum önce
   int candles = (PeriodSeconds() > 0)
                 ? (int)((cur_time - event_time) / PeriodSeconds()) : 0;

   string t = "";
   if(months  > 0) t += IntegerToString(months)  + "ay ";
   if(days    > 0) t += IntegerToString(days)     + "g ";
   if(hours   > 0) t += IntegerToString(hours)    + "sa ";
   t += IntegerToString(mins) + "dk";

   return t + "  +" + IntegerToString(candles) + " mum";
}

//--------------------------------------------------------------------
//  Durum metni üret
//--------------------------------------------------------------------
string BxGetStatusText(int k, datetime cur_time)
{
   int ts    = g_bx_touch_state[k];
   int appr  = g_bx_approach[k];
   int wkt   = g_bx_wk_touch[k];

   string t_main = FormatTimeDiff(g_bx_event_time[k], cur_time);
   string t_wk   = FormatTimeDiff(g_bx_wk_time[k],   cur_time);

   string main_txt = "";
   if(ts == 0) main_txt = "(bekleniyor)";
   else if(ts == 1)
      main_txt = StringFormat("%s'dan geldi | Icinde: %d mum",
                              (appr==1?"Yukari":"Asagi"), g_bx_inside_cnt[k]);
   else if(ts == 2)
      main_txt = StringFormat("%s Deldi gecti | %s",
                              (appr==1?"v":"^"), t_main);
   else if(ts == 3)
      main_txt = StringFormat("%s Kacti | %s",
                              (appr==1?"^ Yukari":"v Asagi"), t_main);

   string wk_txt = "";
   if(wkt == 1)
      wk_txt = StringFormat("\n   Zayif Degme (Ust) | %s", t_wk);
   else if(wkt == 2)
      wk_txt = StringFormat("\n   Zayif Degme (Alt) | %s", t_wk);

   return main_txt + wk_txt;
}

//--------------------------------------------------------------------
//  Etiket çiz/güncelle – en son etkileşime göre sıralı
//--------------------------------------------------------------------
void BxDrawLabels(datetime cur_time)
{
   if(!InpShowStats) return;

   int sorted[BOX_MAX];
   int cnt = 0;
   for(int k = 0; k < g_bx_cnt; k++)
      if(g_bx_state[k] > 0) sorted[cnt++] = k;

   // event_time büyükten küçüğe (en son etkileşim = rank 1)
   for(int a = 0; a < cnt-1; a++)
      for(int b = a+1; b < cnt; b++)
      {
         datetime ta = g_bx_event_time[sorted[a]];
         datetime tb = g_bx_event_time[sorted[b]];
         // Zayıf bölge de varsa onu da hesaba kat
         if(g_bx_wk_time[sorted[a]] > ta) ta = g_bx_wk_time[sorted[a]];
         if(g_bx_wk_time[sorted[b]] > tb) tb = g_bx_wk_time[sorted[b]];
         if(tb > ta){ int tmp=sorted[a]; sorted[a]=sorted[b]; sorted[b]=tmp; }
      }

   // Kesilmiş kutuların etiketlerini sil
   for(int k = 0; k < g_bx_cnt; k++)
      if(g_bx_state[k]==0 && ObjectFind(0,g_bx_lbl[k])>=0)
         ObjectDelete(0,g_bx_lbl[k]);

   // Sıralı etiket çiz
   for(int r = 0; r < cnt; r++)
   {
      int    k   = sorted[r];
      string lbl = g_bx_lbl[k];
      double mid = (g_bx_top[k] + g_bx_bot[k]) / 2.0;
      string txt = StringFormat("[%d] %s", r+1, BxGetStatusText(k, cur_time));

      if(ObjectFind(0,lbl)<0)
         ObjectCreate(0,lbl,OBJ_TEXT,0,cur_time,mid);

      ObjectSetInteger(0,lbl,OBJPROP_TIME,   0, cur_time);
      ObjectSetDouble (0,lbl,OBJPROP_PRICE,  0, mid);
      ObjectSetString (0,lbl,OBJPROP_TEXT,      txt);
      ObjectSetInteger(0,lbl,OBJPROP_COLOR,     InpColorStats);
      ObjectSetInteger(0,lbl,OBJPROP_FONTSIZE,  InpStatsFontSz);
      ObjectSetString (0,lbl,OBJPROP_FONT,      "Courier New");
      ObjectSetInteger(0,lbl,OBJPROP_ANCHOR,    ANCHOR_LEFT);
      ObjectSetInteger(0,lbl,OBJPROP_BACK,      false);
      ObjectSetInteger(0,lbl,OBJPROP_HIDDEN,    true);
   }
}

//--------------------------------------------------------------------
//  Comment özeti
//--------------------------------------------------------------------
void BxShowComment(datetime cur_time)
{
   if(!InpShowStats){ Comment(""); return; }

   int sorted[BOX_MAX];
   int cnt = 0;
   for(int k = 0; k < g_bx_cnt; k++)
      if(g_bx_state[k] > 0) sorted[cnt++] = k;

   for(int a = 0; a < cnt-1; a++)
      for(int b = a+1; b < cnt; b++)
      {
         datetime ta = g_bx_event_time[sorted[a]];
         datetime tb = g_bx_event_time[sorted[b]];
         if(g_bx_wk_time[sorted[a]] > ta) ta = g_bx_wk_time[sorted[a]];
         if(g_bx_wk_time[sorted[b]] > tb) tb = g_bx_wk_time[sorted[b]];
         if(tb > ta){ int tmp=sorted[a]; sorted[a]=sorted[b]; sorted[b]=tmp; }
      }

   string out = "=== KUTU DURUMU ===\n";
   if(cnt == 0){ out += "(Aktif kutu yok)\n"; Comment(out); return; }

   int show = MathMin(cnt, 10);
   for(int r = 0; r < show; r++)
   {
      int k = sorted[r];
      out += StringFormat("[%d] %.5f - %.5f\n    %s\n",
                          r+1, g_bx_top[k], g_bx_bot[k],
                          BxGetStatusText(k, cur_time));
   }
   Comment(out);
}

//--------------------------------------------------------------------
//  Trim sistemi
//--------------------------------------------------------------------
void BxAdvanceTrim(datetime t)
{
   for(int k = 0; k < g_bx_cnt; k++)
   {
      if(g_bx_state[k]==1 && ObjectFind(0,g_bx_nm[k])>=0)
      {
         // Fiyat şu an kutu içindeyse → koru
         if(g_bx_touch_state[k]==1) continue;

         // Ana kutu kes
         ObjectSetInteger(0,g_bx_nm[k],OBJPROP_TIME,1,t);
         g_bx_state[k]=0;

         // Zayıf bölgeleri de kes
         if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)
            ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)
            ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,t);
         // Etiket sil
         if(ObjectFind(0,g_bx_lbl[k])>=0)
            ObjectDelete(0,g_bx_lbl[k]);
      }
      else if(g_bx_state[k]==2)
         g_bx_state[k]=1;
   }
}

void BxDeleteAll()
{
   for(int k=0;k<g_bx_cnt;k++)
   {
      if(ObjectFind(0,g_bx_nm[k])>=0)        ObjectDelete(0,g_bx_nm[k]);
      if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0) ObjectDelete(0,g_bx_wk_abv_nm[k]);
      if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0) ObjectDelete(0,g_bx_wk_blw_nm[k]);
      if(ObjectFind(0,g_bx_lbl[k])>=0)       ObjectDelete(0,g_bx_lbl[k]);
   }
   g_bx_cnt=0;
}

void BxClear(){ g_bx_cnt=0; }

//--------------------------------------------------------------------
//  Çizim yardımcıları
//--------------------------------------------------------------------
datetime ST(const datetime &t[],int idx)
{ int s=ArraySize(t);if(s<=0)return 0;if(idx<0)return t[0];if(idx>=s)return t[s-1];return t[idx]; }

string GetUniqueName(string p){ g_counter++; return p+IntegerToString(g_counter); }

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

   int    bx_phase;
   bool   bx_extreme;
   double bx_swing_h;
   double bx_swing_l;

   bool   has_pot_bull_minor;
   int    pot_bull_start_i;
   double pot_bull_start_p;
   double pot_bull_end_p;

   bool   has_pot_bear_minor;
   int    pot_bear_start_i;
   double pot_bear_start_p;
   double pot_bear_end_p;

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
      has_pot_bull_minor=s.has_pot_bull_minor;pot_bull_start_i=s.pot_bull_start_i;pot_bull_start_p=s.pot_bull_start_p;pot_bull_end_p=s.pot_bull_end_p;
      has_pot_bear_minor=s.has_pot_bear_minor;pot_bear_start_i=s.pot_bear_start_i;pot_bear_start_p=s.pot_bear_start_p;pot_bear_end_p=s.pot_bear_end_p;
   }
};

SState g_state_hist;
SState g_state_curr;

void BxReset(SState &s,double ref_l,double ref_h)
{ s.bx_phase=0;s.bx_extreme=false;s.bx_swing_l=ref_l;s.bx_swing_h=ref_h; }

//--------------------------------------------------------------------
//  Kutu çiz
//--------------------------------------------------------------------
void DoDrawBox(const datetime &time[],string pfx,SState &s,
               int left_i,double top,double bot,color clr)
{
   if(left_i < s.anc_i) left_i = s.anc_i;
   if(top < bot){ double tmp=top; top=bot; bot=tmp; }

   double maj_sz = s.maj_h - s.maj_l;
   if(maj_sz > 0 && (top-bot)/maj_sz*100.0 > InpMaxBoxPct)
   {
      if(clr==InpColorBoxBull||clr==InpColorBoxBullFaint)
      {
         double fh=-1; int fi=left_i;
         for(int k=0;k<s.st_h.Size();k++)
         {
            double mh=s.st_h.GetVal(k);
            if(mh>bot&&mh<top&&(fh<0||mh<fh)){fh=mh;fi=s.st_h.GetIdx(k);}
         }
         if(fh>0){top=fh;left_i=fi;} else top=bot+maj_sz*InpMaxBoxPct/100.0;
      }
      else
      {
         double fl=-1; int fi=left_i;
         for(int k=0;k<s.st_l.Size();k++)
         {
            double ml=s.st_l.GetVal(k);
            if(ml<top&&ml>bot&&(fl<0||ml>fl)){fl=ml;fi=s.st_l.GetIdx(k);}
         }
         if(fl>0){bot=fl;left_i=fi;} else bot=top-maj_sz*InpMaxBoxPct/100.0;
      }
   }

   if(top<=bot) return;

   string nm=GetUniqueName(pfx+"Box_");
   DrawRect(nm,ST(time,left_i),top,D'2099.12.31 00:00',bot,clr);
   // BxAdd: ana kutu + zayıf bölgeler
   BxAdd(nm, top, bot, clr, time, left_i);
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
   if(rt<=0||i<0||i>=rt) return;
   double val_h=high[i], val_l=low[i], val_c=close[i];
   double prev_c=(i>0)?close[i-1]:close[i];
   string pfx=is_history?"":"Live_";

   if(InpShowStats)
      BxUpdateStats(val_h,val_l,val_c,prev_c,time[i]);

   //================================================================
   //  MİNÖR
   //================================================================
   if(state.min_tr==1)
   {
      double old_trig=state.trig_l;
      if(val_h>state.min_h){state.min_h=val_h;state.min_h_i=i;state.trig_l=val_l;}
      if(val_l<old_trig)
      {
         int    peak_i  = state.min_h_i;
         double peak_p  = state.min_h;
         int    start_i = state.lp_i;
         double start_lp= state.lp_p;

         if(draw_ui&&InpShowMin)
            DrawLine(GetUniqueName(pfx+"Minor_"),ST(time,start_i),start_lp,ST(time,peak_i),peak_p,InpColorMin,1,STYLE_SOLID);

         if(state.maj_tr==-1&&!state.has_pot_bull_minor&&start_i>=state.tmp_l_i)
         { state.has_pot_bull_minor=true;state.pot_bull_start_i=start_i;state.pot_bull_start_p=start_lp;state.pot_bull_end_p=peak_p; }

         if(draw_ui&&InpShowBox&&state.maj_st==0&&state.maj_tr==1)
         {
            if(state.bx_phase==0||state.bx_phase==2)
            {
               if(is_history) DoDrawBox(time,pfx,state,start_i,peak_p,start_lp,InpColorBoxBull);
               state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=peak_p;state.bx_swing_l=start_lp;
            }
            else
            { if(peak_p>state.bx_swing_h){state.bx_extreme=true;state.bx_swing_h=peak_p;} }
         }

         if(draw_ui&&InpShowBox&&state.maj_st==0&&state.maj_tr==-1&&state.bx_phase==1)
         {
            if(state.bx_extreme&&peak_p>state.bx_swing_h){state.bx_phase=2;state.bx_extreme=false;}
            else state.bx_swing_h=peak_p;
         }

         state.st_h.Push(peak_p,peak_i);
         if(state.maj_tr==1&&state.maj_st==0&&peak_p<state.tmp_h&&state.st_l.Size()>0)
            if(state.st_l.GetIdx(state.st_l.Size()-1)>state.bos_i)state.st_l.Pop();
         state.min_tr=-1;
         state.lp_i=peak_i;state.lp_p=peak_p;
         state.min_l=val_l;state.min_l_i=i;state.trig_h=val_h;
      }
   }
   else
   {
      double old_trig=state.trig_h;
      if(val_l<state.min_l){state.min_l=val_l;state.min_l_i=i;state.trig_h=val_h;}
      if(val_h>old_trig)
      {
         int    trough_i = state.min_l_i;
         double trough_p = state.min_l;
         int    start_i  = state.lp_i;
         double start_hp = state.lp_p;

         if(draw_ui&&InpShowMin)
            DrawLine(GetUniqueName(pfx+"Minor_"),ST(time,start_i),start_hp,ST(time,trough_i),trough_p,InpColorMin,1,STYLE_SOLID);

         if(state.maj_tr==1&&!state.has_pot_bear_minor&&start_i>=state.tmp_h_i)
         { state.has_pot_bear_minor=true;state.pot_bear_start_i=start_i;state.pot_bear_start_p=start_hp;state.pot_bear_end_p=trough_p; }

         if(draw_ui&&InpShowBox&&state.maj_st==0&&state.maj_tr==1&&state.bx_phase==1)
         {
            if(state.bx_extreme&&trough_p<state.bx_swing_l){state.bx_phase=2;state.bx_extreme=false;}
            else state.bx_swing_l=trough_p;
         }

         if(draw_ui&&InpShowBox&&state.maj_st==0&&state.maj_tr==-1)
         {
            if(state.bx_phase==0||state.bx_phase==2)
            {
               if(is_history) DoDrawBox(time,pfx,state,start_i,start_hp,trough_p,InpColorBoxBear);
               state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=start_hp;state.bx_swing_l=trough_p;
            }
            else
            { if(trough_p<state.bx_swing_l){state.bx_extreme=true;state.bx_swing_l=trough_p;} }
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
      if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
      if(state.maj_st==0)
      {
         double act=state.st_l.Size()>0?state.st_l.GetVal(state.st_l.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_l<act)
         {
            state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_h_i),state.maj_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.maj_h_i,InpColorVLBull);
            if(draw_ui&&InpShowBox)BxAdvanceTrim(ST(time,state.maj_h_i));
            state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);
            if(draw_ui&&InpShowMaj){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,ST(time,state.maj_h_i),state.maj_h,time[i]+PeriodSeconds(),state.maj_h,InpColorBull,1,STYLE_DASH,true);if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,ST(time,state.maj_l_i),state.maj_l,time[i]+PeriodSeconds(),state.maj_l,InpColorBull,1,STYLE_DASH,true);}}
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l)
         {
            if(draw_ui&&InpShowBox)BxAdvanceTrim(ST(time,state.tmp_h_i));
            state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_h_i,InpColorVLBull);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            state.maj_l=val_l;state.maj_l_i=i;
            if(state.has_pot_bear_minor)
               if(is_history&&draw_ui&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
            BxReset(state,val_l,state.tmp_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
      }
      else if(state.maj_st==1)
      {
         if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
         if(val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(val_c>state.maj_h)
         {
            state.bos_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_l_i),state.maj_l,InpColorBull,2,STYLE_SOLID);
            state.st_h.Clear();state.maj_st=0;state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            BxReset(state,state.maj_l,val_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(state.maj_l!=EMPTY_VALUE&&state.maj_l!=0&&val_c<state.maj_l)
         {
            if(draw_ui&&InpShowBox)BxAdvanceTrim(ST(time,state.tmp_h_i));
            state.maj_tr=-1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_h_i),state.tmp_h,InpColorBull,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_h_i,InpColorVLBull);
            state.st_l.Clear();state.anc_i=state.tmp_h_i;state.anc_v=state.tmp_h;state.tmp_l=val_l;state.tmp_l_i=i;state.maj_h=state.tmp_h;state.maj_h_i=state.tmp_h_i;
            state.maj_l=val_l;state.maj_l_i=i;
            if(state.has_pot_bear_minor)
               if(is_history&&draw_ui&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);
            BxReset(state,val_l,state.tmp_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }
   else
   {
      if(val_l<state.tmp_l){state.tmp_l=val_l;state.tmp_l_i=i;state.has_pot_bull_minor=false;}
      if(state.maj_st==0)
      {
         double act=state.st_h.Size()>0?state.st_h.GetVal(state.st_h.Size()-1):EMPTY_VALUE;
         if(act!=EMPTY_VALUE&&val_h>act)
         {
            state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_l_i),state.maj_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.maj_l_i,InpColorVLBear);
            if(draw_ui&&InpShowBox)BxAdvanceTrim(ST(time,state.maj_l_i));
            state.st_l.Clear();state.st_h.Clear();state.maj_st=1;
            state.anc_i=state.maj_l_i;state.anc_v=state.maj_l;state.tmp_h=val_h;state.tmp_h_i=i;
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);
            if(draw_ui&&InpShowMaj){state.cur_bot_line=GetUniqueName(pfx+"HLine_Bot_");DrawLine(state.cur_bot_line,ST(time,state.maj_l_i),state.maj_l,time[i]+PeriodSeconds(),state.maj_l,InpColorBear,1,STYLE_DASH,true);if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0){state.cur_top_line=GetUniqueName(pfx+"HLine_Top_");DrawLine(state.cur_top_line,ST(time,state.maj_h_i),state.maj_h,time[i]+PeriodSeconds(),state.maj_h,InpColorBear,1,STYLE_DASH,true);}}
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h)
         {
            if(draw_ui&&InpShowBox)BxAdvanceTrim(ST(time,state.tmp_l_i));
            state.maj_tr=1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_l_i,InpColorVLBear);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            state.maj_h=val_h;state.maj_h_i=i;
            if(state.has_pot_bull_minor)
               if(is_history&&draw_ui&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
            BxReset(state,state.tmp_l,val_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
      }
      else if(state.maj_st==1)
      {
         if(val_h>state.tmp_h){state.tmp_h=val_h;state.tmp_h_i=i;state.has_pot_bear_minor=false;}
         if(val_l<state.maj_l&&val_c>=state.maj_l){state.maj_l=val_l;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_bot_line,state.maj_l);}
         if(val_c<state.maj_l)
         {
            state.maj_h=state.tmp_h;state.bos_i=i;state.maj_h_i=state.tmp_h_i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.maj_h_i),state.maj_h,InpColorBear,2,STYLE_SOLID);
            state.st_l.Clear();state.maj_st=0;state.anc_i=state.maj_h_i;state.anc_v=state.maj_h;state.tmp_l=val_l;state.tmp_l_i=i;
            BxReset(state,val_l,state.maj_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_h>state.maj_h&&val_c<=state.maj_h){state.maj_h=val_h;if(draw_ui&&InpShowMaj)UpdateLevel(state.cur_top_line,state.maj_h);}
         if(state.maj_h!=EMPTY_VALUE&&state.maj_h!=0&&val_c>state.maj_h)
         {
            if(draw_ui&&InpShowBox)BxAdvanceTrim(ST(time,state.tmp_l_i));
            state.maj_tr=1;state.maj_st=0;state.bos_i=i;
            if(draw_ui&&InpShowMaj)DrawLine(GetUniqueName(pfx+"Major_"),ST(time,state.anc_i),state.anc_v,ST(time,state.tmp_l_i),state.tmp_l,InpColorBear,2,STYLE_SOLID);
            if(draw_ui&&InpShowVL&&is_history)DrawSwingVLines(time,pfx,state.anc_i,state.tmp_l_i,InpColorVLBear);
            state.st_h.Clear();state.anc_i=state.tmp_l_i;state.anc_v=state.tmp_l;state.tmp_h=val_h;state.tmp_h_i=i;state.maj_l=state.tmp_l;state.maj_l_i=state.tmp_l_i;
            state.maj_h=val_h;state.maj_h_i=i;
            if(state.has_pot_bull_minor)
               if(is_history&&draw_ui&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);
            BxReset(state,state.tmp_l,val_h);
            CutLine(state.cur_top_line,time[i]);CutLine(state.cur_bot_line,time[i]);state.cur_top_line="";state.cur_bot_line="";
         }
      }
   }
}

//--------------------------------------------------------------------
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[], const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   if(rates_total<2) return 0;
   static datetime last_bar_time=0; static int last_rates_tot=0;
   int vp=prev_calculated;
   if(prev_calculated==0&&last_bar_time==time[rates_total-1])vp=rates_total-1;
   if(last_rates_tot>0&&rates_total<last_rates_tot)vp=0;

   if(vp>0&&vp<rates_total-1)
   {
      for(int i=vp;i<rates_total-1;i++)
      {
         bool inside=(high[i]<=g_state_hist.mb_h)&&(low[i]>=g_state_hist.mb_l);
         if(!inside)
         {
            if(high[i]>g_state_hist.mb_h||low[i]<g_state_hist.mb_l)
               {g_state_hist.mb_h=high[i];g_state_hist.mb_l=low[i];g_state_hist.mb_i=i;}
            ProcessBar(i,open,high,low,close,time,g_state_hist,true,true);
         }
         else if(InpShowStats)
         { double pc=(i>0)?close[i-1]:close[i]; BxUpdateStats(high[i],low[i],close[i],pc,time[i]); }
      }
   }

   if(vp==0)
   {
      last_bar_time=time[rates_total-1];
      g_anchor_time=TimeCurrent()-(datetime)(GetActiveDays()*86400.0);
      g_counter=0;
      ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
      ObjectsDeleteAll(0,"VL_");ObjectsDeleteAll(0,"Box_");ObjectsDeleteAll(0,"Live_");
      ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");ObjectsDeleteAll(0,"BoxLbl_");
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
      g_state_hist.has_pot_bull_minor=false; g_state_hist.has_pot_bear_minor=false;

      for(int i=si+1;i<rates_total-1;i++)
      {
         bool inside=(high[i]<=g_state_hist.mb_h)&&(low[i]>=g_state_hist.mb_l);
         if(!inside)
         {
            if(high[i]>g_state_hist.mb_h||low[i]<g_state_hist.mb_l)
               {g_state_hist.mb_h=high[i];g_state_hist.mb_l=low[i];g_state_hist.mb_i=i;}
            ProcessBar(i,open,high,low,close,time,g_state_hist,true,true);
         }
         else if(InpShowStats)
         { double pc=(i>0)?close[i-1]:close[i]; BxUpdateStats(high[i],low[i],close[i],pc,time[i]); }
      }
   }

   ObjectsDeleteAll(0,"Live_");DeleteLine("LiveLeg");
   int li=rates_total-1;
   g_state_curr.CopyFrom(g_state_hist);
   if(li>0)
   {
      bool il=(high[li]<=g_state_curr.mb_h)&&(low[li]>=g_state_curr.mb_l);
      if(!il) ProcessBar(li,open,high,low,close,time,g_state_curr,false,true);
      else if(InpShowStats)
      { double pc=(li>0)?close[li-1]:close[li]; BxUpdateStats(high[li],low[li],close[li],pc,time[li]); }
   }

   if(InpShowMin&&li>0)
   {
      int lgi; double lgp;
      if(g_state_curr.min_tr==1){lgi=g_state_curr.min_h_i;lgp=g_state_curr.min_h;}
      else{lgi=g_state_curr.min_l_i;lgp=g_state_curr.min_l;}
      DrawLine("LiveLeg",ST(time,g_state_curr.lp_i),g_state_curr.lp_p,ST(time,lgi),lgp,InpColorMin,1,STYLE_DOT);
   }

   if(InpShowStats&&li>0)
      BxDrawLabels(time[li]+(datetime)(PeriodSeconds()*2));

   // MTF Sinyal Paneli

   last_rates_tot=rates_total;
   return(rates_total);
}
//+------------------------------------------------------------------+

int OnInit() { IndicatorSetString(INDICATOR_SHORTNAME,"SMACv2_v30"); return INIT_SUCCEEDED; }
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,"Minor_");ObjectsDeleteAll(0,"Major_");ObjectsDeleteAll(0,"HLine_");
   ObjectsDeleteAll(0,"VL_");ObjectsDeleteAll(0,"Box_");ObjectsDeleteAll(0,"Live_");
   ObjectsDeleteAll(0,"BoxWkAbv_");ObjectsDeleteAll(0,"BoxWkBlw_");ObjectsDeleteAll(0,"BoxLbl_");
   BxClear(); Comment("");
}
