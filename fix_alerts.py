import re

with open("Nasilsin_Indicator.mq5", "r") as f:
    code = f.read()

# Replace the complicated missed/revisit/trig1/trig2 block with the simple original one that works.
start_str = r"// Reset triggers if swing changed \(only when fully confirmed by a bar close / definitive state update\)"
end_str = r"return\(rates_total\);"

def simplify_alerts(match):
    return """// Reset triggers if swing changed
         if (g_state_curr.maj_h != g_last_alert_maj_h ||
             g_state_curr.maj_l != g_last_alert_maj_l ||
             g_state_curr.maj_tr != g_last_alert_trend)
           {
            g_level1_triggered = false;
            g_level2_triggered = false;
            g_last_alert_maj_h = g_state_curr.maj_h;
            g_last_alert_maj_l = g_state_curr.maj_l;
            g_last_alert_trend = g_state_curr.maj_tr;
           }

         // Fiyat %100'e ulaştığında (yani kırılım geldiğinde) sahte düzeltme bildirimi atmaması için < 99.0 sınırı eklendi.
         bool trig1 = (live_pct >= InpTriggerLevel1 && live_pct < 99.0 && !g_level1_triggered);
         bool trig2 = (live_pct >= InpTriggerLevel2 && live_pct < 99.0 && !g_level2_triggered);

         if(trig1 || trig2 || InpTestMode)
           {
            int trigger_lvl = trig2 ? 2 : 1;
            bool success = TriggerMTFAlert(last_idx, time[last_idx], close[last_idx], trigger_lvl);
            if(success && !InpTestMode) {
               if(trig1) g_level1_triggered = true;
               if(trig2) g_level2_triggered = true;
            }
           }
        }
     }

   return(rates_total);"""

import re
new_code = re.sub(start_str + r".*?" + end_str, simplify_alerts, code, flags=re.DOTALL)

with open("Nasilsin_Indicator.mq5", "w") as f:
    f.write(new_code)
