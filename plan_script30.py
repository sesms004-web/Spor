import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# "Gereksiz sekilde kutularin uzunlugu sinirsiz oldu"
# Wait! In `EvaluateTradeSignal`, I added a loop over boxes:
# `for(int k=g_bx_cnt-1; k>=0 && box_count<4; k--)`
# This doesn't modify anything.
# What if the user is complaining about the boxes I added to `BxAdd`?
# In `BxAdd`, I did not change the length.
# Did I accidentally break `BxAdvanceTrim` because I changed `g_shd_dir` etc in `BxAdd`?
# NO.
# Let's check `patch_choch_color_length.py` changes.
# `code = code.replace("PeriodSeconds()*5", "PeriodSeconds()*10")`
# Were there any `PeriodSeconds()*5` in `DoDrawBox` or somewhere else?
# Let's search `PeriodSeconds()*10` in `misyoner001.mq5`.

print("Finding PeriodSeconds()*10")
for i, line in enumerate(code.split("\n")):
    if "PeriodSeconds()*10" in line:
        print(i+1, line.strip())
