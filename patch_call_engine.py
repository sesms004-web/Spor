import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Bearish Trigger: call the engine
search_bear = """              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {
                  if(InpAlertPopup) Alert(msg);
                  if(InpAlertPush) SendNotification(msg);
                  last_alert_d1_i_bear = state.d1_i;
              }"""

replace_bear = """              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bear = 0;
              if (state.d1_i != last_alert_d1_i_bear) {
                  if (InpEnableAlertCHoCHBase) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution) {
                      EvaluateTradeSignal(i, time[i], val_c, -1, p_pct, is_strong);
                  }
                  last_alert_d1_i_bear = state.d1_i;
              }"""

content = content.replace(search_bear, replace_bear)

# Bullish Trigger: call the engine
search_bull = """              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {
                  if(InpAlertPopup) Alert(msg);
                  if(InpAlertPush) SendNotification(msg);
                  last_alert_d1_i_bull = state.d1_i;
              }"""

replace_bull = """              // Only alert if we haven't already alerted for THIS specific swing setup
              static int last_alert_d1_i_bull = 0;
              if (state.d1_i != last_alert_d1_i_bull) {
                  if (InpEnableAlertCHoCHBase) {
                      if(InpAlertPopup) Alert(msg);
                      if(InpAlertPush) SendNotification(msg);
                  }
                  if (InpEnableTradeExecution) {
                      EvaluateTradeSignal(i, time[i], val_c, 1, p_pct, is_strong);
                  }
                  last_alert_d1_i_bull = state.d1_i;
              }"""

content = content.replace(search_bull, replace_bull)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Engine called")
