import re

with open('vol100.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Let's fix GetMTFPullback boundary conditions
# Old logic:
#            if (live_price >= ref_h) pct = 0;
# New logic:
#            if (live_price >= ref_h) { pct = 0; max_pct = 0; }
# Same for bearish. But we need to be careful with max_pct tracking if we are currently breaking out.

# Currently, in GetMTFPullback:
#        if (trend == 1) { // BUY Trend
#            pct = ((ref_h - live_price) / range) * 100.0;
#            double local_lowest = rates[copied-1].low;
#            for(int i = maj_h_idx; i < copied; i++) {
#                if(low_arr[i] < local_lowest) local_lowest = low_arr[i];
#            }
#            max_pct = ((ref_h - local_lowest) / range) * 100.0;
#            if (live_price >= ref_h) pct = 0;

target_pattern = r"""       if \(trend == 1\) \{ // BUY Trend
           pct = \(\(ref_h - live_price\) / range\) \* 100\.0;
           double local_lowest = rates\[copied-1\]\.low;
           for\(int i = maj_h_idx; i < copied; i\+\+\) \{
               if\(low_arr\[i\] < local_lowest\) local_lowest = low_arr\[i\];
           \}
           max_pct = \(\(ref_h - local_lowest\) / range\) \* 100\.0;
           if \(live_price >= ref_h\) pct = 0;
       \} else \{ // SELL Trend
           pct = \(\(live_price - ref_l\) / range\) \* 100\.0;
           double local_highest = rates\[copied-1\]\.high;
           for\(int i = maj_l_idx; i < copied; i\+\+\) \{
               if\(high_arr\[i\] > local_highest\) local_highest = high_arr\[i\];
           \}
           max_pct = \(\(local_highest - ref_l\) / range\) \* 100\.0;
           if \(live_price <= ref_l\) pct = 0;
       \}"""

new_logic = """       if (trend == 1) { // BUY Trend
           pct = ((ref_h - live_price) / range) * 100.0;
           double local_lowest = rates[copied-1].low;
           for(int i = maj_h_idx; i < copied; i++) {
               if(low_arr[i] < local_lowest) local_lowest = low_arr[i];
           }
           max_pct = ((ref_h - local_lowest) / range) * 100.0;

           // Kırılım (Breakout) Durumu SIFIRLAMA
           // Eğer canlı fiyat, güncel onaylı tepemizi (maj_h) çoktan aştıysa (kırdıysa),
           // ortada bir "çekilme" kalmamıştır, yeni bir dalga yapıyordur. Yüzdeleri tamamen SIFIRLA.
           if (live_price >= ref_h) { pct = 0; max_pct = 0; }
       } else { // SELL Trend
           pct = ((live_price - ref_l) / range) * 100.0;
           double local_highest = rates[copied-1].high;
           for(int i = maj_l_idx; i < copied; i++) {
               if(high_arr[i] > local_highest) local_highest = high_arr[i];
           }
           max_pct = ((local_highest - ref_l) / range) * 100.0;

           // Kırılım (Breakout) Durumu SIFIRLAMA
           if (live_price <= ref_l) { pct = 0; max_pct = 0; }
       }"""

content = re.sub(target_pattern, new_logic, content)

with open('vol100.mq5', 'w', encoding='utf-8') as f:
    f.write(content)

print("Pullback reset logic on breakout successfully applied.")
