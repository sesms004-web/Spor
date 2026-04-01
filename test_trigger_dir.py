import re

with open('denemevol1.mq5', 'r') as f:
    text = f.read()

# Let's check where EvaluateTradeSignal is called and what is passed as trigger_dir
search = re.findall(r'EvaluateTradeSignal\(.*?\)', text)
for s in search:
    print(s)
