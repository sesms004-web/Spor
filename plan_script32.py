import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# The user is complaining "Gereksiz şekilde kutularin uzunluğu sınırsız oldu".
# If the boxes are truly infinite on their screen, it means `BxAdvanceTrim` is NOT trimming them.
# `BxAdvanceTrim` is called like this: `BxAdvanceTrim(GetTimeSafe(time,state.maj_h_i));`
# Where does it get called?
# Inside `ProcessBar`, when `val_l<act` and `state.maj_st==0` etc.
# Wait, did I mess up anything inside `ProcessBar` when replacing the `EvaluateTradeSignal` block?
# Let's check `patch_choch_style_fix.py` again.
# Did I accidentally delete a bracket or change the block structure?
match = re.search(r"// Trade signal validation.*?if\(isn\)ld1b=state\.d1_i;", code, re.DOTALL)
if match:
    print(match.group(0))
