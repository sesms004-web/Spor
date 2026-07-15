import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Wait, let's also update the historical truncation part in BxUpdateStats, not just live ones.
# Actually, BxUpdateStats is called for history too. `if(!is_history)` is good for live, but what about history?
# For history, `bar_time` is also correct. But drawing objects during history might be heavy if done every tick.
# Oh, historical bars DO NOT draw `Live_` objects. Wait, historical bars don't have `Live_` prefix, they just use regular names, and they ARE drawn during history!
# Yes, `ProcessBar` calls `DoDrawBox` / `CheckBaseDropBox` which creates objects immediately.
# So `is_history` doesn't mean objects don't exist. They DO exist.
# We should just unconditionally update `OBJPROP_TIME` if the object exists.
bx_update_stats_patch_full = """      if(ts==0){if(im){g_bx_approach[k]=(na!=0)?na:(c>(top+bot)/2.0?1:-1);g_bx_touch_state[k]=1;g_bx_inside_cnt[k]=1;g_bx_event_time[k]=bar_time;
         if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectSetInteger(0,g_bx_nm[k],       OBJPROP_TIME,1,bar_time);
         if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,bar_time);
         if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,bar_time);
      }}"""
content = re.sub(r'      if\(ts==0\)\{if\(im\)\{g_bx_approach\[k\]=\(na!=0\)\?na:\(c>\(top\+bot\)/2\.0\?1:-1\);g_bx_touch_state\[k\]=1;g_bx_inside_cnt\[k\]=1;g_bx_event_time\[k\]=bar_time;\n\s*if\(!is_history\) \{\n\s*if\(ObjectFind.*?bar_time\);\n\s*\}\n\s*\}\}', bx_update_stats_patch_full, content, flags=re.DOTALL)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
