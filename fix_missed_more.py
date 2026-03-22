with open("Nasilsin_Indicator.mq5", "r") as f:
    text = f.read()

text = text.replace("g_level1_missed = false;", "")
text = text.replace("g_level2_missed = false;", "")
text = text.replace("bool g_level1_missed = false;", "")
text = text.replace("bool g_level2_missed = false;", "")
text = text.replace("bool TriggerMTFAlert(int bar_idx, datetime t, double price, int trigger_lvl, bool is_revisit=false)", "bool TriggerMTFAlert(int bar_idx, datetime t, double price, int trigger_lvl)")

with open("Nasilsin_Indicator.mq5", "w") as f:
    f.write(text)
