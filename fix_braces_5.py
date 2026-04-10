with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Verify OnCalculate
start_idx = text.find('int OnCalculate(')
func_text = text[start_idx:]
opens = func_text.count('{')
closes = func_text.count('}')
print(f"OnCalculate opens: {opens}, closes: {closes}")
