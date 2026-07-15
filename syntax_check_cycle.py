import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Let's verify my GetCycleName. I DID put separate counters!
cycle_code = re.search(r'int g_cycle_cnt_min.*\}', content, re.DOTALL)
if cycle_code:
    print(cycle_code.group(0))
else:
    print("Could not find the separate counters I thought I added!")
