import re

with open('vol100.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Currently in GetMTFPullback:
#    // Simülasyon bitti, son durumu dışarı aktar
#    trend = sim_state.maj_tr;
#
#    ref_h = sim_state.maj_h;
#    ref_l = sim_state.maj_l;
#
#    // Zaman dizilerinde sınır aşımı kontrolü
#    int maj_h_idx = sim_state.maj_h_i < copied ? sim_state.maj_h_i : copied - 1;
#    int maj_l_idx = sim_state.maj_l_i < copied ? sim_state.maj_l_i : copied - 1;

old_block = """   // Simülasyon bitti, son durumu dışarı aktar
   trend = sim_state.maj_tr;

   ref_h = sim_state.maj_h;
   ref_l = sim_state.maj_l;

   // Zaman dizilerinde sınır aşımı kontrolü
   int maj_h_idx = sim_state.maj_h_i < copied ? sim_state.maj_h_i : copied - 1;
   int maj_l_idx = sim_state.maj_l_i < copied ? sim_state.maj_l_i : copied - 1;"""

new_block = """   // Simülasyon bitti, son durumu dışarı aktar
   trend = sim_state.maj_tr;

   // Eğer son dalga henüz onaylanmamışsa (maj_st == 0) yani fiyat kırılım yapmış ama
   // geri çekilip yeni bir minör tepe/dip oluşturarak zirveyi kilitlememişse,
   // hesaplamayı eski ve geride kalmış maj_h/maj_l yerine, o anki en uç noktalar (tmp_h/tmp_l) üzerinden yap!
   int m_h_i = sim_state.maj_h_i;
   int m_l_i = sim_state.maj_l_i;

   ref_h = sim_state.maj_h;
   ref_l = sim_state.maj_l;

   if (sim_state.maj_st == 0) {
       if (trend == 1) { // Up Trend: Yükselen trend devam ediyorsa, en uç nokta tmp_h'tir.
           ref_h = sim_state.tmp_h;
           m_h_i = sim_state.tmp_h_i;
       } else { // Down Trend: Düşen trend devam ediyorsa, en uç nokta tmp_l'dir.
           ref_l = sim_state.tmp_l;
           m_l_i = sim_state.tmp_l_i;
       }
   }

   // Zaman dizilerinde sınır aşımı kontrolü
   int maj_h_idx = m_h_i < copied ? m_h_i : copied - 1;
   int maj_l_idx = m_l_i < copied ? m_l_i : copied - 1;"""

content = content.replace(old_block, new_block)

with open('vol100.mq5', 'w', encoding='utf-8') as f:
    f.write(content)

print("MTF extrema fix applied.")
