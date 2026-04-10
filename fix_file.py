import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # REMOVE OLD VARIABLES
    content = re.sub(r"input bool   InpEnableAutoTradeWriter  = true;.*?\n", "", content)
    content = re.sub(r"input int    InpMaxTradesPerSwing      = 2;.*?\n", "", content)
    content = re.sub(r"input double InpStrongSLMultiplier     = 1\.0;.*?\n", "", content)
    content = re.sub(r"input double InpWeakSLMultiplier       = 1\.5;.*?\n", "", content)
    content = re.sub(r"input double InpTPRewardRatio          = 3\.0;.*?\n", "", content)
    content = re.sub(r"input bool   InpForceTestSignal        = false;.*?\n", "", content)
    content = re.sub(r"//--- Trade Geometry \(SL/TP\) Settings ---\n", "", content)

    # REMOVE OLD AUTO-TRADE LOGIC
    # The old auto-trade block starts with `// --- AUTO-TRADE FILE WRITER LOGIC ---`
    # and ends just before `//+------------------------------------------------------------------+\n//| MTF Alert System (Smart Algorithmic Decision Engine)`
    pattern_remove_old_logic = r"   // --- AUTO-TRADE FILE WRITER LOGIC ---.*?(?=//\+------------------------------------------------------------------\+\n//\| MTF Alert System)"
    content = re.sub(pattern_remove_old_logic, "   }\n\n", content, flags=re.DOTALL)

    # REMOVE VIRTUAL TRADE GLOBALS
    pattern_virtual_globals = r"//--- Virtual Trade Tracking ---.*?double g_last_alert_maj_h = 0;"
    content = re.sub(pattern_virtual_globals, "double g_last_alert_maj_h = 0;", content, flags=re.DOTALL)

    # REMOVE VIRTUAL TRADE IN OnCalculate
    pattern_virtual_tracker = r"   // --- 🕵️‍♂️ VIRTUAL TRADE TRACKER \(Sanal SL/TP Kontrolü\) ---.*?(?=\n   if\(last_idx > 0 && \(Period\(\) == PERIOD_M1\)\))"
    content = re.sub(pattern_virtual_tracker, "", content, flags=re.DOTALL)

    # FIX JSON STRING NEWLINES
    content = content.replace("string json = \"{\n\";\n           json += \"  \\\"symbol\\\": \\\"\" + Symbol() + \"\\\",\n\";\n           json += \"  \\\"direction\\\": \\\"BUY\\\",\n\";\n           json += \"  \\\"entry\\\": \" + DoubleToString(entry, 5) + \",\n\";\n           json += \"  \\\"sl\\\": \" + DoubleToString(sl, 5) + \",\n\";\n           json += \"  \\\"tp\\\": \" + DoubleToString(tp, 5) + \",\n\";\n           json += \"  \\\"base_extreme\\\": \" + DoubleToString(ext_pt, 5) + \",\n\";\n           json += \"  \\\"is_strong\\\": true,\n\";\n           json += \"  \\\"is_test\\\": true\n\";\n           json += \"}\";",
        "string json = \"{\\n\";\n           json += \"  \\\"symbol\\\": \\\"\" + Symbol() + \"\\\",\\n\";\n           json += \"  \\\"direction\\\": \\\"BUY\\\",\\n\";\n           json += \"  \\\"entry\\\": \" + DoubleToString(entry, 5) + \",\\n\";\n           json += \"  \\\"sl\\\": \" + DoubleToString(sl, 5) + \",\\n\";\n           json += \"  \\\"tp\\\": \" + DoubleToString(tp, 5) + \",\\n\";\n           json += \"  \\\"base_extreme\\\": \" + DoubleToString(ext_pt, 5) + \",\\n\";\n           json += \"  \\\"is_strong\\\": true,\\n\";\n           json += \"  \\\"is_test\\\": true\\n\";\n           json += \"}\";")

    content = content.replace("string json = \"{\n\";\n               json += \"  \\\"symbol\\\": \\\"\" + Symbol() + \"\\\",\n\";\n               json += \"  \\\"direction\\\": \\\"\" + dir_str + \"\\\",\n\";\n               json += \"  \\\"entry\\\": \" + DoubleToString(entry, 5) + \",\n\";\n               json += \"  \\\"sl\\\": \" + DoubleToString(sl, 5) + \",\n\";\n               json += \"  \\\"tp\\\": \" + DoubleToString(tp, 5) + \",\n\";\n               json += \"  \\\"base_extreme\\\": \" + DoubleToString(ext_pt, 5) + \",\n\";\n               json += \"  \\\"is_strong\\\": \" + (is_strong ? \"true\" : \"false\") + \",\n\";\n               json += \"  \\\"is_test\\\": \" + (InpTestMode ? \"true\" : \"false\") + \"\n\";\n               json += \"}\";",
        "string json = \"{\\n\";\n               json += \"  \\\"symbol\\\": \\\"\" + Symbol() + \"\\\",\\n\";\n               json += \"  \\\"direction\\\": \\\"\" + dir_str + \"\\\",\\n\";\n               json += \"  \\\"entry\\\": \" + DoubleToString(entry, 5) + \",\\n\";\n               json += \"  \\\"sl\\\": \" + DoubleToString(sl, 5) + \",\\n\";\n               json += \"  \\\"tp\\\": \" + DoubleToString(tp, 5) + \",\\n\";\n               json += \"  \\\"base_extreme\\\": \" + DoubleToString(ext_pt, 5) + \",\\n\";\n               json += \"  \\\"is_strong\\\": \" + (is_strong ? \"true\" : \"false\") + \",\\n\";\n               json += \"  \\\"is_test\\\": \" + (InpTestMode ? \"true\" : \"false\") + \"\\n\";\n               json += \"}\";")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_code('mukemmeliyet.mq5')
