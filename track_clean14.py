with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Verify no more "variable already defined" for c_dir_h1.
c_dir_h1_count = text.count('int c_dir_h1')
if c_dir_h1_count > 1:
    print('Found duplicate c_dir_h1')
else:
    print('c_dir_h1 ok')
