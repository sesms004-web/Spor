import sys
with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's verify `GetMTFPullback` signature
signature = text[text.find('bool GetMTFPullback'):text.find('{', text.find('bool GetMTFPullback'))]
print("Signature:", signature)
