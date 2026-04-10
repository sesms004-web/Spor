import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Since I messed up the lines by replacing in place with wrong string, I will do a precise replace of the whole blocks.

block_manual = r"""           string json = "{\n";\n";
           json \+= "  \\"symbol\\": \\"" \+ Symbol\(\) \+ "\\",\n";
           json \+= "  \\"direction\\": \\"BUY\\",\n";
           json \+= "  \\"entry\\": " \+ DoubleToString\(entry, 5\) \+ ",\n";
           json \+= "  \\"sl\\": " \+ DoubleToString\(sl, 5\) \+ ",\n";
           json \+= "  \\"tp\\": " \+ DoubleToString\(tp, 5\) \+ ",\n";
           json \+= "  \\"base_extreme\\": " \+ DoubleToString\(ext_pt, 5\) \+ ",\n";
           json \+= "  \\"is_strong\\": true,\n";\n";
           json \+= "  \\"is_test\\": true\n";\n";
           json \+= "\}";"""

fixed_manual = """           string json = "{\\n";
           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
           json += "  \\"direction\\": \\"BUY\\",\\n";
           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
           json += "  \\"is_strong\\": true,\\n";
           json += "  \\"is_test\\": true\\n";
           json += "}";"""

text = re.sub(block_manual, fixed_manual, text)

block_auto = r"""               string json = "{\n";\n";
               json \+= "  \\"symbol\\": \\"" \+ Symbol\(\) \+ "\\",\n";
               json \+= "  \\"direction\\": \\"" \+ dir_str \+ "\\",\n";
               json \+= "  \\"entry\\": " \+ DoubleToString\(entry, 5\) \+ ",\n";
               json \+= "  \\"sl\\": " \+ DoubleToString\(sl, 5\) \+ ",\n";
               json \+= "  \\"tp\\": " \+ DoubleToString\(tp, 5\) \+ ",\n";
               json \+= "  \\"base_extreme\\": " \+ DoubleToString\(ext_pt, 5\) \+ ",\n";
               json \+= "  \\"is_strong\\": " \+ \(is_strong \? "true" : "false"\) \+ ",\n";
               json \+= "  \\"is_test\\": " \+ \(InpTestMode \? "true" : "false"\) \+ "\n";\n";
               json \+= "\}";"""

fixed_auto = """               string json = "{\\n";
               json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
               json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";
               json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
               json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
               json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
               json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
               json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";
               json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";
               json += "}";"""

text = re.sub(block_auto, fixed_auto, text)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
