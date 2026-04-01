import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

# H1 Replacement
search_h1 = """   // --- H1 MACRO LOGIC ---
   int h1_points = 0;
   bool h1_momentum = ((mp_h1 - p_h1) >= 20.0);
   bool is_h1_aligned = (t_h1 == trigger_dir);

   if (h1_momentum) {
       string peak_str = DoubleToString(mp_h1, 0);
       string bounce_str = DoubleToString(mp_h1 - p_h1, 0);
       if (is_h1_aligned) { h1_points = 30; h1_text = "H1 (Makro): %" + peak_str + " zirvesinden %" + bounce_str + " Sert Dönüş (İvme) -> [+30 Puan]\\n"; }
       else               { h1_points = 0;  h1_text = "H1 (Makro): %" + peak_str + " zirvesinden %" + bounce_str + " Ters İvme (Tehlike) -> [0 Puan]\\n"; }
   } else {
       if (p_h1 >= 50.0) { // Premium
           if (is_h1_aligned) { h1_points = 30; h1_text = "H1 (Makro): İdeal Pahalı/Ucuz Bölgesinde (Altın Vuruş) -> [+30 Puan]\\n"; }
           else               { h1_points = 20; h1_text = "H1 (Makro): İdeal Bölgede ama Ters Yön (Son İtiş) -> [+20 Puan]\\n"; }
       } else { // Discount
           if (is_h1_aligned) { h1_points = 0;  h1_text = "H1 (Makro): Trend Yönünde ama Fiyat Erken/Zayıf -> [0 Puan]\\n"; }
           else               { h1_points = 30; h1_text = "H1 (Makro): Yeni Düzeltme Başlıyor (Önü Açık) -> [+30 Puan]\\n"; }
       }
   }"""

replace_h1 = """   // --- H1 MACRO LOGIC ---
   int h1_points = 0;
   bool h1_momentum = ((mp_h1 - p_h1) >= 20.0);
   bool is_h1_aligned = (t_h1 == trigger_dir);
   string peak_str_h1 = DoubleToString(mp_h1, 1);
   string bounce_str_h1 = DoubleToString(mp_h1 - p_h1, 1);
   string stats_h1 = "[Zirve:%" + peak_str_h1 + " | Çekilme:%" + bounce_str_h1 + "] ";

   if (h1_momentum) {
       if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "Sert Dönüş (İvme) -> [+30 Puan]\\n"; }
       else               { h1_points = 0;  h1_text = "H1: " + stats_h1 + "Ters İvme (Tehlike) -> [0 Puan]\\n"; }
   } else {
       if (p_h1 >= 50.0) { // Premium
           if (is_h1_aligned) { h1_points = 30; h1_text = "H1: " + stats_h1 + "İdeal Bölge (Altın Vuruş) -> [+30 Puan]\\n"; }
           else               { h1_points = 20; h1_text = "H1: " + stats_h1 + "İdeal Bölgede ama Ters Yön -> [+20 Puan]\\n"; }
       } else { // Discount
           if (is_h1_aligned) { h1_points = 0;  h1_text = "H1: " + stats_h1 + "Erken/Zayıf Bölge -> [0 Puan]\\n"; }
           else               { h1_points = 30; h1_text = "H1: " + stats_h1 + "Yeni Düzeltme (Önü Açık) -> [+30 Puan]\\n"; }
       }
   }"""

content = content.replace(search_h1, replace_h1)

# M30 Replacement
search_m30 = """   // --- M30 MODIFIER LOGIC ---
   int m30_points = 0;
   bool m30_momentum = ((mp_m30 - p_m30) >= 20.0);
   bool is_m30_aligned = (t_m30 == trigger_dir);

   if (m30_momentum) {
       string peak_str = DoubleToString(mp_m30, 0);
       string bounce_str = DoubleToString(mp_m30 - p_m30, 0);
       if (is_m30_aligned) { m30_points = 15; m30_text = "M30 (Ara Filtre): %" + peak_str + " zirvesinden %" + bounce_str + " Sert İvme -> [+15 Puan]\\n"; }
       else                { m30_points = -5; m30_text = "M30 (Ara Filtre): %" + peak_str + " zirvesinden %" + bounce_str + " Ters İvme -> [-5 Puan]\\n"; }
   } else {
       if (p_m30 >= 50.0) {
           if (is_m30_aligned) { m30_points = 10;  m30_text = "M30 (Ara Filtre): Şişkin Bölgede Destekliyor -> [+10 Puan]\\n"; }
           else                { m30_points = -10; m30_text = "M30 (Ara Filtre): Şişkin Bölgede Direnç (Ters) -> [-10 Puan]\\n"; }
       } else {
           if (is_m30_aligned) { m30_points = 10;  m30_text = "M30 (Ara Filtre): Yolun Başında Destekliyor -> [+10 Puan]\\n"; }
           else                { m30_points = 10;  m30_text = "M30 (Ara Filtre): Sağlıklı Düzeltme Yapıyor (Olumlu) -> [+10 Puan]\\n"; }
       }
   }"""

replace_m30 = """   // --- M30 MODIFIER LOGIC ---
   int m30_points = 0;
   bool m30_momentum = ((mp_m30 - p_m30) >= 20.0);
   bool is_m30_aligned = (t_m30 == trigger_dir);
   string peak_str_m30 = DoubleToString(mp_m30, 1);
   string bounce_str_m30 = DoubleToString(mp_m30 - p_m30, 1);
   string stats_m30 = "[Zirve:%" + peak_str_m30 + " | Çekilme:%" + bounce_str_m30 + "] ";

   if (m30_momentum) {
       if (is_m30_aligned) { m30_points = 15; m30_text = "M30: " + stats_m30 + "Sert İvme (Onay) -> [+15 Puan]\\n"; }
       else                { m30_points = -5; m30_text = "M30: " + stats_m30 + "Ters İvme (Tehlike) -> [-5 Puan]\\n"; }
   } else {
       if (p_m30 >= 50.0) {
           if (is_m30_aligned) { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Şişkin Bölgede Destek -> [+10 Puan]\\n"; }
           else                { m30_points = -10; m30_text = "M30: " + stats_m30 + "Şişkin Bölgede Direnç -> [-10 Puan]\\n"; }
       } else {
           if (is_m30_aligned) { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Yolun Başında Destek -> [+10 Puan]\\n"; }
           else                { m30_points = 10;  m30_text = "M30: " + stats_m30 + "Sağlıklı Düzeltme -> [+10 Puan]\\n"; }
       }
   }"""

content = content.replace(search_m30, replace_m30)

# M15 Replacement
search_m15 = """   if (is_duplicate) {
       m15_points = 0; m15_text = "M15 (Ara Filtre): M30 ile aynı dalga, pas geçildi. -> [0 Puan]\\n";
   } else {
       if (m15_momentum) {
           string peak_str = DoubleToString(mp_m15, 0);
           string bounce_str = DoubleToString(mp_m15 - p_m15, 0);
           if (is_m15_aligned) { m15_points = 10; m15_text = "M15 (Ara Filtre): %" + peak_str + " zirvesinden %" + bounce_str + " Sert İvme -> [+10 Puan]\\n"; }
           else                { m15_points = 0;  m15_text = "M15 (Ara Filtre): %" + peak_str + " zirvesinden %" + bounce_str + " Ters İvme -> [0 Puan]\\n"; }
       } else {
           if (p_m15 >= 50.0) {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15 (Ara Filtre): Şişkin Bölgede Destekliyor -> [+5 Puan]\\n"; }
               else                { m15_points = -5; m15_text = "M15 (Ara Filtre): Şişkin Bölgede Direnç (Ters) -> [-5 Puan]\\n"; }
           } else {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15 (Ara Filtre): Yolun Başında Destekliyor -> [+5 Puan]\\n"; }
               else                { m15_points = 5;  m15_text = "M15 (Ara Filtre): Sağlıklı Düzeltme Yapıyor -> [+5 Puan]\\n"; }
           }
       }
   }"""

replace_m15 = """   string peak_str_m15 = DoubleToString(mp_m15, 1);
   string bounce_str_m15 = DoubleToString(mp_m15 - p_m15, 1);
   string stats_m15 = "[Zirve:%" + peak_str_m15 + " | Çekilme:%" + bounce_str_m15 + "] ";

   if (is_duplicate) {
       m15_points = 0; m15_text = "M15: " + stats_m15 + "M30 ile aynı dalga -> [0 Puan]\\n";
   } else {
       if (m15_momentum) {
           if (is_m15_aligned) { m15_points = 10; m15_text = "M15: " + stats_m15 + "Sert İvme (Onay) -> [+10 Puan]\\n"; }
           else                { m15_points = 0;  m15_text = "M15: " + stats_m15 + "Ters İvme (Zayıf Etki) -> [0 Puan]\\n"; }
       } else {
           if (p_m15 >= 50.0) {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Şişkin Bölgede Destek -> [+5 Puan]\\n"; }
               else                { m15_points = -5; m15_text = "M15: " + stats_m15 + "Şişkin Bölgede Direnç -> [-5 Puan]\\n"; }
           } else {
               if (is_m15_aligned) { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Yolun Başında Destek -> [+5 Puan]\\n"; }
               else                { m15_points = 5;  m15_text = "M15: " + stats_m15 + "Sağlıklı Düzeltme -> [+5 Puan]\\n"; }
           }
       }
   }"""

content = content.replace(search_m15, replace_m15)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Final patch applied to file")
