with open('smacv1.mq5', 'r', encoding='utf-8') as f:
    for i, line in enumerate(f):
        if 'c_dir_h1' in line or 'InpTriggerLevel1' in line or 'InpTestMode' in line:
            print(f"{i+1}: {line.strip()}")
