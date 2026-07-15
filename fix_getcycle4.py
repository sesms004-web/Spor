import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Make sure GetCycleName was actually added:
if "string GetCycleName" in content:
    print("GetCycleName exists.")
else:
    print("GetCycleName STILL missing.")
    # let's just append it after global variables
    content = re.sub(r'int g_counter=0;', r'int g_counter=0;\nint g_cycle_cnt=0;\nstring GetCycleName(string pfx, int max_count){g_cycle_cnt++;return pfx + IntegerToString(g_cycle_cnt % max_count);}', content)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
