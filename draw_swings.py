import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Instead of drawing minor/major lines individually during historical Processing, we will draw the last 2 at the end of OnCalculate.
# However, the user said "zikzak kısımları al filan ilk öncelikle onları gizle arkada çalışsın ama gizli şekilde... 2 swing güncel olarak çizmeni istiyorum".
# The easiest way to hide old swings and keep only the last 2 is to clear all minor/major lines at the end of OnCalculate,
# and then manually draw the top 2 elements from the `st_h` and `st_l` stacks, plus the current LiveLeg.
# Actually, the indicator might draw hundreds of lines during history because ProcessBar contains DrawLine("Live_Minor_"...) or just "Minor_...".
# To prevent this, we should change the DrawLine calls inside ProcessBar so they don't draw anything when we don't want them to.
# Since there are input booleans `InpShowMin` and `InpShowMaj`, we can force them to be FALSE for historical drawing, or we can just delete all old lines at the end and redraw.
# But wait, deleting and redrawing every tick is slow if there are thousands of lines. Wait, it uses ObjectsDeleteAll(0,"Live_").
# For historical lines (no prefix), they are drawn once when `prev_calculated == 0`.
# We can just change ProcessBar so it NEVER draws minor/major lines directly.
# Wait, let's look at `OnCalculate`.

# Find where historical ProcessBar is called
on_calc_grep = re.search(r'int OnCalculate\(.*?\n\{.*?\n\}', content, re.DOTALL)
# Actually let's just patch ProcessBar to NOT draw lines for Minor/Major.
# Then in OnCalculate, after ProcessBar loop, we draw the last 2 swings.

# Wait, if we just disable InpShowMin and InpShowMaj entirely in the input? No, they are inputs.
# Let's change the DrawLine calls in ProcessBar to check if it's the last 2? Hard to do in a streaming way.
