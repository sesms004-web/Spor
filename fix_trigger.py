with open("Nasilsin_Indicator.mq5", "r") as f:
    text = f.read()

text = text.replace("bool TriggerMTFAlert(int current_bar_i, datetime t, double live_price, int triggered_level, bool is_revisit=false)", "bool TriggerMTFAlert(int current_bar_i, datetime t, double live_price, int triggered_level)")

import re
def remove_revisit_str(match):
    return """string lvl_str = IntegerToString(triggered_level == 1 ? InpTriggerLevel1 : InpTriggerLevel2);"""

text = re.sub(r"string lvl_str = IntegerToString\(triggered_level == 1 \? InpTriggerLevel1 : InpTriggerLevel2\);\n\s*if\(is_revisit\) lvl_str \+= \" \(Re-visit\)\";", remove_revisit_str, text)

with open("Nasilsin_Indicator.mq5", "w") as f:
    f.write(text)
