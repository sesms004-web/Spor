import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Modify BxUpdateStats to include Weak Zone (wk_sz) in touch condition
# Original:
# double top=g_bx_top[k],bot=g_bx_bot[k];
# bool im=(h>=bot)&&(l<=top);
# We also have ShdBxUpdateStats to modify:
# double top=g_shd_top[k],bot=g_shd_bot[k];
# bool im=(h>=bot)&&(l<=top);

def patch_touch(content, func_name, top_var, bot_var):
    pattern = r'double top=' + top_var + r',bot=' + bot_var + r';\n\s*bool im=\(h>=bot\)&&\(l<=top\);'
    replace = f"""double top={top_var},bot={bot_var};
      double wk_sz = (top - bot) * InpWeakZonePct / 100.0;
      double ext_top = top + wk_sz;
      double ext_bot = bot - wk_sz;
      bool im=(h>=ext_bot)&&(l<=ext_top);"""
    return re.sub(pattern, replace, content)

content = patch_touch(content, 'BxUpdateStats', 'g_bx_top[k]', 'g_bx_bot[k]')
content = patch_touch(content, 'ShdBxUpdateStats', 'g_shd_top[k]', 'g_shd_bot[k]')

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
