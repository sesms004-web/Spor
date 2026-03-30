import re

with open('vol100.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure ProcessBar within GetMTFPullback explicitly calls with draw_ui=false
# We already did this, it passes `false` to the last argument of ProcessBar.

# Is EvaluateTradeSignal called AFTER drawing CHoCH?
# Yes, inside ProcessBar:
'''
                  if (InpEnableAlertCHoCHBase && draw_ui) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution && draw_ui) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, ext_pct, is_strong);
                  }
'''
# We can swap the order so the UI is drawn FIRST!

new_choch_bear = """
          if (InpShowChoch && draw_ui) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              // 1. Draw the minor structure path (T1 -> D1 -> T2 -> Signal Point)
              string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_1, time[state.t1_i], state.t1_h, time[state.d1_i], state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

              string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_2, time[state.d1_i], state.d1_l, time[state.t2_i], state.t2_h, InpColorChochPath, 1, STYLE_DOT, false);

              string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_3, time[state.t2_i], state.t2_h, time[i], state.d1_l, InpColorChochPath, 1, STYLE_DOT, false);

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_l, time[i] + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);

              ChartRedraw(); // Force UI update before MTF scan
          }

          if (!is_history) {
              string msg = "🔴 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬇️ AŞAĞI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Tepe likiditesi alındı.\\n";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Tepe likiditesi alınamadı.\\n";
              }

              msg += "Çekilme: %" + DoubleToString(ext_pct, 2) + " (Kırılım: %" + DoubleToString(break_pct, 2) + ")\\n";

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {
                  if (InpEnableAlertCHoCHBase && draw_ui) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution && draw_ui) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, ext_pct, is_strong);
                  }
                  last_alert_d1_i_bear = state.d1_i;
              }
          }
"""

new_choch_bull = """
          if (InpShowChoch && draw_ui) {
              color sig_color = is_strong ? InpColorChochStrong : InpColorChochWeak;

              // 1. Draw the minor structure path (T1 -> D1 -> T2 -> Signal Point)
              string path_1 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_1, time[state.t1_i], state.t1_l, time[state.d1_i], state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

              string path_2 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_2, time[state.d1_i], state.d1_h, time[state.t2_i], state.t2_l, InpColorChochPath, 1, STYLE_DOT, false);

              string path_3 = GetUniqueName(prefix + "CHoCH_Path_");
              DrawLine(path_3, time[state.t2_i], state.t2_l, time[i], state.d1_h, InpColorChochPath, 1, STYLE_DOT, false);

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_h, time[i] + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);

              ChartRedraw(); // Force UI update before MTF scan
          }

          if (!is_history) {
              string msg = "🟢 [" + Symbol() + "] " + EnumToString(Period()) + " Trend Döndü! (CHoCH)\\n";
              msg += "Yön: ⬆️ YUKARI\\n";
              if (is_strong) {
                  msg += "Durum: 🔥 GÜÇLÜ! Dip likiditesi alındı.\\n";
              } else {
                  msg += "Durum: ⚠️ ZAYIF! Dip likiditesi alınamadı.\\n";
              }

              msg += "Çekilme: %" + DoubleToString(ext_pct, 2) + " (Kırılım: %" + DoubleToString(break_pct, 2) + ")\\n";

              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {
                  if (InpEnableAlertCHoCHBase && draw_ui) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution && draw_ui) {
                      EvaluateTradeSignal(i, time[i], val_c, 1, ext_pct, is_strong);
                  }
                  last_alert_d1_i_bull = state.d1_i;
              }
          }
"""

# Let's write a simple script to replace these blocks
# Bearish replace
pattern_bear = re.compile(r'if \(!is_history\) \{.*?string msg = "🔴 \[".*?last_alert_d1_i_bear = state\.d1_i;\n\s*\}\n\s*\}\n\n\s*if \(InpShowChoch && draw_ui\) \{.*?DrawLine\(choch_name.*?\}\n', re.DOTALL)
# Reverse the order!
# First we search for the current block

match_bear = pattern_bear.search(content)
if match_bear:
    print("Found bearish block!")
    content = content[:match_bear.start()] + new_choch_bear + content[match_bear.end():]

pattern_bull = re.compile(r'if \(!is_history\) \{.*?string msg = "🟢 \[".*?last_alert_d1_i_bull = state\.d1_i;\n\s*\}\n\s*\}\n\n\s*if \(InpShowChoch && draw_ui\) \{.*?DrawLine\(choch_name.*?\}\n', re.DOTALL)
match_bull = pattern_bull.search(content)
if match_bull:
    print("Found bullish block!")
    content = content[:match_bull.start()] + new_choch_bull + content[match_bull.end():]


with open('vol100.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
