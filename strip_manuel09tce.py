import re

with open('Mmuoooeop.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Strip MTF Alert System Inputs
content = re.sub(r'// ─── Test Bildirimi ───.*?// ───', '// ───', content, flags=re.DOTALL)
content = re.sub(r'input group "--- BILDIRIM TEST ---".*?InpAlertPopup\s*=\s*false;\n', '', content, flags=re.DOTALL)

# 2. Strip MTF & Alert Functions
content = re.sub(r'// ─── TF Kutu Analizi \(Shadow\) ───.*?(?=\n// ─── OnInit ───)', '', content, flags=re.DOTALL)
content = re.sub(r'// ─── Bildirim Tekrar Engeli ───\nint g_last_notif_d1i_sell = -1;\nint g_last_notif_d1i_buy  = -1;\n', '', content, flags=re.DOTALL)


# 3. Inside ProcessBar, strip SendNotifMTF calls and string building
content = re.sub(r'SendNotifMTF\(.*?;\n', '', content)
content = re.sub(r'\s*if\(InpAlertPopup\)\s*Alert\(.*?\);', '', content)
content = re.sub(r'\s*if\(InpAlertPush\)\s*SendNotification\(.*?\);', '', content)


with open('Mmuoooeop.mq5', 'w', encoding='utf-8') as f:
    f.write(content)
