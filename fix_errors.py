import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# 1. Fix GetCycleName logic
# We need separate counters for Minor and Major. We can use a simple map or hardcoded logic.
cycle_func_new = """
int g_cycle_cnt_min = 0;
int g_cycle_cnt_maj = 0;
string GetCycleName(string pfx, int max_count)
{
   if(StringFind(pfx, "Minor") >= 0) {
      g_cycle_cnt_min++;
      return pfx + IntegerToString(g_cycle_cnt_min % max_count);
   } else if(StringFind(pfx, "Major") >= 0) {
      g_cycle_cnt_maj++;
      return pfx + IntegerToString(g_cycle_cnt_maj % max_count);
   }
   g_cycle_cnt++;
   return pfx + IntegerToString(g_cycle_cnt % max_count);
}
"""
content = re.sub(r'int g_cycle_cnt\s*=\s*0;\nstring GetCycleName\(string pfx, int max_count\)\s*\{\s*g_cycle_cnt\+\+;\s*return pfx \+ IntegerToString\(g_cycle_cnt % max_count\);\s*\}', cycle_func_new, content)


# 2. Fix ShdBxAdvanceTrim orphaned brackets
# Let's just completely replace it to be sure.
shd_trim_full = """void ShdBxAdvanceTrim()
{
   for(int k=0;k<g_shd_cnt;k++){
      if(g_shd_state[k]==1){
         if(g_shd_touch[k]>0){
            g_shd_state[k]=0;
         }
      }
      else if(g_shd_state[k]==2)g_shd_state[k]=1;
   }
}"""
content = re.sub(r'void ShdBxAdvanceTrim\(\)\s*\{.*?\}\s*\}', shd_trim_full, content, flags=re.DOTALL)


# 3. Fix orphaned `else if` in ProcessBar
# I commented out `if(state.bx_phase==0||state.bx_phase==2) {DoDrawBox...}` in `ProcessBar` previously.
# But wait, looking back at the original code, there was an `else if` attached to it?
# Original code:
# if(state.bx_phase==0||state.bx_phase==2){DoDrawBox(...);...}
# Let's check what was around it.
