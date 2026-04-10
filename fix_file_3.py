import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # The issue is that the actual string in python `\n` translates to a literal newline when written,
    # and when I replaced it above, the regex didn't catch the literal newlines since I used `\n` in the string representation instead of actual multi-line strings.
    # Let's just fix all literal newlines inside quotes.

    # Simple replacement:
    content = content.replace('string json = "{\n";', 'string json = "{\\n";')
    content = content.replace('json += "  \\"symbol\\": \\"" + Symbol() + "\\",\n";', 'json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";')
    content = content.replace('json += "  \\"direction\\": \\"" + dir_str + "\\",\n";', 'json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";')
    content = content.replace('json += "  \\"direction\\": \\"BUY\\",\n";', 'json += "  \\"direction\\": \\"BUY\\",\\n";')
    content = content.replace('json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\n";', 'json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";')
    content = content.replace('json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\n";', 'json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";')
    content = content.replace('json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\n";', 'json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";')
    content = content.replace('json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\n";', 'json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";')
    content = content.replace('json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\n";', 'json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";')
    content = content.replace('json += "  \\"is_strong\\": true,\n";', 'json += "  \\"is_strong\\": true,\\n";')
    content = content.replace('json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\n";', 'json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";')
    content = content.replace('json += "  \\"is_test\\": true\n";', 'json += "  \\"is_test\\": true\\n";')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_code('mukemmeliyet.mq5')
