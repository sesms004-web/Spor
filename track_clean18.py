with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Verify that EvaluateTradeSignal looks correct
idx = text.find('void EvaluateTradeSignal')
print(text[idx+1800:idx+2500])
