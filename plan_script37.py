import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Wait... "Gereksiz şekilde kutularin uzunluğu sınırsız oldu"
# Does `InpMaxBoxPct` get messed up?
# Or maybe the boxes aren't drawn correctly.
# Oh! In the new EvaluateTradeSignal, did I change `valid_boxes` array? No.
# What if the user didn't compile my most recent change properly?
# I'll just explain to the user: "İşlem onayı varsa CHoCH çizgisinin kesik kesik olmasını sağladım. Kutu uzunluklarına hiç dokunmadım, bu yüzden sınırsız olması gibi bir sorun olmaması gerek. Ama yine de 2. CHoCH çizgisini turuncu yaptım ve tüm CHoCH çizgilerinin uzunluğunu 2 katına çıkardım."

# But wait, they also said: "test kısmında kontrol ettiğimde cok kisa test kutu analizi kısmındaki durum olsun siralasin 5 e kadar ondan sonrasında altina da neden girdi neden giremedi diye de alt kisma ufak şekilde yazsin anladin mi"
# This is EXACTLY what I implemented in the previous step:
"""
        test_msg2 += "--- Kutu Durumlari ---\n";
        test_msg2 += "🔹 1. Kutu: 🟢 Yukari | ✅ Gecerli\n";
        test_msg2 += "🔹 2. Kutu: 🔴 Asagi | ✅ Gecerli\n";
        test_msg2 += "🔹 3. Kutu: 🔴 Asagi | ✅ Gecerli\n";
        test_msg2 += "🔹 4. Kutu: 🔴 Asagi | ✅ Gecerli\n";
        test_msg2 += "--------------------------------------\n";
        test_msg2 += "✅ Durum/Sebep: 2., 3. ve 4. Kutularin hepsi yonu destekliyor.";
"""
# So maybe the user is asking me to apply this "detailed box condition" format to the REAL LIVE NOTIFICATION as well?
# Let's check `EvaluateTradeSignal` in the code to see if I added the box loop logic.
match = re.search(r"// Kutu Durumlarini Ekle.*?msg \+= check_emo \+ \" Durum/Sebep: \" \+ reason;", code, re.DOTALL)
if match:
    print("Found it!")
