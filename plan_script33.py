import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Let's see if the boxes becoming infinite is because of `is_history`.
# In memory: "In MQL5 SMC indicators, UI-trimming functions (like BxAdvanceTrim) must be allowed to execute on live ticks (is_history = false) to properly trim expiring boxes when a trend flips dynamically. Guarding them entirely behind is_history causes boxes to stretch indefinitely."
# Did I accidentally add `if(is_history)` around `BxAdvanceTrim`?
# Let's check `BxAdvanceTrim` calls.
print("BxAdvanceTrim calls:")
for i, line in enumerate(code.split('\n')):
    if "BxAdvanceTrim" in line and "void" not in line:
        print(i+1, line.strip())
