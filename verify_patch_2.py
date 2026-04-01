with open('denemevol1.mq5', 'r') as f:
    text = f.read()
    import re
    if "Zirve:" in text and "Çekilme:" in text:
        print("Patch is in the file!")
    else:
        print("Patch is NOT in the file!")
