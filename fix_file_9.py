def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # The manual test JSON block is malformed (indentation issue and missing context).
    # Let's fix it fully using regex.
    import re

    # Let's find the `string filename = "signal_" + Symbol() + ".json";` inside the `InpForceTestSignal` block
    # and replace the whole block until `FileWrite`

    # Replace the manual JSON
    content = re.sub(
        r'           string filename = "signal_" \+ Symbol\(\) \+ "\.json";\n               string json = "\{\\\\n";\n           json \+= "  \\"symbol\\": \\"" \+ Symbol\(\) \+ "\\",\\\\n";\n           json \+= "  \\"direction\\": \\"BUY\\",\\\\n";\n           json \+= "  \\"entry\\": " \+ DoubleToString\(entry, 5\) \+ ",\\\\n";\n           json \+= "  \\"sl\\": " \+ DoubleToString\(sl, 5\) \+ ",\\\\n";\n           json \+= "  \\"tp\\": " \+ DoubleToString\(tp, 5\) \+ ",\\\\n";\n           json \+= "  \\"base_extreme\\": " \+ DoubleToString\(ext_pt, 5\) \+ ",\\\\n";\n           json \+= "  \\"is_strong\\": true,\\\\n";\n           json \+= "  \\"is_test\\": true\\\\n";\n           json \+= "\}";',
        r'           string filename = "signal_" + Symbol() + ".json";\n           string json = "{\\n";\n           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";\n           json += "  \\"direction\\": \\"BUY\\",\\n";\n           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";\n           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";\n           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";\n           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";\n           json += "  \\"is_strong\\": true,\\n";\n           json += "  \\"is_test\\": true\\n";\n           json += "}";',
        content
    )

    # Replace the auto trade JSON
    content = re.sub(
        r'       string filename = "signal_" \+ Symbol\(\) \+ "\.json";\n           string json = "\{\\\\n";\n               json \+= "  \\"symbol\\": \\"" \+ Symbol\(\) \+ "\\",\\\\n";\n               json \+= "  \\"direction\\": \\"" \+ dir_str \+ "\\",\\\\n";\n               json \+= "  \\"entry\\": " \+ DoubleToString\(entry, 5\) \+ ",\\\\n";\n               json \+= "  \\"sl\\": " \+ DoubleToString\(sl, 5\) \+ ",\\\\n";\n               json \+= "  \\"tp\\": " \+ DoubleToString\(tp, 5\) \+ ",\\\\n";\n               json \+= "  \\"base_extreme\\": " \+ DoubleToString\(ext_pt, 5\) \+ ",\\\\n";\n               json \+= "  \\"is_strong\\": " \+ \(is_strong \? "true" : "false"\) \+ ",\\\\n";\n               json \+= "  \\"is_test\\": " \+ \(InpTestMode \? "true" : "false"\) \+ "\\\\n";\n               json \+= "\}";',
        r'           string filename = "signal_" + Symbol() + ".json";\n           string json = "{\\n";\n           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";\n           json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";\n           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";\n           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";\n           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";\n           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";\n           json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";\n           json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";\n           json += "}";',
        content
    )

    with open(filepath, 'w') as f:
        f.write(content)

fix_file('mukemmeliyet.mq5')
