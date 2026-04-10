import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. FIX MANUEL TEST BLOCK
pattern_manual = r'(// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---.*?string json = "\{\n";\n.*?json \+= "\}";)'
replacement_manual = r"""// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---
   if (InpForceTestSignal) {
       Print("🧪 [TEST SİNYALİ] Gönderiliyor...");
       string filename = "signal_" + Symbol() + ".json";
       int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
       if (file_handle != INVALID_HANDLE) {
           double entry = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
           double point_size = Point();

           // Sahte bir BUY işlemi simüle edelim:
           double sl = entry - (InpTestManualSLDistance * point_size);
           double tp = entry + ((entry - sl) * InpTPRewardRatio);
           double ext_pt = entry - ((InpTestManualSLDistance * point_size) / InpStrongSLMultiplier);

           string json = "{\\n";
           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
           json += "  \\"direction\\": \\"BUY\\",\\n";
           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
           json += "  \\"is_strong\\": true,\\n";
           json += "  \\"is_test\\": true\\n";
           json += "}";"""

text = re.sub(pattern_manual, replacement_manual, text, flags=re.DOTALL)

# 2. FIX AUTO TRADE BLOCK
pattern_auto = r'(           string filename = "signal_" \+ Symbol\(\) \+ "\.json";\n               string json = "\{\n";\n.*?json \+= "\}";)'
replacement_auto = r"""           string filename = "signal_" + Symbol() + ".json";
           int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
           if (file_handle != INVALID_HANDLE) {
               string json = "{\\n";
               json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
               json += "  \\"direction\\": \\"" + dir_str + "\\",\\n";
               json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
               json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
               json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
               json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
               json += "  \\"is_strong\\": " + (is_strong ? "true" : "false") + ",\\n";
               json += "  \\"is_test\\": " + (InpTestMode ? "true" : "false") + "\\n";
               json += "}";"""

text = re.sub(r'           string filename = "signal_" \+ Symbol\(\) \+ "\.json";.*?json \+= "\}";', replacement_auto, text, flags=re.DOTALL)


with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
