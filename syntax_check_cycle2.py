import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Did my regex replace work? Let's check
if "int g_cycle_cnt_min=0;" in content:
    print("Yes, separate counters are present!")
else:
    print("NO, regex failed.")
