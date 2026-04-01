with open('denemevol1.mq5', 'r') as f:
    text = f.read()
    import re
    if "İzin" in text:
        print("Still has İzin")
    if "InpMaxBreakoutPct" in text:
        print("Still has InpMaxBreakoutPct")
    print(re.search(r'//--- CHoCH Settings ---.*?\n\n', text, re.DOTALL).group(0))
