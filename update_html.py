import re

with open('input.html', 'r') as f:
    html = f.read()

# Make it mobile responsive

# 1. Update the aside element for mobile responsiveness
html = html.replace(
    '<aside class="w-64 min-w-[256px] shrink-0 bg-slate-900 border-r border-slate-800 flex flex-col h-screen sticky top-0">',
    '<aside id="sidebar" class="fixed inset-y-0 left-0 z-50 w-64 min-w-[256px] shrink-0 bg-slate-900 border-r border-slate-800 flex flex-col h-screen transition-transform duration-300 -translate-x-full md:relative md:translate-x-0">'
)

# Add a backdrop for the sidebar on mobile
html = html.replace(
    '<!-- Main Content -->',
    '<!-- Mobile Sidebar Backdrop -->\n    <div id="sidebar-backdrop" onclick="toggleSidebar()" class="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-40 hidden md:hidden"></div>\n\n    <!-- Main Content -->'
)

# 2. Update Header to add hamburger menu button
html = html.replace(
    '<header class="bg-slate-900/80 backdrop-blur-md border-b border-slate-800 px-8 py-4 sticky top-0 z-40 flex justify-between items-center">',
    '<header class="bg-slate-900/80 backdrop-blur-md border-b border-slate-800 px-4 md:px-8 py-4 sticky top-0 z-30 flex justify-between items-center">'
)
html = html.replace(
    '<h2 id="page-title" class="text-xl font-bold text-slate-100">Takvim</h2>',
    '<div class="flex items-center space-x-4">\n                <button onclick="toggleSidebar()" class="md:hidden p-2 text-slate-400 hover:text-slate-100 rounded-lg hover:bg-slate-800 transition-colors">\n                    <i data-lucide="menu" class="w-6 h-6"></i>\n                </button>\n                <h2 id="page-title" class="text-xl font-bold text-slate-100">Takvim</h2>\n            </div>'
)

# 3. Add JS function to toggle sidebar
js_func = """
        // Sidebar Toggle for Mobile
        function toggleSidebar() {
            const sidebar = document.getElementById('sidebar');
            const backdrop = document.getElementById('sidebar-backdrop');
            if (sidebar.classList.contains('-translate-x-full')) {
                sidebar.classList.remove('-translate-x-full');
                backdrop.classList.remove('hidden');
            } else {
                sidebar.classList.add('-translate-x-full');
                backdrop.classList.add('hidden');
            }
        }
"""
html = html.replace('// State Management', js_func + '\n        // State Management')

# Make the switchTab function do it correctly
html = html.replace(
    'lucide.createIcons();\n        }',
    "lucide.createIcons();\n            \n            if (window.innerWidth < 768) {\n                const sidebar = document.getElementById('sidebar');\n                const backdrop = document.getElementById('sidebar-backdrop');\n                if (sidebar && !sidebar.classList.contains('-translate-x-full')) {\n                    sidebar.classList.add('-translate-x-full');\n                    backdrop.classList.add('hidden');\n                }\n            }\n        }"
)

# 4. Make other elements mobile friendly
html = html.replace('<div class="p-8">', '<div class="p-4 md:p-8">')

html = html.replace(
    '<h3 id="calendar-month-year" class="text-2xl font-bold text-slate-100 min-w-[150px] text-center">',
    '<h3 id="calendar-month-year" class="text-lg md:text-2xl font-bold text-slate-100 min-w-[120px] md:min-w-[150px] text-center">'
)

html = html.replace('<table class="w-full text-left min-w-[1000px]">', '<table class="w-full text-left min-w-[800px] overflow-x-auto block md:table">')
html = html.replace('<th class="px-8 py-4">Tarih</th>', '<th class="px-4 md:px-8 py-4">Tarih</th>')
html = html.replace('<td class="px-8 py-4 text-xs text-slate-400">', '<td class="px-4 md:px-8 py-4 text-xs text-slate-400">')
html = html.replace('<td class="px-8 py-4 text-xs text-slate-500 max-w-[200px]"', '<td class="px-4 md:px-8 py-4 text-xs text-slate-500 max-w-[200px]"')

html = html.replace(
    '<div class="grid grid-cols-2 gap-4">',
    '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">'
)
html = html.replace(
    '<div class="grid grid-cols-3 gap-4">',
    '<div class="grid grid-cols-1 md:grid-cols-3 gap-4">'
)

html = html.replace(
    '<div class="grid grid-cols-3 gap-2" id="setup-buttons-container">',
    '<div class="grid grid-cols-2 md:grid-cols-3 gap-2" id="setup-buttons-container">'
)

html = html.replace(
    '<div class="bg-slate-900 w-full max-w-3xl h-[80vh] rounded-3xl border border-slate-800 shadow-2xl flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200">',
    '<div class="bg-slate-900 w-full max-w-3xl h-[90vh] md:h-[80vh] rounded-3xl border border-slate-800 shadow-2xl flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200">'
)

html = html.replace('<div class="flex space-x-2">', '<div class="flex flex-col md:flex-row space-y-2 md:space-y-0 md:space-x-2">')

html = html.replace(
    '<form id="trade-form" onsubmit="handleTradeSubmit(event)" class="p-8 space-y-4">',
    '<form id="trade-form" onsubmit="handleTradeSubmit(event)" class="p-4 md:p-8 space-y-4 max-h-[80vh] overflow-y-auto">'
)

html = html.replace('<div class="p-6">', '<div class="p-4 md:p-6">')

# Fix modal padding
html = html.replace('class="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 hidden flex items-center justify-center p-6"', 'class="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 hidden flex items-center justify-center p-4 md:p-6"')


with open('index.html', 'w') as f:
    f.write(html)
