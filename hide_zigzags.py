import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Replace if(InpShowMin)DrawLine(...) with nothing, basically preventing them from being drawn during ProcessBar
content = re.sub(r'if\(InpShowMin\)DrawLine\([^;]+;', '', content)
# Wait, also InpShowMaj.
content = re.sub(r'if\(InpShowMaj\)DrawLine\([^;]+;', '', content)

# But wait, we also have InpShowMaj checking for HLine_Top_ and HLine_Bot_. Should we hide those too?
# "zikzak kısımları al filan ilk öncelikle onları gizle arkada çalışsın... 2 swing güncel olarak çizmeni istiyorum"
# I will hide ALL InpShowMin and InpShowMaj drawing from ProcessBar.
# It's safer to just set InpShowMin=false and InpShowMaj=false internally or override them in the Draw function.
# Wait, changing the input variable might be easier! But we can't change inputs in code in MQL5.
# Let's replace `InpShowMin` with `false` in `ProcessBar`, same for `InpShowMaj`.
# Let's do string replacement for the exact lines in ProcessBar.
