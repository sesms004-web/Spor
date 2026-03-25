import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Add new input toggles
search_alerts = """//--- Alert Settings ---
input double InpTriggerLevel1    = 40.0;             // 1. Bildirim Çekilme % (örn. %40)"""

replace_alerts = """//--- Alert Settings ---
input bool   InpEnableAlertTrendChange = true;       // Ana Trend (Kapanış) Dönüş Bildirimini Aç
input bool   InpEnableAlertMTFLevels   = true;       // %40/%60 MTF Analiz Bildirimini Aç (Bölüm 1/2)
input bool   InpEnableAlertCHoCHBase   = true;       // Temel CHoCH (Kırılım) Bildirimini Aç
input bool   InpEnableTradeExecution   = true;       // 50 Puanlık 'İşleme Gir' Analiz Sistemini Aç
input double InpTriggerLevel1    = 40.0;             // 1. Bildirim Çekilme % (örn. %40)"""

content = content.replace(search_alerts, replace_alerts)

# Patch Trend Change Alert
search_trend = """               string new_dir = (g_state_hist.maj_tr == 1) ? "YUKARI" : "AŞAĞI";
               string trend_msg = "🚨 [" + Symbol() + "] M1 Trend Döndü! Yeni Yön: " + new_dir;
               if(InpAlertPopup) Alert(trend_msg);
               if(InpAlertPush)  SendNotification(trend_msg);"""

replace_trend = """               if (InpEnableAlertTrendChange) {
                   string new_dir = (g_state_hist.maj_tr == 1) ? "YUKARI" : "AŞAĞI";
                   string trend_msg = "🚨 [" + Symbol() + "] M1 Trend Döndü! Yeni Yön: " + new_dir;
                   if(InpAlertPopup) Alert(trend_msg);
                   if(InpAlertPush)  SendNotification(trend_msg);
               }"""

content = content.replace(search_trend, replace_trend)

# Patch MTF Levels Alert (The massive one)
search_mtf = """         if(trig1 || trig2 || InpTestMode)
           {
            int trigger_lvl = trig2 ? 2 : 1;
            bool is_revisit = (trigger_lvl == 2) ? is_revisit_2 : is_revisit_1;
            bool success = TriggerMTFAlert(last_idx, time[last_idx], close[last_idx], trigger_lvl, is_revisit);
            if(success && !InpTestMode) {
               if(trig1) { g_level1_triggered = true; g_level1_missed = false; }
               if(trig2) { g_level2_triggered = true; g_level2_missed = false; }
            }
           }"""

replace_mtf = """         if(InpEnableAlertMTFLevels && (trig1 || trig2 || InpTestMode))
           {
            int trigger_lvl = trig2 ? 2 : 1;
            bool is_revisit = (trigger_lvl == 2) ? is_revisit_2 : is_revisit_1;
            bool success = TriggerMTFAlert(last_idx, time[last_idx], close[last_idx], trigger_lvl, is_revisit);
            if(success && !InpTestMode) {
               if(trig1) { g_level1_triggered = true; g_level1_missed = false; }
               if(trig2) { g_level2_triggered = true; g_level2_missed = false; }
            }
           }"""

content = content.replace(search_mtf, replace_mtf)

# The CHoCH and Execution ones will be added in the next step when we build the engine.

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Toggles patched")
