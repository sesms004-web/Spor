import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Replace inside bar logic in GetMTFPullback
mtf_search = """   for(int i = 1; i < copied; i++)
     {
      bool inside = (high[i] <= high[i-1]) && (low[i] >= low[i-1]);
      if(!inside)
        {"""

mtf_replace = """   st.mb_h = high[0];
   st.mb_l = low[0];
   st.mb_i = 0;

   for(int i = 1; i < copied; i++)
     {
      bool inside = (high[i] <= st.mb_h) && (low[i] >= st.mb_l);
      if(!inside)
        {
         // Dışarı çıktı, yeni mother bar olabilir
         if (high[i] > st.mb_h || low[i] < st.mb_l) {
            st.mb_h = high[i];
            st.mb_l = low[i];
            st.mb_i = i;
         }"""

content = content.replace(mtf_search, mtf_replace)

# Replace inside bar logic in OnCalculate
oncalc_search = """   for(int i = limit; i < rates_total - 1; i++)
     {
      bool inside = (high[i] <= high[i-1]) && (low[i] >= low[i-1]);
      if(!inside)
        {"""

oncalc_replace = """   if (prev_calculated == 0 && limit < rates_total) {
      g_state_hist.mb_h = high[limit-1];
      g_state_hist.mb_l = low[limit-1];
      g_state_hist.mb_i = limit-1;
   }

   for(int i = limit; i < rates_total - 1; i++)
     {
      bool inside = (high[i] <= g_state_hist.mb_h) && (low[i] >= g_state_hist.mb_l);

      // Outside bar handle: Eğer aynı barda hem high hem low kırıldıysa (çok nadir ama olur),
      // sadece trend yönündeki kırılımı baz almak için tam Mother Bar güncellemesini yap.
      if(!inside)
        {
         if (high[i] > g_state_hist.mb_h || low[i] < g_state_hist.mb_l) {
            g_state_hist.mb_h = high[i];
            g_state_hist.mb_l = low[i];
            g_state_hist.mb_i = i;
         }"""

content = content.replace(oncalc_search, oncalc_replace)

last_bar_search = """   bool inside_last = false;
   if(last_idx > 0)
     {
      inside_last = (high[last_idx] <= high[last_idx-1]) && (low[last_idx] >= low[last_idx-1]);
     }"""

last_bar_replace = """   bool inside_last = false;
   if(last_idx > 0)
     {
      inside_last = (high[last_idx] <= g_state_curr.mb_h) && (low[last_idx] >= g_state_curr.mb_l);
     }"""

content = content.replace(last_bar_search, last_bar_replace)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Mother Bar filtering applied")
