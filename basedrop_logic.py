import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Add inputs for Base-Drop logic
inputs_to_add = """
//--- Base-Drop Kutu Mantığı
input double InpBigCandleMult = 2.0; // Şiddetli Mum Çarpanı
input int    InpBaseMaxCandles = 5;  // Maksimum Ufak Mum (Base) Sayısı
input int    InpBaseAvgLookback = 10; // Ortalama Gövde Bakma Süresi
"""

content = re.sub(r'(//--- Kutu\ninput bool   InpShowBox)', inputs_to_add + r'\n\1', content)

# Add the new CheckBaseDropBox function
base_drop_func = """
//=====================================================================
// Base-Drop Box Detection
//=====================================================================
void CheckBaseDropBox(int i, const double &open[], const double &high[], const double &low[], const double &close[], const datetime &time[], SState &state, string pfx)
{
   if(i < InpBaseAvgLookback + InpBaseMaxCandles) return;

   // Calculate average body size over recent candles (excluding current)
   double avg_body = 0;
   for(int j = 1; j <= InpBaseAvgLookback; j++) {
      avg_body += MathAbs(close[i-j] - open[i-j]);
   }
   avg_body /= InpBaseAvgLookback;

   if(avg_body == 0) return;

   double cur_body = MathAbs(close[i] - open[i]);

   // Check if current candle is a "Big Violent Candle"
   if(cur_body > avg_body * InpBigCandleMult) {
      bool is_bullish = close[i] > open[i];

      // Look back for "Base" (small candles)
      int base_start = i - 1;
      int base_count = 0;
      double box_top = -1, box_bot = -1;

      while(base_count < InpBaseMaxCandles && base_start >= 0) {
         double body = MathAbs(close[base_start] - open[base_start]);
         if(body < avg_body) {
            if(box_top == -1 || high[base_start] > box_top) box_top = high[base_start];
            if(box_bot == -1 || low[base_start] < box_bot) box_bot = low[base_start];
            base_count++;
            base_start--;
         } else {
            break;
         }
      }

      if(base_count > 0) {
         color box_clr = is_bullish ? InpColorBoxBull : InpColorBoxBear;
         // Adjust box logic to not use zigzag extremes since this is an independent OB
         // We call a simpler box draw or just use DoDrawBox. DoDrawBox has logic for adjusting bounds
         // based on maj_sz (major swing size) which might not fit well. Let's just bypass it.
         // Actually, DoDrawBox is fine if we just pass a fake state or we can just draw directly.
         // Since it adds to g_bx arrays, it's better to bypass DoDrawBox's trim logic if it's too restrictive,
         // but wait, DoDrawBox trims the box using InpMaxBoxPct relative to maj_sz.

         double top = box_top;
         double bot = box_bot;
         double wk_sz = (top - bot) * InpWeakZonePct / 100.0;
         color  wk_clr = is_bullish ? InpColorWeakBull : InpColorWeakBear;

         string nm = GetUniqueName(pfx + "OB_Box_");
         string wk_abv = GetUniqueName(pfx + "OB_BoxWkAbv_");
         string wk_blw = GetUniqueName(pfx + "OB_BoxWkBlw_");
         datetime t_left = GetTimeSafe(time, base_start + 1);

         DrawRect(nm, t_left, top, D'2099.12.31 00:00', bot, box_clr);
         DrawWeakRect(wk_abv, t_left, top + wk_sz, top, wk_clr);
         DrawWeakRect(wk_blw, t_left, bot, bot - wk_sz, wk_clr);

         BxAdd(nm, wk_abv, wk_blw, top, bot, false);
      }
   }
}
"""

content = re.sub(r'(//=====================================================================\n// MTF — Shadow Analiz)', base_drop_func + r'\n\1', content)

# Inject CheckBaseDropBox into ProcessBar
# We put it right at the beginning of ProcessBar or right after stats update.
process_bar_inj = """   BxUpdateStats(val_h,val_l,val_c,prev_c,time[i],is_history);

   // Base-Drop Kutusu
   if(InpShowBox) {
      CheckBaseDropBox(i, open, high, low, close, time, state, pfx);
   }
"""

content = re.sub(r'   BxUpdateStats\(val_h,val_l,val_c,prev_c,time\[i\],is_history\);\n', process_bar_inj, content)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
