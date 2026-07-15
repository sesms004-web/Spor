import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Wait, let's verify if `GetCycleName` is used properly and there are no compilation syntax errors.
print("GetCycleName snippet:")
idx = content.find("GetCycleName")
if idx != -1:
    print(content[idx-50:idx+200])
