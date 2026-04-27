import re

with open('smcv1.mq5', 'r') as f:
    content = f.read()

# Make the drawing isolated by correctly using ObjectsDeleteAll to prevent ghost texts.
del_search = """      ObjectsDeleteAll(0, "CHoCH_Bull_");
      ObjectsDeleteAll(0, "CHoCH_Path_");
      ObjectsDeleteAll(0, "CHoCH_Signal_");"""

del_replace = """      ObjectsDeleteAll(0, "CHoCH_Bull_");
      ObjectsDeleteAll(0, "CHoCH_Path_");
      ObjectsDeleteAll(0, "CHoCH_Signal_");
      ObjectsDeleteAll(0, "CHoCH_Text_");"""

content = content.replace(del_search, del_replace)

with open('smcv1.mq5', 'w') as f:
    f.write(content)
