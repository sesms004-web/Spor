import re
with open('smcvol01.mq5', 'r') as f:
    text = f.read()

m = re.search(r'string sup_text = "\\n🛡️ DESTEKLEYİCİ YAPILAR & CEZALAR:\\n";', text)
print("Found declaration:", bool(m))
if m:
    print(text[m.start():m.end()+300])
