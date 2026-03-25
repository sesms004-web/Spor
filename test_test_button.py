import re

with open('denemevol1.mq5', 'r') as f:
    text = f.read()

# Let's check the test trigger specifically
search = re.search(r'// TEST TRIGGER.*?EvaluateTradeSignal\(.*?\);', text, re.DOTALL)
if search:
    print(search.group(0))
