import re

with open('smcvol01.mq5', 'r') as f:
    content = f.read()

# I see what's happening. `ProcessBar` sets `last_choch_dir` properly.
# But does `sup_text` actually have anything to append when `penalty == 0` and all text blocks are properly populated?
# Wait!
#    sup_text += h1_sup_text + m30_sup_text + m15_sup_text + m5_sup_text;
# And then:
#    msg += sup_text + "\\n";
# The user said: "Destekleyici yapilar ve cezalar kısmı hala boş choch analiz kısmına işlemiyor"
# Wait! "choch analiz kısmına işlemiyor". They meant the points are NOT added to the Total Points?
# `total_points += h1_sup_points + m30_sup_points + m15_sup_points + m5_sup_points;`
# `total_points += penalty;`
# It DOES add it to total_points!
