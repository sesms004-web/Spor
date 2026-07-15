import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Wait, I didn't verify if I added GetCycleName correctly.
if "string GetCycleName" in content:
    print("GetCycleName exists")
else:
    print("GetCycleName NOT found!")
