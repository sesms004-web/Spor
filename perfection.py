import re

with open('smaecv1.mq5', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Inputs
inputs_to_remove = [
    r'input group "--- MTF PULLBACK LEVELS ---".*?\n',
    r'input double InpTriggerLevel1.*?\n',
    r'input double InpTriggerLevel2.*?\n',
    r'input bool   InpNotificationFilter.*?\n',
    r'input bool   InpEnableAlertMTFLevels.*?\n',
    r'input bool   InpEnableAlertTrendChange.*?\n',
    r'input bool\s+InpTestMTFChochReport.*?\n',
    r'input bool\s+InpTestTradeExecution.*?\n',
    r'input double\s+InpTestTargetSL.*?\n',
    r'input double\s+InpTestTargetTP.*?\n',
    r'input bool\s+InpTestMode.*?\n',
    r'input double\s+InpMinPullbackPct.*?\n',
    r'input double\s+InpMaxPullbackPct.*?\n',
    r'input bool\s+InpEnableSLPctLimit.*?\n',
    r'input double\s+InpMinSLPct.*?\n',
    r'input double\s+InpMaxSLPct.*?\n',
    r'input int\s+InpMinTradeScoreLimit.*?\n'
]
for p in inputs_to_remove:
    code = re.sub(p, '', code)

mtf_alert_code = """
void SendMTFAnalysisAlert(datetime t, int trigger_dir, bool is_strong)
{
   int t_m1=0, t_m3=0, t_m5=0, t_m15=0, t_m30=0, t_h1=0;
   double p_m1=0, p_m3=0, p_m5=0, p_m15=0, p_m30=0, p_h1=0;
   double mp_m1=0, mp_m3=0, mp_m5=0, mp_m15=0, mp_m30=0, mp_h1=0;
   double h_m1=0, l_m1=0, h_m3=0, l_m3=0, h_m5=0, l_m5=0, h_m15=0, l_m15=0, h_m30=0, l_m30=0, h_h1=0, l_h1=0;
   datetime dmy_th, dmy_tl, th_m15, tl_m15, th_m30, tl_m30;

   GetMTFPullback(PERIOD_M1, t_m1, p_m1, mp_m1, t, h_m1, l_m1, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M3, t_m3, p_m3, mp_m3, t, h_m3, l_m3, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M5, t_m5, p_m5, mp_m5, t, h_m5, l_m5, dmy_th, dmy_tl);
   GetMTFPullback(PERIOD_M15, t_m15, p_m15, mp_m15, t, h_m15, l_m15, th_m15, tl_m15);
   GetMTFPullback(PERIOD_M30, t_m30, p_m30, mp_m30, t, h_m30, l_m30, th_m30, tl_m30);
   GetMTFPullback(PERIOD_H1, t_h1, p_h1, mp_h1, t, h_h1, l_h1, dmy_th, dmy_tl);

   int total_points = 0;
   string h1_text = "", m30_text = "", m15_text = "", m5_text = "", m1_text = "";

   int m1_points = is_strong ? 5 : 0;
   total_points += m1_points;
   m1_text = GenerateMTFString("M1", t_m1, h_m1, l_m1, p_m1, mp_m1);
   if(is_strong) m1_text += "🔥 Likidite Temizlendi -> [+5 Puan]\\n";
   else          m1_text += "⚠️ Likidite Alınmadı -> [+0 Puan]\\n";

   int h1_points = 0;
   double h1_mom = mp_h1 - p_h1;
   bool is_h1_aligned = (t_h1 == trigger_dir);

   if (h1_mom >= 15.0) {
       if (is_h1_aligned) {
           if (h1_mom >= 20.0) { h1_points = 35; h1_text = "🚀 Uyumlu, Çok Sert Momentum -> [+35 Puan]\\n"; }
           else                { h1_points = 30; h1_text = "⚡ Uyumlu, Sert Momentum -> [+30 Puan]\\n"; }
       } else {
           h1_points = 0; h1_text = "🛑 Ters Yönlü Sert Momentum -> [0 Puan]\\n";
       }
   } else {
       if (is_h1_aligned) {
           if (p_h1 >= 50.0) { h1_points = 30; h1_text = "🎯 Uyumlu, Momentum Yok Ama %50 İdeal -> [+30 Puan]\\n"; }
           else              { h1_points = 10; h1_text = "📉 Uyumlu, Momentum Yok Ve Şişkin -> [+10 Puan]\\n"; }
       } else {
           if (p_h1 >= 50.0) { h1_points = 20; h1_text = "🔄 Ters Yönlü Ama %50 İdeal -> [+20 Puan]\\n"; }
           else              { h1_points = 30; h1_text = "⏳ Ters Yönlü Ve Şişkin -> [+30 Puan]\\n"; }
       }
   }
   h1_text = GenerateMTFString("H1", t_h1, h_h1, l_h1, p_h1, mp_h1) + h1_text;
   total_points += h1_points;

   int m30_points = 0;
   double m30_mom = mp_m30 - p_m30;
   bool is_m30_aligned = (t_m30 == trigger_dir);
   bool clone_m30_h1 = (MathAbs(h_m30 - h_h1) < Point() * 5 && MathAbs(l_m30 - l_h1) < Point() * 5);

   if (clone_m30_h1) {
       m30_points = 0; m30_text = "👯 H1 İle Aynı Yapı Es Geçildi -> [0 Puan]\\n";
   } else {
       if (!is_m30_aligned) {
           if (m30_mom >= 15.0) { m30_points = 0;  m30_text = "🛑 Bize Karşı Sert Tepki -> [0 Puan]\\n"; }
           else                 { m30_points = 10; m30_text = "😴 Ters Yönlü Ama Sakin -> [+10 Puan]\\n"; }
       } else {
           if (m30_mom >= 20.0)      { m30_points = 25; m30_text = "🚀 Uyumlu, Çok Sert Dönüş -> [+25 Puan]\\n"; }
           else if (m30_mom >= 15.0) { m30_points = 20; m30_text = "⚡ Uyumlu, Sert Dönüş -> [+20 Puan]\\n"; }
           else if (p_m30 >= 50.0)   { m30_points = 15; m30_text = "🎯 Uyumlu, Tepki Yok Ama %50 İdeal -> [+15 Puan]\\n"; }
           else                      { m30_points = 5;  m30_text = "📉 Uyumlu, Tepki Yok Ve Şişkin -> [+5 Puan]\\n"; }
       }
   }
   m30_text = GenerateMTFString("M30", t_m30, h_m30, l_m30, p_m30, mp_m30) + m30_text;
   total_points += m30_points;

   int m15_points = 0;
   double m15_mom = mp_m15 - p_m15;
   bool is_m15_aligned = (t_m15 == trigger_dir);
   bool clone_m15_m30 = (MathAbs(h_m15 - h_m30) < Point() * 5 && MathAbs(l_m15 - l_m30) < Point() * 5);

   if (clone_m15_m30) {
       m15_points = 0; m15_text = "👯 M30 İle Aynı Yapı Es Geçildi -> [0 Puan]\\n";
   } else {
       if (!is_m15_aligned) {
           if (m15_mom >= 15.0) { m15_points = 0; m15_text = "🛑 Bize Karşı Sert Tepki -> [0 Puan]\\n"; }
           else                 { m15_points = 5; m15_text = "😴 Ters Yönlü Ama Sakin -> [+5 Puan]\\n"; }
       } else {
           if (m15_mom >= 20.0)      { m15_points = 20; m15_text = "🚀 Uyumlu, Çok Sert Dönüş -> [+20 Puan]\\n"; }
           else if (m15_mom >= 15.0) { m15_points = 15; m15_text = "⚡ Uyumlu, Sert Dönüş -> [+15 Puan]\\n"; }
           else if (p_m15 >= 50.0)   { m15_points = 15; m15_text = "🎯 Uyumlu, Tepki Yok Ama %50 İdeal -> [+15 Puan]\\n"; }
           else                      { m15_points = 5;  m15_text = "📉 Uyumlu, Tepki Yok Ve Şişkin -> [+5 Puan]\\n"; }
       }
   }
   m15_text = GenerateMTFString("M15", t_m15, h_m15, l_m15, p_m15, mp_m15) + m15_text;
   total_points += m15_points;

   int m5_points = 0;
   double m5_mom = mp_m5 - p_m5;
   bool is_m5_aligned = (t_m5 == trigger_dir);
   bool clone_m5_m15 = (MathAbs(h_m5 - h_m15) < Point() * 5 && MathAbs(l_m5 - l_m15) < Point() * 5);

   if (clone_m5_m15) {
       m5_points = 0; m5_text = "👯 M15 İle Aynı Yapı Es Geçildi -> [0 Puan]\\n";
   } else {
       if (!is_m5_aligned) {
           if (m5_mom >= 15.0) { m5_points = 0; m5_text = "🛑 Bize Karşı Sert Tepki -> [0 Puan]\\n"; }
           else                { m5_points = 5; m5_text = "😴 Ters Yönlü Ama Sakin -> [+5 Puan]\\n"; }
       } else {
           if (m5_mom >= 20.0)      { m5_points = 15; m5_text = "🚀 Uyumlu, Çok Sert Dönüş -> [+15 Puan]\\n"; }
           else if (m5_mom >= 15.0) { m5_points = 10; m5_text = "⚡ Uyumlu, Sert Dönüş -> [+10 Puan]\\n"; }
           else if (p_m5 >= 50.0)   { m5_points = 10; m5_text = "🎯 Uyumlu, Tepki Yok Ama %50 İdeal -> [+10 Puan]\\n"; }
           else                     { m5_points = 5;  m5_text = "📉 Uyumlu, Tepki Yok Ve Şişkin -> [+5 Puan]\\n"; }
       }
   }
   m5_text = GenerateMTFString("M5 ", t_m5, h_m5, l_m5, p_m5, mp_m5) + m5_text;
   total_points += m5_points;

   string msg = "📊 [" + Symbol() + "] MTF ANALİZ ŞABLONU 📊\\n";
   msg += "🔍 M1 KIRILIM KALİTESİ:\\n" + m1_text + "\\n";
   msg += "📈 ZAMAN DİLİMİ PUANLARI:\\n";
   msg += h1_text;
   msg += m30_text;
   msg += m15_text;
   msg += m5_text;
   msg += "\\n🏆 TOPLAM İŞLEM SKORU: " + IntegerToString(total_points) + " Puan\\n";

   if(InpAlertPopup) Alert(msg);
   if(InpAlertPush) {
       string msg1 = "📊 [" + Symbol() + "] MTF ANALİZ (1/2)\\n" + h1_text + m30_text;
       string msg2 = "📊 [" + Symbol() + "] MTF ANALİZ (2/2)\\n" + m15_text + m5_text + "\\n🏆 TOPLAM SKOR: " + IntegerToString(total_points);
       SendNotification(msg1);
       Sleep(100);
       SendNotification(msg2);
   }
}

void ExecuteTradeSignal(double live_price, int trigger_dir, bool is_strong, double minor_extreme_sl, int maj_extreme_i)
{
   double sl_dist = MathAbs(live_price - minor_extreme_sl);

   if (is_strong) sl_dist *= InpStrongSLMultiplier;
   else           sl_dist *= InpWeakSLMultiplier;

   double sl_price = (trigger_dir == 1) ? (live_price - sl_dist) : (live_price + sl_dist);
   double tp_dist = sl_dist * 3.0;
   double tp_price = (trigger_dir == 1) ? (live_price + tp_dist) : (live_price - tp_dist);

   static int last_broadcast_maj_extreme_i = -1;
   if (maj_extreme_i != last_broadcast_maj_extreme_i || maj_extreme_i == 0) {
       BroadcastTradeSignal(Symbol(), trigger_dir, live_price, sl_price, tp_price, is_strong, 100, false);
       last_broadcast_maj_extreme_i = maj_extreme_i;
   }
}
"""

def remove_function(source, func_sig):
    idx = source.find(func_sig)
    if idx == -1: return source
    brace_count = 0
    in_block = False
    for i in range(idx, len(source)):
        if source[i] == '{':
            brace_count += 1
            in_block = True
        elif source[i] == '}':
            brace_count -= 1
        if in_block and brace_count == 0:
            return source[:idx] + source[i+1:]
    return source

# Insert new code at EvaluateTradeSignal, then delete EvaluateTradeSignal
idx = code.find("void EvaluateTradeSignal")
code = code[:idx] + mtf_alert_code + code[idx:]

code = remove_function(code, "void EvaluateTradeSignal")
code = remove_function(code, "void GetMTFChochDetails")
code = remove_function(code, "struct SMTFReport")
code = remove_function(code, "void GenerateMTFChochReport")
code = remove_function(code, "bool TriggerMTFAlert")

# Replace function calls
code = re.sub(
    r'EvaluateTradeSignal\(i,\s*time\[i\],\s*g_pending_entry,\s*g_pending_dir,\s*g_pending_p_pct,\s*g_pending_is_strong,\s*g_pending_sl,\s*g_pending_maj_extreme_i\);',
    'SendMTFAnalysisAlert(time[i], g_pending_dir, g_pending_is_strong);\n                      ExecuteTradeSignal(g_pending_entry, g_pending_dir, g_pending_is_strong, g_pending_sl, g_pending_maj_extreme_i);',
    code
)
code = re.sub(
    r'EvaluateTradeSignal\(i,\s*time\[i\],\s*val_c,\s*-1,\s*p_pct,\s*is_strong,\s*state\.t2_h,\s*state\.maj_h_i\);',
    'if(InpAlertPopup) Alert("🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI (AŞAĞI - SELL) 🚨");\n                      SendMTFAnalysisAlert(time[i], -1, is_strong);\n                      ExecuteTradeSignal(val_c, -1, is_strong, state.t2_h, state.maj_h_i);',
    code
)
code = re.sub(
    r'EvaluateTradeSignal\(i,\s*time\[i\],\s*val_c,\s*1,\s*p_pct,\s*is_strong,\s*state\.t2_l,\s*state\.maj_l_i\);',
    'if(InpAlertPopup) Alert("🚨 [" + Symbol() + "] YENİ İŞLEM FIRSATI (YUKARI - BUY) 🚨");\n                      SendMTFAnalysisAlert(time[i], 1, is_strong);\n                      ExecuteTradeSignal(val_c, 1, is_strong, state.t2_l, state.maj_l_i);',
    code
)

code = re.sub(
    r'EvaluateTradeSignal\(rates_total-1,\s*TimeCurrent\(\),\s*SymbolInfoDouble\(Symbol\(\),\s*SYMBOL_BID\),\s*test_dir,\s*live_pct,\s*true,\s*dummy_ext,\s*0,\s*true\);',
    '',
    code
)

# Globals
code = re.sub(r'bool g_level1_triggered = false;\n', '', code)
code = re.sub(r'bool g_level2_triggered = false;\n', '', code)
code = re.sub(r'bool g_level1_missed = false;\n', '', code)
code = re.sub(r'bool g_level2_missed = false;\n', '', code)
code = re.sub(r'double g_last_alert_maj_h = 0;\n', '', code)
code = re.sub(r'double g_last_alert_maj_l = 0;\n', '', code)
code = re.sub(r'int g_last_alert_trend = 0;\n', '', code)

# Reset block explicitly inside OnCalculate
code = re.sub(r'\s*g_last_alert_maj_h = 0;\n', '', code)
code = re.sub(r'\s*g_last_alert_maj_l = 0;\n', '', code)
code = re.sub(r'\s*g_last_alert_trend = 0;\n', '', code)
code = re.sub(r'\s*g_level1_triggered = false;\n', '', code)
code = re.sub(r'\s*g_level2_triggered = false;\n', '', code)
code = re.sub(r'\s*g_level1_missed = false;\n', '', code)
code = re.sub(r'\s*g_level2_missed = false;\n', '', code)

# Safe Blocks cleanups
def remove_code_block(source, start_str):
    idx = source.find(start_str)
    if idx == -1: return source
    brace_count = 0
    in_block = False
    for i in range(idx, len(source)):
        if source[i] == '{':
            brace_count += 1
            in_block = True
        elif source[i] == '}':
            brace_count -= 1
        if in_block and brace_count == 0:
            return source[:idx] + source[i+1:]
    return source

code = remove_code_block(code, "// TEST TRIGGER")
code = remove_code_block(code, "if (InpTestMTFChochReport && !last_test_state)")
code = remove_code_block(code, "if(last_idx > 0 && (Period() == PERIOD_M1 || InpTestMode))")

code = re.sub(r'if\s*\(InpTestMode\)\s*msg\d\s*=\s*".*?;\n', '', code)
code = code.replace("|| InpTestMode", "")
code = code.replace("&& !InpTestMode", "")
code = re.sub(r'static bool last_test_state = false;\n', '', code)
code = re.sub(r'last_test_state = InpTestMTFChochReport;\n', '', code)

# 40/60 checks inline
code = re.sub(r'bool in_pullback_zone\s*=\s*\(p_pct\s*>=\s*InpMinPullbackPct\s*&&\s*p_pct\s*<=\s*InpMaxPullbackPct\);', 'bool in_pullback_zone = true;', code)
code = re.sub(r'bool t2_valid\s*=\s*\(t2_pct\s*>=\s*InpMinPullbackPct\s*&&\s*t2_pct\s*<=\s*InpMaxPullbackPct\);', 'bool t2_valid = true;', code)

# REPLACE ARRAY BOUNDS FIX FOR DRAWLINE INSTEAD OF BLIND STRING REPLACEMENT!
# Find the exact if(InpShowChoch) blocks! There are two of them (one for Bear, one for Bull).
def inject_bounds(source, sig):
    idx = source.find(sig)
    if idx == -1: return source
    brace_count = 0
    in_block = False
    for i in range(idx, len(source)):
        if source[i] == '{':
            brace_count += 1
            in_block = True
        elif source[i] == '}':
            brace_count -= 1
        if in_block and brace_count == 0:
            bounds_check_code = """
              int r_total_t = ArraySize(time);
              if (state.t1_i >= 0 && state.t1_i < r_total_t &&
                  state.d1_i >= 0 && state.d1_i < r_total_t &&
                  state.t2_i >= 0 && state.t2_i < r_total_t &&
                  i >= 0 && i < r_total_t) {
"""
            # We inject bounds check right after the sig matches, and then close it right before the end brace.
            inner_content = source[idx + len(sig):i]
            # Replace the string in inner_content so we know we wrap it safely
            inner_content = bounds_check_code + inner_content + "\n              }"
            return source[:idx + len(sig)] + inner_content + source[i:]
    return source

# Just inject manually using robust regex to avoid duplicated if braces!
bear_match = re.search(r'(if\s*\(InpShowChoch\)\s*\{\s*color sig_color = is_strong \? InpColorChochStrong : InpColorChochWeak;)(.*?)(state\.choch_dir = 0;)', code, re.DOTALL)
if bear_match:
    original = bear_match.group(0)
    sig = bear_match.group(1)
    inner = bear_match.group(2)
    end = bear_match.group(3)

    wrapped = sig + "\n              int r_total_t = ArraySize(time);\n              if (state.t1_i >= 0 && state.t1_i < r_total_t && state.d1_i >= 0 && state.d1_i < r_total_t && state.t2_i >= 0 && state.t2_i < r_total_t && i >= 0 && i < r_total_t) {\n" + inner + "              }\n          " + end
    code = code.replace(original, wrapped)

bull_match = re.search(r'(if\s*\(InpShowChoch\)\s*\{\s*color sig_color = is_strong \? InpColorChochStrong : InpColorChochWeak;)(.*?)(state\.choch_dir = 0;)', code[code.find("Bullish CHoCH confirmed!"):], re.DOTALL)
if bull_match:
    original = bull_match.group(0)
    sig = bull_match.group(1)
    inner = bull_match.group(2)
    end = bull_match.group(3)

    wrapped = sig + "\n              int r_total_t = ArraySize(time);\n              if (state.t1_i >= 0 && state.t1_i < r_total_t && state.d1_i >= 0 && state.d1_i < r_total_t && state.t2_i >= 0 && state.t2_i < r_total_t && i >= 0 && i < r_total_t) {\n" + inner + "              }\n          " + end
    # We must only replace it after Bullish CHoCH confirmed!
    start_pos = code.find("Bullish CHoCH confirmed!")
    code = code[:start_pos] + code[start_pos:].replace(original, wrapped, 1)

with open('smaecv1.mq5', 'w', encoding='utf-8') as f:
    f.write(code)
