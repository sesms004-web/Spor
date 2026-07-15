import re

with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
    content = f.read()

# Fix ShdBxAdvanceTrim
shd_replace = """void ShdBxAdvanceTrim()
{
   for(int k=0;k<g_shd_cnt;k++){
      if(g_shd_state[k]==1){
         if(g_shd_touch[k]>0){
            g_shd_state[k]=0;
         }
      }
      else if(g_shd_state[k]==2)g_shd_state[k]=1;
   }
}"""
content = re.sub(r'void ShdBxAdvanceTrim\(\).*?\}', shd_replace, content, flags=re.DOTALL)

# Fix BxAdvanceTrim
bx_replace = """void BxAdvanceTrim(datetime t)
{
   if(g_shadow_mode){ShdBxAdvanceTrim();return;}
   for(int k=0;k<g_bx_cnt;k++){
      if(g_bx_state[k]==1){
         if(g_bx_touch_state[k]>0){
            if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectSetInteger(0,g_bx_nm[k],       OBJPROP_TIME,1,g_bx_event_time[k]);
            if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,g_bx_event_time[k]);
            if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,g_bx_event_time[k]);
            g_bx_state[k]=0;
            continue;
         }
         if(ObjectFind(0,g_bx_nm[k])>=0)       ObjectSetInteger(0,g_bx_nm[k],       OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_wk_abv_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_abv_nm[k],OBJPROP_TIME,1,t);
         if(ObjectFind(0,g_bx_wk_blw_nm[k])>=0)ObjectSetInteger(0,g_bx_wk_blw_nm[k],OBJPROP_TIME,1,t);
         g_bx_state[k]=0;
      }
      else if(g_bx_state[k]==2)g_bx_state[k]=1;
   }
}"""
content = re.sub(r'void BxAdvanceTrim\(datetime t\)\s*\{.*?\n\}\n', bx_replace + '\n', content, flags=re.DOTALL)

with open('yeni_deneme_kutu_islemleri.mq5', 'w') as f:
    f.write(content)
