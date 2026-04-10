import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Completely rewrite the manual JSON string building code using format
pattern1 = r'           string json = "\{\n";.*?           json \+= "  \\"is_test\\": true\n";'
replacement1 = """           string json = "{\\n";
           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
           json += "  \\"direction\\": \\"BUY\\",\\n";
           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
           json += "  \\"is_strong\\": true,\\n";
           json += "  \\"is_test\\": true\\n";
           json += "}";"""

content = re.sub(pattern1, replacement1, content, flags=re.DOTALL)


# Completely rewrite the auto trade JSON string building code using format
pattern2 = r'               string json = "\{\n";.*?               json \+= "  \\"is_test\\": " \+ \(InpTestMode \? "true" : "false"\) \+ "\n";'
replacement2 = """               string json = "{\\n";
               json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
               json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";
               json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
               json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
               json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
               json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
               json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";
               json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";
               json += "}";"""

content = re.sub(pattern2, replacement2, content, flags=re.DOTALL)


with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
