import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# Fix H1 nested logic in EvaluateTradeSignal to match the exact matrix rules
search_h1 = """   if (h1_momentum) {
       if (is_h1_aligned) { h1_points = 40; h1_text = "H1 (Makro): Sert Momentum Dönüşü (Trend Onayı) -> [+40 Puan]\\n"; }
       else               { h1_points = 0;  h1_text = "H1 (Makro): Ters Yönde Sert Momentum (Tehlike!) -> [0 Puan]\\n"; }
   } else {
       if (p_h1 >= 50.0) { // Premium
           if (is_h1_aligned) { h1_points = 40; h1_text = "H1 (Makro): İdeal Pahalı/Ucuz Bölgesinde (Altın Vuruş) -> [+40 Puan]\\n"; }
           else               { h1_points = 20; h1_text = "H1 (Makro): İdeal Bölgede ama Ters Yön (Son İtiş) -> [+20 Puan]\\n"; }
       } else { // Discount
           if (is_h1_aligned) { h1_points = 0;  h1_text = "H1 (Makro): Trend Yönünde ama Fiyat Erken/Zayıf -> [0 Puan]\\n"; }
           else               { h1_points = 40; h1_text = "H1 (Makro): Yeni Düzeltme Başlıyor (Önü Açık) -> [+40 Puan]\\n"; }
       }
   }"""

replace_h1 = """   if (h1_momentum) {
       if (is_h1_aligned) { h1_points = 40; h1_text = "H1 (Makro): Sert Momentum Dönüşü (Trend Onayı) -> [+40 Puan]\\n"; }
       else               { h1_points = 0;  h1_text = "H1 (Makro): Ters Yönde Sert Momentum (Tehlike!) -> [0 Puan]\\n"; }
   } else {
       if (p_h1 >= 50.0) { // Premium
           if (is_h1_aligned) { h1_points = 40; h1_text = "H1 (Makro): İdeal Pahalı/Ucuz Bölgesinde (Altın Vuruş) -> [+40 Puan]\\n"; }
           else               { h1_points = 20; h1_text = "H1 (Makro): İdeal Bölgede ama Ters Yön (Son İtiş) -> [+20 Puan]\\n"; }
       } else { // Discount
           if (is_h1_aligned) { h1_points = 0;  h1_text = "H1 (Makro): Trend Yönünde ama Fiyat Erken/Zayıf -> [0 Puan]\\n"; }
           else               { h1_points = 40; h1_text = "H1 (Makro): Yeni Düzeltme Başlıyor (Önü Açık) -> [+40 Puan]\\n"; }
       }
   }"""

content = content.replace(search_h1, replace_h1)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)
