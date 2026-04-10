with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's count them properly across the whole function ProcessBar to ensure it's balanced there.
start_idx = text.find('void ProcessBar(')
end_idx = text.find('//+------------------------------------------------------------------+\n//| Custom indicator iteration function')

if start_idx != -1 and end_idx != -1:
    func_text = text[start_idx:end_idx]
    opens = func_text.count('{')
    closes = func_text.count('}')
    print(f"ProcessBar opens: {opens}, closes: {closes}")
