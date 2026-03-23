import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Completely remove the input variable
search_input = "input double InpMaxBreakoutPct = 50.0;           // CHoCH Maksimum İzin Verilen Kırılım %\n"
content = content.replace(search_input, "")

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Input removed completely")
