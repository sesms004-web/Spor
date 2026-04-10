import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # The actual strings have literal newlines `\n` without `\`, causing issues in MQL5 string literal matching. Let's fix this specific problem.
    # We will search for all lines between `string json = "{` and `json += "}";` and fix them.
    # Actually, we can just replace everything with the proper block.

    content = re.sub(r'string json = "\{.*?json \+= "\}";',
"""string json = "{\\n";
               json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
               json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";
               json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
               json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
               json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
               json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
               json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";
               json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";
               json += "}";""", content, flags=re.DOTALL)

    content = re.sub(r'string json = "\{.*?json \+= "\}";',
"""string json = "{\\n";
           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
           json += "  \\"direction\\": \\"BUY\\",\\n";
           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
           json += "  \\"is_strong\\": true,\\n";
           json += "  \\"is_test\\": true\\n";
           json += "}";""", content, count=1, flags=re.DOTALL) # The first one is the TEST trigger, wait the regex matching might be tricky because of the literal newlines.

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_code('mukemmeliyet.mq5')
