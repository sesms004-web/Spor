import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Fix orphaned else if in ProcessBar
replace1 = """
            // if(state.bx_phase==0||state.bx_phase==2){DoDrawBox(time,pfx,state,si,pp,sp,InpColorBoxBull);state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=pp;state.bx_swing_l=sp;}
            // else if(pp>state.bx_swing_h){state.bx_extreme=true;state.bx_swing_h=pp;}
"""
content = re.sub(r'// if\(state\.bx_phase==0\|\|state\.bx_phase==2\)\{DoDrawBox\(time,pfx,state,si,pp,sp,InpColorBoxBull\);state\.bx_phase=1;state\.bx_extreme=false;state\.bx_swing_h=pp;state\.bx_swing_l=sp;\}\n\s*else if\(pp>state\.bx_swing_h\)\{state\.bx_extreme=true;state\.bx_swing_h=pp;\}', replace1, content)


replace2 = """
            // if(state.bx_phase==0||state.bx_phase==2){DoDrawBox(time,pfx,state,si,sp,tp,InpColorBoxBear);state.bx_phase=1;state.bx_extreme=false;state.bx_swing_h=sp;state.bx_swing_l=tp;}
            // else if(tp<state.bx_swing_l){state.bx_extreme=true;state.bx_swing_l=tp;}
"""
content = re.sub(r'// if\(state\.bx_phase==0\|\|state\.bx_phase==2\)\{DoDrawBox\(time,pfx,state,si,sp,tp,InpColorBoxBear\);state\.bx_phase=1;state\.bx_extreme=false;state\.bx_swing_h=sp;state\.bx_swing_l=tp;\}\n\s*else if\(tp<state\.bx_swing_l\)\{state\.bx_extreme=true;state\.bx_swing_l=tp;\}', replace2, content)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
