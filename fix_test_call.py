import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the GetMTFPullback call in TEST TRIGGER EXECUTION block
pattern = r'           // Milimetrik olarak diğer grafikleri de besleyen ANA fonksiyonu çağır\n           GetMTFPullback\(PERIOD_M1, live_tr, live_pct, dmy_mpct, time\[last_idx\], dmy_h, dmy_l, dmy_th, dmy_tl\);\n           \n           double bid = SymbolInfoDouble\(Symbol\(\), SYMBOL_BID\);'

replacement = """           double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

           // Milimetrik olarak diğer grafikleri de besleyen ANA fonksiyonu çağır
           GetMTFPullback(PERIOD_M1, live_tr, live_pct, dmy_mpct, time[last_idx], bid, dmy_h, dmy_l, dmy_th, dmy_tl);"""

text = re.sub(pattern, replacement, text)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
