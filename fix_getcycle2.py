import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

cycle_name_func = """
int g_cycle_cnt = 0;
string GetCycleName(string pfx, int max_count)
{
   g_cycle_cnt++;
   return pfx + IntegerToString(g_cycle_cnt % max_count);
}
"""

content = content.replace("string GetUniqueName(string prefix)", cycle_name_func + "\nstring GetUniqueName(string prefix)")

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
