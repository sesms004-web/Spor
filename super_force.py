import os

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Finding the exact block
start_idx = text.find('// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---')
end_idx = text.find('FileWrite(file_handle, json);', start_idx)

if start_idx != -1 and end_idx != -1:
    new_text = """// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---
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
           double ext_pt = entry - ((InpTestManualSLDistance * point_size) / InpStrongSLMultiplier); // Tersine mühendislik ile base extreme bulalım

           string json = "{\\n";
           json += "  \\"symbol\\": \\"" + Symbol() + "\\",\\n";
           json += "  \\"direction\\": \\"BUY\\",\\n";
           json += "  \\"entry\\": " + DoubleToString(entry, 5) + ",\\n";
           json += "  \\"sl\\": " + DoubleToString(sl, 5) + ",\\n";
           json += "  \\"tp\\": " + DoubleToString(tp, 5) + ",\\n";
           json += "  \\"base_extreme\\": " + DoubleToString(ext_pt, 5) + ",\\n";
           json += "  \\"is_strong\\": true,\\n";
           json += "  \\"is_test\\": true\\n";
           json += "}";

           """
    text = text[:start_idx] + new_text + text[end_idx:]

start_idx_2 = text.find('string filename = "signal_" + Symbol() + ".json";')
end_idx_2 = text.find('FileWrite(file_handle, json);', start_idx_2)
if start_idx_2 != -1 and end_idx_2 != -1:
    new_text_2 = """string filename = "signal_" + Symbol() + ".json";
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
               json += "}";

               """
    text = text[:start_idx_2] + new_text_2 + text[end_idx_2:]


with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
