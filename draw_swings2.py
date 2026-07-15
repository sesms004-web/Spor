import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Let's see how OnCalculate looks.
print(re.search(r'int OnCalculate[\s\S]*?return rates_total;\n\}', content).group(0)[:500])
print("-----")
print(re.search(r'int OnCalculate[\s\S]*?return rates_total;\n\}', content).group(0)[-1000:])
