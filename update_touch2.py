import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Did my regex replace work? Let's check
if "double ext_top" not in content:
    print("Regex failed. Let's do it manually.")

    shd_old = "double top=g_shd_top[k],bot=g_shd_bot[k];\n      bool im=(h>=bot)&&(l<=top);"
    shd_new = """double top=g_shd_top[k],bot=g_shd_bot[k];
      double wk_sz=(top-bot)*InpWeakZonePct/100.0;
      bool im=(h>=bot-wk_sz)&&(l<=top+wk_sz);"""

    bx_old = "double top=g_bx_top[k],bot=g_bx_bot[k];\n      bool im=(h>=bot)&&(l<=top);"
    bx_new = """double top=g_bx_top[k],bot=g_bx_bot[k];
      double wk_sz=(top-bot)*InpWeakZonePct/100.0;
      bool im=(h>=bot-wk_sz)&&(l<=top+wk_sz);"""

    content = content.replace(shd_old, shd_new)
    content = content.replace(bx_old, bx_new)

    with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
        f.write(content)
else:
    print("Regex succeeded earlier.")
