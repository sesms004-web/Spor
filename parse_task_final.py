import re

with open("smacv2.mq5", "r", encoding="utf-8") as f:
    code = f.read()

# Requirements:
# 1. "İlk önce choch kırılimi ile gelen kısmdaki yapilar cezalar kısmını komple temizle"
# In EvaluateTradeSignal, we currently have `sup_text` populated by the `GenerateMTFChochReport` logic! Wait, what does the code actually have right now? Let's check exactly what is in EvaluateTradeSignal!
