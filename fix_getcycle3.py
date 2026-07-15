import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# I replaced `GetUniqueName(string p)` with `GetCycleName(string pfx, int max_count)` in my previous thought, but I failed to match the signature.
# It is actually `string GetUniqueName(string p){g_counter++;return p+IntegerToString(g_counter);}`
cycle_name_func = """
int g_cycle_cnt = 0;
string GetCycleName(string pfx, int max_count)
{
   g_cycle_cnt++;
   return pfx + IntegerToString(g_cycle_cnt % max_count);
}
"""
content = re.sub(r'string GetUniqueName\(string p\).*?\}', cycle_name_func + '\nstring GetUniqueName(string p){g_counter++;return p+IntegerToString(g_counter);}', content)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
