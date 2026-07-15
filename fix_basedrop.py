import re
# check that 'GetTimeSafe' can take (time, idx). Wait, what is the signature?
with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Let's ensure GetTimeSafe exists and takes datetime array and index
if "datetime GetTimeSafe(" in content:
    print("GetTimeSafe found.")
else:
    print("GetTimeSafe NOT found.")

# Let's also check DrawRect and DrawWeakRect signatures
if "void DrawRect(" in content:
    print("DrawRect found.")
else:
    print("DrawRect NOT found.")
