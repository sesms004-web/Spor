import re
with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

if "int g_cycle_cnt_min=0;" in content:
    print("Yes, it's there now!")
else:
    print("Still failed")
