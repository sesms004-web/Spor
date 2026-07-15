import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Add GetCycleName function
cycle_name_func = """
int g_cycle_cnt = 0;
string GetCycleName(string pfx, int max_count)
{
   g_cycle_cnt++;
   return pfx + IntegerToString(g_cycle_cnt % max_count);
}
"""
content = re.sub(r'string GetUniqueName\(string prefix\)', cycle_name_func + '\nstring GetUniqueName(string prefix)', content)

# Now, we should use GetCycleName instead of GetUniqueName for Minor and Major lines in ProcessBar.
# Actually, it's safer to just replace `GetUniqueName(pfx+"Minor_")` with `GetCycleName(pfx+"Minor_", 2)`
# and `GetUniqueName(pfx+"Major_")` with `GetCycleName(pfx+"Major_", 2)`

content = content.replace('GetUniqueName(pfx+"Minor_")', 'GetCycleName(pfx+"Minor_", 2)')
content = content.replace('GetUniqueName(pfx+"Major_")', 'GetCycleName(pfx+"Major_", 2)')

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
