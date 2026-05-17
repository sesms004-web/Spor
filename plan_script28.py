import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# The difference is that in `BxUpdateStats` I added `g_bx_break_up` tracking.
# And `g_bx_bars_since_touch` tracking.
# None of this alters `g_bx_state` or `g_bx_touch_state`.
# So why would `BxAdvanceTrim` not trim the boxes properly?
# "if(g_bx_state[k]==1){ if(g_bx_touch_state[k]==1)continue; ObjectSetInteger(...) }"
# Wait. Look at the original `BxUpdateStats`:
"""
        else if(ts==1){if(im){g_bx_inside_cnt[k]++;g_bx_event_time[k]=bar_time;}
            else{bool bd=(c<bot),bu=(c>top);int ap=g_bx_approach[k];
                if(ap==1){if(bd)g_bx_touch_state[k]=2;else if(bu)g_bx_touch_state[k]=3;}
                else{if(bu)g_bx_touch_state[k]=2;else if(bd)g_bx_touch_state[k]=3;}
                g_bx_event_time[k]=bar_time;}}
"""
# In the NEW `BxUpdateStats`:
"""
        else if(ts==1){if(im){g_bx_inside_cnt[k]++;g_bx_event_time[k]=bar_time;}
            else{bool bd=(c<bot),bu=(c>top);int ap=g_bx_approach[k];
                if(ap==1){
                    if(bd){g_bx_touch_state[k]=2; g_bx_break_dn[k]++;}
                    else if(bu){g_bx_touch_state[k]=3; g_bx_break_up[k]++;}
                }
                else{
                    if(bu){g_bx_touch_state[k]=2; g_bx_break_up[k]++;}
                    else if(bd){g_bx_touch_state[k]=3; g_bx_break_dn[k]++;}
                }
                g_bx_event_time[k]=bar_time;}}
"""
# Notice anything?
# Wait. In the original, `if(ap==1) { if(bd) ... else if(bu) ... }`. If NEITHER `bd` nor `bu` is true?
# What if `c` is BETWEEN `top` and `bot`?
# But wait, `im` is `(h>=bot)&&(l<=top)`. If `im` is FALSE, then `h < bot` OR `l > top`.
# So `c` MUST be `< bot` OR `c > top`.
# Thus, either `bd` or `bu` MUST be true.
# Therefore, `g_bx_touch_state[k]` is definitely changed from 1 to 2 or 3.
# So this logic hasn't changed its effect on `g_bx_touch_state`.
# So what causes the boxes to be infinite?

# Is it `BxAdvanceTrim` missing an index?
# No, `ObjectSetInteger(0,g_bx_nm[k],OBJPROP_TIME,1,t);` sets Time2 to `t`.
# Did the time `t` change? `t` is `GetTimeSafe(time,state.tmp_h_i)` or something.
# None of the `ProcessBar` / `BxAdvanceTrim` inputs changed.
# The user says "Gereksiz şekilde kutularin uzunluğu sınırsız oldu".
# What if the user is referring to the CHoCH line itself?! "Choch cizgilerinin uzunlugunu 2x yapar misin" - I DID.
# Oh! Wait! In the previous prompt: "Sarı 2. Çizgi turuncu olsun ve 2. Choch de nasil senaryo çiziyorsun 1. Choch ile ayni dimi kutu olayı bir sinyal icin oluyor bir de choch çizgilerinin uzunluğunu 2x yapar mısın"
# And then they sent an image, and said "Gereksiz şekilde kutularin uzunluğu sınırsız oldu".
# Does the image show the BOXES are infinite? Or the CHoCH line?
# Wait! "Gereksiz sekilde kutularin uzunlugu sinirsiz oldu"
