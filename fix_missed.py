import re
with open("Nasilsin_Indicator.mq5", "r") as f:
    text = f.read()

# Make sure we don't have missing variables in OnCalculate that were removed but still needed by GetMTFPullback etc
text = text.replace("bool g_level1_missed = false;\nbool g_level2_missed = false;\n", "")
text = text.replace("g_level1_missed = false;\n      g_level2_missed = false;\n", "")

# In TriggerMTFAlert, remove the "is_revisit=false" parameter if it exists
def replace_mtf(match):
    return """bool TriggerMTFAlert(int bar_idx, datetime t, double price, int trigger_lvl)"""

text = re.sub(r"bool TriggerMTFAlert\(int bar_idx, datetime t, double price, int trigger_lvl, bool is_revisit=false\)", replace_mtf, text)

# In the body of TriggerMTFAlert, remove revisit texts
def replace_revisit_body(match):
    return """string lvl_str = IntegerToString(trigger_lvl == 1 ? InpTriggerLevel1 : InpTriggerLevel2);"""

text = re.sub(r"string lvl_str = IntegerToString\(trigger_lvl == 1 \? InpTriggerLevel1 : InpTriggerLevel2\);\n\s*if\(is_revisit\) lvl_str \+= \" \(Re-visit\)\";", replace_revisit_body, text)

with open("Nasilsin_Indicator.mq5", "w") as f:
    f.write(text)
