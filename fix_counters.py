import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Replace old single counter with separate ones
old_cycle = r'int g_cycle_cnt=0;\nstring GetCycleName\(string pfx, int max_count\)\{g_cycle_cnt\+\+;return pfx \+ IntegerToString\(g_cycle_cnt % max_count\);\}'
new_cycle = """int g_cycle_cnt_min=0;
int g_cycle_cnt_maj=0;
int g_cycle_cnt=0;
string GetCycleName(string pfx, int max_count){
   if(StringFind(pfx, "Minor") >= 0) {
      g_cycle_cnt_min++;
      return pfx + IntegerToString(g_cycle_cnt_min % max_count);
   } else if(StringFind(pfx, "Major") >= 0) {
      g_cycle_cnt_maj++;
      return pfx + IntegerToString(g_cycle_cnt_maj % max_count);
   }
   g_cycle_cnt++;
   return pfx + IntegerToString(g_cycle_cnt % max_count);
}"""

content = re.sub(old_cycle, new_cycle, content)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
