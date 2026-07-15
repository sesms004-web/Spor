import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Issue 1: Memory leak due to "OB_Box_" prefix. Change it to "Box_OB_" so ObjectsDeleteAll catches it.
content = content.replace('pfx + "OB_Box_"', 'pfx + "Box_OB_"')
content = content.replace('pfx + "OB_BoxWkAbv_"', 'pfx + "Box_OB_WkAbv_"')
content = content.replace('pfx + "OB_BoxWkBlw_"', 'pfx + "Box_OB_WkBlw_"')

# Issue 2: Immediate Box Truncation in BxUpdateStats
# When `bd` or `bu` (break down / break up) or touch happens, we should truncate the box visually right there if not already truncated.
# Actually, the user wants the box to stop extending when touched: "temas edenlerin uzamasını durdurmani istiyorum"
# In `BxUpdateStats` (for non-shadow):
# if(ts==0){if(im){ ... g_bx_touch_state[k]=1; ... }}
# When `g_bx_touch_state` becomes > 0, we should stop it.
bx_update_stats_patch = """      if(ts==0){if(im){g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;
         if(!is_history) {
            if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectSetInteger(0,g_bx_nm[k],       OBJPROP_TIME,1,bar_time);
            if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,bar_time);
            if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,bar_time);
         }
      }}"""

content = content.replace("      if(ts==0){if(im){g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;}}", bx_update_stats_patch)


with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
