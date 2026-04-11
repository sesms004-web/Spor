with open('index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the Trade Modal container to have a max-height so it doesn't bleed off screen
# It is currently:
# <div class="bg-slate-900 w-full max-w-lg rounded-3xl border border-slate-800 shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200">
# Make it have flex flex-col and max-h-[90vh]
content = content.replace(
    '<div class="bg-slate-900 w-full max-w-lg rounded-3xl border border-slate-800 shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200">',
    '<div class="bg-slate-900 w-full max-w-lg max-h-[90vh] md:max-h-[85vh] rounded-3xl border border-slate-800 shadow-2xl flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200">'
)

# 2. Update the form inside the Trade Modal to be scrollable
# It is currently:
# <form id="trade-form" onsubmit="handleTradeSubmit(event)" class="p-8 space-y-4">
content = content.replace(
    '<form id="trade-form" onsubmit="handleTradeSubmit(event)" class="p-8 space-y-4">',
    '<form id="trade-form" onsubmit="handleTradeSubmit(event)" class="p-4 md:p-8 space-y-4 overflow-y-auto overscroll-contain flex-grow">'
)

# Also let's check Account Modal:
content = content.replace(
    '<div class="bg-slate-900 w-full max-w-md rounded-3xl border border-slate-800 shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200">',
    '<div class="bg-slate-900 w-full max-w-md max-h-[90vh] rounded-3xl border border-slate-800 shadow-2xl flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200">'
)

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(content)
