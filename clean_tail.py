import re

with open('SwingYapisi.mqh', 'r') as f:
    text = f.read()

idx = text.find('//+------------------------------------------------------------------+')
if idx != -1:
    text = text[:idx]

with open('SwingYapisi.mqh', 'w') as f:
    f.write(text)
