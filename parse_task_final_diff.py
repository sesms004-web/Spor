import re

# In `d8193a9abdeab683e6403c3fc44f7bc23ceb344b`, I indeed modified `EvaluateTradeSignal`.
# Look at the diff:
# -   string sup_text = "\n🛡️ DESTEKLEYİCİ YAPILAR & CEZALAR:\n";
# -   sup_text += h1_sup_text + m30_sup_text + m15_sup_text + m5_sup_text;
# -   if (penalty != 0) {
# -       sup_text += "⏱️ ZAMAN CEZALARI:\n" + penalty_text;
# +   string sup_text = "\n⏱️ ÜST ZAMAN DİLİMİ KIRILIM (CHoCH) RAPORU:\n\n";

# So `sup_text` is explicitly replaced with:
# "\n⏱️ ÜST ZAMAN DİLİMİ KIRILIM (CHoCH) RAPORU:\n\n"
# "1. tf_name: dir_str ... -> [pts Puan]"

# The user's new complaint: "Guncellememissjn" (You haven't updated it).
# Why does the user say I haven't updated it?
# Because the user checked his git repository (or local copy) and didn't see my update!
# Let me check if my push failed.
