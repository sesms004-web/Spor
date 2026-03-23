with open('denemevol1.mq5', 'r') as f:
    text = f.read()
    import re
    match = re.search(r'//--- CHoCH Settings ---.*?\n\n', text, re.DOTALL)
    if match:
        print(match.group(0))
