import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Hardcoded replacement
bad_test_str = """           string json = "{\\n";
           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
           json += "  \\"direction\\": \\"BUY\\",\\n";
           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
           json += "  \\"is_strong\\": true,\\n";
           json += "  \\"is_test\\": true\\n";
           json += "}";"""

bad_test_str_literal = bad_test_str.replace('\\n', '\n').replace('\\"', '"')

good_test_str = """           string json = "{\\n";
           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
           json += "  \\"direction\\": \\"BUY\\",\\n";
           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
           json += "  \\"is_strong\\": true,\\n";
           json += "  \\"is_test\\": true\\n";
           json += "}";"""

text = text.replace(bad_test_str_literal, good_test_str)

bad_auto_str_literal = """               string json = "{\n";
               json += "  \"symbol\": \"" + Symbol() + "\",\n";
               json += "  \"direction\": \"" + dir_str + "\",\n";
               json += "  \"entry\": " + DoubleToString(entry, 5) + ",\n";
               json += "  \"sl\": " + DoubleToString(sl, 5) + ",\n";
               json += "  \"tp\": " + DoubleToString(tp, 5) + ",\n";
               json += "  \"base_extreme\": " + DoubleToString(ext_pt, 5) + ",\n";
               json += "  \"is_strong\": " + (is_strong ? "true" : "false") + ",\n";
               json += "  \"is_test\": " + (InpTestMode ? "true" : "false") + "\n";
               json += "}";"""

good_auto_str = """               string json = "{\\n";
               json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
               json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";
               json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
               json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
               json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
               json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
               json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";
               json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";
               json += "}";"""

text = text.replace(bad_auto_str_literal, good_auto_str)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
