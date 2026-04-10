import re

def update_code(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add back InpForceTestSignal variable
    input_test_signal = "\ninput bool   InpForceTestSignal       = false;      // ⚠️ [TEST] Ortak Klasöre Manuel Deneme Sinyali Atar\n"
    content = content.replace("input double InpTestManualSLDistance  = 100.0;      // 🧪 Test SL Mesafesi (Point Cinsinden, Örn: 100)\n",
                              "input double InpTestManualSLDistance  = 100.0;      // 🧪 Test SL Mesafesi (Point Cinsinden, Örn: 100)\n" + input_test_signal)

    # 2. Fix the MANUEL TEST SIGNAL block (it got replaced with the auto trade json variables accidentally)
    # The block inside InpForceTestSignal should use hardcoded "BUY", true instead of dir_str and is_strong
    pattern_manual_test = r'(// --- 🧪 MANUEL TEST SİNYALİ FIRLATICI ---.*?string json = "\{\\\\n";\n\n).*?(\n           FileWrite\(file_handle, json\);)'

    correct_manual_test_json = r"""               json += "  \"symbol\": \"" + Symbol() + "\",\\n";
               json += "  \"direction\": \"BUY\",\\n";
               json += "  \"entry\": " + DoubleToString(entry, 5) + ",\\n";
               json += "  \"sl\": " + DoubleToString(sl, 5) + ",\\n";
               json += "  \"tp\": " + DoubleToString(tp, 5) + ",\\n";
               json += "  \"base_extreme\": " + DoubleToString(ext_pt, 5) + ",\\n";
               json += "  \"is_strong\": true,\\n";
               json += "  \"is_test\": true\\n";
               json += "}";"""

    content = re.sub(pattern_manual_test, r'\1' + correct_manual_test_json + r'\2', content, count=1, flags=re.DOTALL)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_code('mukemmeliyet.mq5')
