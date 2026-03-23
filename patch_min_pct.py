import re
with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# I see it somehow reverted to 20.0 in my previous edits! I need to ensure it is 40.0.
search = """input double InpMinPullbackPct = 20.0;           // CHoCH Min Çekilme % (Onay Yüzdeliği)"""
replace = """input double InpMinPullbackPct = 40.0;           // CHoCH Min Çekilme % (Onay Yüzdeliği)"""

content = content.replace(search, replace)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)
print("Min pct patched to 40.0")
