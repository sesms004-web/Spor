import re

with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's fix the `undeclared identifier 'last_alert_d1_i_bear'` issue too.
# I had incorrectly placed `last_alert_d1_i_bear = state.d1_i;` outside the curly brace or something? No, it's:
# static int last_alert_d1_i_bear = 0;
# if (state.d1_i != last_alert_d1_i_bear) { ... last_alert_d1_i_bear = state.d1_i; }
# This is valid MQL5 inside a block. Let's make it more robust by taking it out of the if.

pattern = r"""          // İşlem Koruması: Sadece ve sadece grafikte fiziksel kırılım çizgisi \(CHoCH_Signal\) çizildiyse işlemi/bildirimi fırlat!
          if \(!is_history && \(!InpShowChoch \|\| is_line_drawn\)\) \{
              static int last_alert_d1_i_bear = 0;
              if \(state\.d1_i != last_alert_d1_i_bear\) \{
                  if \(InpEnableTradeExecution && draw_ui\) \{
                      EvaluateTradeSignal\(i, time\[i\], val_c, -1, ext_pct, is_strong, trade_sl_anchor\);
                  \}
                  last_alert_d1_i_bear = state\.d1_i;
              \}
          \}"""

replacement = """          // İşlem Koruması: Sadece ve sadece grafikte fiziksel kırılım çizgisi (CHoCH_Signal) çizildiyse işlemi/bildirimi fırlat!
          static int last_alert_d1_i_bear = 0;
          if (!is_history && (!InpShowChoch || is_line_drawn)) {
              if (state.d1_i != last_alert_d1_i_bear) {
                  if (InpEnableTradeExecution && draw_ui) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, ext_pct, is_strong, trade_sl_anchor);
                  }
                  last_alert_d1_i_bear = state.d1_i;
              }
          }"""

text = re.sub(pattern, replacement, text)

pattern2 = r"""          // İşlem Koruması: Sadece ve sadece grafikte fiziksel kırılım çizgisi \(CHoCH_Signal\) çizildiyse işlemi/bildirimi fırlat!
          if \(!is_history && \(!InpShowChoch \|\| is_line_drawn\)\) \{
              static int last_alert_d1_i_bull = 0;
              if \(state\.d1_i != last_alert_d1_i_bull\) \{
                  if \(InpEnableTradeExecution && draw_ui\) \{
                      EvaluateTradeSignal\(i, time\[i\], val_c, 1, ext_pct, is_strong, trade_sl_anchor\);
                  \}
                  last_alert_d1_i_bull = state\.d1_i;
              \}
          \}"""

replacement2 = """          // İşlem Koruması: Sadece ve sadece grafikte fiziksel kırılım çizgisi (CHoCH_Signal) çizildiyse işlemi/bildirimi fırlat!
          static int last_alert_d1_i_bull = 0;
          if (!is_history && (!InpShowChoch || is_line_drawn)) {
              if (state.d1_i != last_alert_d1_i_bull) {
                  if (InpEnableTradeExecution && draw_ui) {
                      EvaluateTradeSignal(i, time[i], val_c, 1, ext_pct, is_strong, trade_sl_anchor);
                  }
                  last_alert_d1_i_bull = state.d1_i;
              }
          }"""

text = re.sub(pattern2, replacement2, text)

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
