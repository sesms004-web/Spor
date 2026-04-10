import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# I will literally replace every matching occurrence of the string piece by piece.
content = content.replace('"{\\n";', '"{_NEWLINE_";')
content = content.replace('"{\n";', '"{_NEWLINE_";')

content = content.replace('",\\n";', '",_NEWLINE_";')
content = content.replace('",\n";', '",_NEWLINE_";')

content = content.replace('true,\\n";', 'true,_NEWLINE_";')
content = content.replace('true,\n";', 'true,_NEWLINE_";')

content = content.replace('false,\\n";', 'false,_NEWLINE_";')
content = content.replace('false,\n";', 'false,_NEWLINE_";')

content = content.replace('true\\n";', 'true_NEWLINE_";')
content = content.replace('true\n";', 'true_NEWLINE_";')

content = content.replace('false\\n";', 'false_NEWLINE_";')
content = content.replace('false\n";', 'false_NEWLINE_";')

# Now put the literal back correctly
content = content.replace('_NEWLINE_', '\\n')

# And let's fix the auto-trade block in case it broke dir_str mapping
# Find: json += "  \"direction\": \"BUY\",\n"; in auto trade and revert to dir_str
# Actually, let's just make sure both blocks are 100% correct by string find
auto_trade_start = content.find('// --- YENİ AKILLI JSON AUTO-TRADE YAZICI ---')
if auto_trade_start != -1:
    wrong_buy = content.find('json += "  \\"direction\\": \\"BUY\\",\\n";', auto_trade_start)
    if wrong_buy != -1:
        # replace just the first occurrence
        content = content[:wrong_buy] + 'json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";' + content[wrong_buy+len('json += "  \\"direction\\": \\"BUY\\",\\n";'):]

# And check for is_strong being static true in auto-trade
if auto_trade_start != -1:
    wrong_strong = content.find('json += "  \\"is_strong\\": true,\\n";', auto_trade_start)
    if wrong_strong != -1:
        content = content[:wrong_strong] + 'json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";' + content[wrong_strong+len('json += "  \\"is_strong\\": true,\\n";'):]

    wrong_test = content.find('json += "  \\"is_test\\": true\\n";', auto_trade_start)
    if wrong_test != -1:
        content = content[:wrong_test] + 'json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";' + content[wrong_test+len('json += "  \\"is_test\\": true\\n";'):]


with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
