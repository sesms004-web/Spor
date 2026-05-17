import re

with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Let's inspect BxAdvanceTrim
# Ah, the user said "Gereksiz şekilde kutularin uzunluğu sınırsız oldu".
# If I changed `BxAdvanceTrim` to use `ObjectSetInteger(0,g_bx_nm[k],OBJPROP_TIME,1,t);`
# Actually, I never changed `BxAdvanceTrim`! It was like that before!
# BUT if `g_bx_state[k]` isn't 1...
# When `BxAdd` is called, `g_bx_state[k] = 2;`.
# Then `BxAdvanceTrim` is called:
# `else if(g_bx_state[k]==2) g_bx_state[k]=1;`
# So the *first* time `BxAdvanceTrim` is called after a box is added, its state goes from 2 -> 1.
# The *second* time it's called, if `g_bx_touch_state[k]==1`, it skips. Otherwise, it trims it to time `t`, and `g_bx_state[k]=0` (inactive).
# Wait, did I break `g_bx_touch_state[k]`?
# "if(ts==0) { if(im) { g_bx_touch_state[k]=1; ... } }"
# If `g_bx_touch_state[k]` becomes 1, it means the price is INSIDE the box.
# If the price exits the box, `ts==1` and `im==false`:
# `else if(ts==1){ if(im){...} else { ... g_bx_touch_state[k]=2 or 3; } }`
# So `g_bx_touch_state` becomes 2 or 3.
# Then the next `BxAdvanceTrim` will see `g_bx_state[k]==1` and `g_bx_touch_state[k]!=1`, so it WILL trim it.
# So why would the boxes be infinite now?
# Wait! In `BxUpdateStats`, `if(ts==0){ if(im){ g_bx_touch_state[k]=1; } }`
# Did I change how `im` is evaluated?
# `bool im=(h>=bot)&&(l<=top);`
# It was like that before.
# What if it's the right_ray?
# In `DrawRect`, `ObjectCreate(0,nm,OBJ_RECTANGLE,0,t1,top,t2,bot);`
# Wait... if `g_bx_state` somehow stays at 2?
# The user said "Gereksiz şekilde kutularin uzunluğu sınırsız oldu" ... maybe the user *means* something else.
# Like "boxes used to trim but now they don't".
