import re

with open('vol100.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Modify GetMTFPullback to run a lightweight version of ProcessBar
# First, add a lightweight ProcessBar that doesn't rely on drawing functions or SState entirely, but reuses SState logic with draw_ui=false.

# Wait, we already have ProcessBar that accepts SState and draw_ui!
# We can just instantiate a temporary SState inside GetMTFPullback and run ProcessBar over the copied rates!
# This is brilliant and re-uses exact same logic, ensuring perfect 1:1 parity with M1 structure.

new_get_mtf = """
bool GetMTFPullback(ENUM_TIMEFRAMES tf, int &trend, double &pct, double &max_pct, datetime current_time,
                    double live_price, double &ref_h, double &ref_l, datetime &ref_t_h, datetime &ref_t_l)
  {
   int bars = GetBarsForTF(tf);
   MqlRates rates[];
   ArraySetAsSeries(rates, false); // En eski bar = 0, en yeni = bars-1 (ProcessBar için döngü kolaylığı)

   int copied = CopyRates(Symbol(), tf, 0, bars, rates);
   if(copied < 10) return false;

   // Arka planda çalışacak geçici State objesi (Çizim YAPMAYACAK)
   SState sim_state;

   // Başlangıç değerlerini ilk barlara göre ayarla
   sim_state.min_h   = rates[0].high;
   sim_state.min_h_i = 0;
   sim_state.min_l   = rates[0].low;
   sim_state.min_l_i = 0;
   sim_state.trig_h  = rates[0].high;
   sim_state.trig_l  = rates[0].low;
   sim_state.tmp_h   = rates[0].high;
   sim_state.tmp_h_i = 0;
   sim_state.tmp_l   = rates[0].low;
   sim_state.tmp_l_i = 0;
   sim_state.min_tr  = (rates[0].close > rates[0].open) ? 1 : -1;
   sim_state.anc_i   = 0;
   sim_state.anc_v   = rates[0].close;
   sim_state.lp_i    = 0;
   sim_state.lp_p    = rates[0].close;

   sim_state.mb_h = rates[0].high;
   sim_state.mb_l = rates[0].low;
   sim_state.mb_i = 0;

   sim_state.t1_h = 0; sim_state.t1_l = 0; sim_state.t1_i = 0;
   sim_state.d1_h = 0; sim_state.d1_l = 0; sim_state.d1_i = 0;
   sim_state.t2_h = 0; sim_state.t2_l = 0; sim_state.t2_i = 0;
   sim_state.choch_dir = 0;

   double initial_atr = (rates[0].high - rates[0].low);
   if(initial_atr == 0) initial_atr = Point() * 10;
   double tiny_gap = initial_atr * 0.1;

   sim_state.maj_h = rates[0].high + tiny_gap;
   sim_state.maj_l = rates[0].low - tiny_gap;
   sim_state.maj_tr = sim_state.min_tr;
   sim_state.maj_st = 1;
   sim_state.bos_i = 0;

   sim_state.maj_h_i = 0;
   sim_state.maj_l_i = 0;

   // ProcessBar fonksiyonunun imzasını kopyalamak için geçici diziler
   double open_arr[], high_arr[], low_arr[], close_arr[];
   datetime time_arr[];
   ArrayResize(open_arr, copied);
   ArrayResize(high_arr, copied);
   ArrayResize(low_arr, copied);
   ArrayResize(close_arr, copied);
   ArrayResize(time_arr, copied);

   for(int i = 0; i < copied; i++) {
       open_arr[i]  = rates[i].open;
       high_arr[i]  = rates[i].high;
       low_arr[i]   = rates[i].low;
       close_arr[i] = rates[i].close;
       time_arr[i]  = rates[i].time;
   }

   // Barları simüle et
   for(int i = 1; i < copied; i++)
     {
      bool inside = (high_arr[i] <= sim_state.mb_h) && (low_arr[i] >= sim_state.mb_l);
      if(!inside)
        {
         if (high_arr[i] > sim_state.mb_h || low_arr[i] < sim_state.mb_l) {
            sim_state.mb_h = high_arr[i];
            sim_state.mb_l = low_arr[i];
            sim_state.mb_i = i;
         }
         // draw_ui = false olarak çağırıyoruz, grafiğe obje çizmez!
         ProcessBar(i, open_arr, high_arr, low_arr, close_arr, time_arr, sim_state, true, false);
        }
     }

   // Simülasyon bitti, son durumu çek
   trend = sim_state.maj_tr;

   ref_h = sim_state.maj_h;
   ref_l = sim_state.maj_l;
   ref_t_h = time_arr[sim_state.maj_h_i];
   ref_t_l = time_arr[sim_state.maj_l_i];

   pct = 0.0;
   max_pct = 0.0;

   if (ref_h != EMPTY_VALUE && ref_l != EMPTY_VALUE && ref_h != ref_l) {
       double range = ref_h - ref_l;
       if (trend == 1) { // BUY Trend
           // Anlık çekilme
           pct = ((ref_h - live_price) / range) * 100.0;
           // Max çekilme (tepeden bugüne kadarki en derin nokta)
           // Hangi index'ten tarayacağız? Son oluşan tepeden (maj_h_i) günümüze
           double local_lowest = rates[copied-1].low;
           for(int i = sim_state.maj_h_i; i < copied; i++) {
               if(low_arr[i] < local_lowest) local_lowest = low_arr[i];
           }
           max_pct = ((ref_h - local_lowest) / range) * 100.0;

           if (live_price >= ref_h) pct = 0;
       } else { // SELL Trend
           // Anlık çekilme
           pct = ((live_price - ref_l) / range) * 100.0;
           // Max çekilme (dipten bugüne kadarki en yüksek nokta)
           // Hangi index'ten tarayacağız? Son oluşan dipten (maj_l_i) günümüze
           double local_highest = rates[copied-1].high;
           for(int i = sim_state.maj_l_i; i < copied; i++) {
               if(high_arr[i] > local_highest) local_highest = high_arr[i];
           }
           max_pct = ((local_highest - ref_l) / range) * 100.0;

           if (live_price <= ref_l) pct = 0;
       }
   }

   if(pct < 0) pct = 0;
   if(max_pct < pct) max_pct = pct;

   return true;
  }
"""

# Replace the old GetMTFPullback block
pattern = r"bool GetMTFPullback\(ENUM_TIMEFRAMES tf,.*?return true;\n  \}"
content = re.sub(pattern, new_get_mtf.strip(), content, flags=re.DOTALL)

with open('vol100.mq5', 'w', encoding='utf-8') as f:
    f.write(content)

print("Patch applied successfully.")
