import re

with open('manuel09tce.mq5', 'r', encoding='utf-8') as f:
    man_code = f.read()

# I will cleanly copy the `manuel09tce.mq5` file to `Mmuoooeop.mq5`
with open('Mmuoooeop.mq5', 'w', encoding='utf-8') as f:
    f.write(man_code)
