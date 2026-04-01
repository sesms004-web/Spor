import re

with open('denemevol1.mq5', 'r') as f:
    content = f.read()

deinit_search = """   ObjectsDeleteAll(0, "HLine_");
   ObjectsDeleteAll(0, "LiveLeg_");
  }"""

deinit_replace = """   ObjectsDeleteAll(0, "HLine_");
   ObjectsDeleteAll(0, "LiveLeg_");
   ObjectsDeleteAll(0, "CHoCH_Bear_");
   ObjectsDeleteAll(0, "CHoCH_Bull_");
  }"""

content = content.replace(deinit_search, deinit_replace)

oncalc_del_search = """      ObjectsDeleteAll(0, "HLine_");
      ObjectsDeleteAll(0, "LiveLeg_");

      int start_idx = 0;"""

oncalc_del_replace = """      ObjectsDeleteAll(0, "HLine_");
      ObjectsDeleteAll(0, "LiveLeg_");
      ObjectsDeleteAll(0, "CHoCH_Bear_");
      ObjectsDeleteAll(0, "CHoCH_Bull_");

      int start_idx = 0;"""

content = content.replace(oncalc_del_search, oncalc_del_replace)

with open('denemevol1.mq5', 'w') as f:
    f.write(content)

print("Deinit patched")
