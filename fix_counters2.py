import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Let's see what is actually in the file for GetCycleName
match = re.search(r'int g_cycle_cnt.*?\}', content, re.DOTALL)
if match:
    old_cycle = match.group(0)
    print("Found:\n", old_cycle)

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
    content = content.replace(old_cycle, new_cycle)
    with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
        f.write(content)
else:
    print("Could not find GetCycleName in file.")
