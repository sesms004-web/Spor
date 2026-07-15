import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Fix the duplicate block in ShdBxAdvanceTrim
bad_block = """      else if(g_shd_state[k]==2)g_shd_state[k]=1;
   }
}
      else if(g_shd_state[k]==2)g_shd_state[k]=1;
   }
}"""

good_block = """      else if(g_shd_state[k]==2)g_shd_state[k]=1;
   }
}"""

content = content.replace(bad_block, good_block)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
