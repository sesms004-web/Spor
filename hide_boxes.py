import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# We comment out the old `DoDrawBox` logic for `bx_phase` and `pot_bear_minor`/`pot_bull_minor`.
# Since these are in ProcessBar, we can just replace them with commented versions.

replacements = [
    (r'if\(state\.bx_phase==0\|\|state\.bx_phase==2\)\{DoDrawBox\(time,pfx,state,si,pp,sp,InpColorBoxBull\);',
     r'// if(state.bx_phase==0||state.bx_phase==2){DoDrawBox(time,pfx,state,si,pp,sp,InpColorBoxBull);'),
    (r'if\(state\.bx_phase==0\|\|state\.bx_phase==2\)\{DoDrawBox\(time,pfx,state,si,sp,tp,InpColorBoxBear\);',
     r'// if(state.bx_phase==0||state.bx_phase==2){DoDrawBox(time,pfx,state,si,sp,tp,InpColorBoxBear);'),
    (r'if\(state\.has_pot_bear_minor&&InpShowBox\)DoDrawBox\(time,pfx,state,state\.pot_bear_start_i,state\.pot_bear_start_p,state\.pot_bear_end_p,InpColorBoxBearFaint\);',
     r'// if(state.has_pot_bear_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bear_start_i,state.pot_bear_start_p,state.pot_bear_end_p,InpColorBoxBearFaint);'),
    (r'if\(state\.has_pot_bull_minor&&InpShowBox\)DoDrawBox\(time,pfx,state,state\.pot_bull_start_i,state\.pot_bull_end_p,state\.pot_bull_start_p,InpColorBoxBullFaint\);',
     r'// if(state.has_pot_bull_minor&&InpShowBox)DoDrawBox(time,pfx,state,state.pot_bull_start_i,state.pot_bull_end_p,state.pot_bull_start_p,InpColorBoxBullFaint);')
]

for pat, repl in replacements:
    content = re.sub(pat, repl, content)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
