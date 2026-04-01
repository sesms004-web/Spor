# Fix the double % escape used in regex to standard MQL5 syntax
with open('denemevol2.mq5', 'r') as f:
    text = f.read()

text = text.replace("StringFormat(\"[Zirve:%%.1f | Çekilme:%%.1f] \",", "StringFormat(\"[Zirve:%.1f | Çekilme:%.1f] \",")

with open('denemevol2.mq5', 'w') as f:
    f.write(text)
