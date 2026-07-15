import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Let's see how many DrawLine calls use InpShowMin or InpShowMaj
lines = content.split('\n')
for line in lines:
    if 'InpShowMin' in line and 'DrawLine' in line:
        pass # print(line.strip())
    if 'InpShowMaj' in line and 'DrawLine' in line:
        pass # print(line.strip())

# We can just draw the last 2 swings in OnCalculate!
# But to stop ProcessBar from drawing all historical ones, we can just change ProcessBar to not draw them.
# The user wants "2 swing güncel olarak çizmeni istiyorum".
# The minor structure is kept in g_state_curr.min_h, min_h_i, min_l, min_l_i, lp_i, lp_p.
# Actually, the past swings are in g_state_curr.st_h and g_state_curr.st_l!
# Wait, for Minor, they don't have st_h and st_l. Those are for Major!
# So where is the history of Minor swings kept?
# ProcessBar just draws them and forgets them!
# "if(InpShowMin)DrawLine(GetUniqueName(pfx+"Minor_"),...);"

# If we just want to show the LAST 2 swings of minor, we can change the name from `GetUniqueName(pfx+"Minor_")` to a fixed set of names that cycle.
# In `ProcessBar`, replace `GetUniqueName(pfx+"Minor_")` with something that returns just "Minor_1" and "Minor_2" alternatingly?
# But `GetUniqueName` appends `_` and a counter!
# If we replace `GetUniqueName(pfx+"Minor_")` with `GetCycleName(pfx+"Minor_", 2)`, it would overwrite older lines automatically!
