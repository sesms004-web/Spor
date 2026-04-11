import sys

html_content = r"""<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>All Trading Journal</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: #020617;
            color: #f8fafc;
        }
        .calendar-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
        }
        .glass {
            background: rgba(15, 23, 42, 0.8);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .active-tab {
            background-color: #0ea5e9; /* Sky 500 */
            color: white !important;
        }
        .active-tab i, .active-tab span {
            color: white !important;
        }
        .scrollbar-hide::-webkit-scrollbar {
            display: none;
        }
        .dark-card {
            background-color: #0f172a;
            border: 1px solid #1e293b;
        }
        .dark-input {
            background-color: #1e293b;
            border: 1px solid #334155;
            color: #f8fafc;
        }
        .dark-input:focus {
            border-color: #0ea5e9;
            ring: 2px;
            ring-color: #0ea5e9;
        }
    </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen flex overflow-hidden">

    <!-- Sidebar -->
    <aside class="w-64 min-w-[256px] shrink-0 bg-slate-900 border-r border-slate-800 flex flex-col h-screen sticky top-0">
        <div class="p-6">
            <div class="flex items-center space-x-2 text-sky-500 font-bold text-xl tracking-tight">
                <i data-lucide="trending-up" class="w-8 h-8"></i>
                <span>All Trading</span>
            </div>
        </div>

        <nav class="flex-grow px-4 space-y-2 mt-4">
            <button onclick="switchTab('home')" id="nav-home" class="w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all hover:bg-slate-800 text-slate-400 active-tab">
                <i data-lucide="home" class="w-5 h-5"></i>
                <span class="font-semibold">Ana Sayfa</span>
            </div>

            <div id="account-nav" class="hidden space-y-2">
                <button onclick="switchTab('calendar')" id="nav-calendar" class="w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all hover:bg-slate-800 text-slate-400">
                    <i data-lucide="calendar" class="w-5 h-5"></i>
                    <span class="font-semibold">Takvim</span>
                </button>
                <button onclick="switchTab('history')" id="nav-history" class="w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all hover:bg-slate-800 text-slate-400">
                    <i data-lucide="list" class="w-5 h-5"></i>
                    <span class="font-semibold">İşlemler</span>
                </button>
                <button onclick="switchTab('analysis')" id="nav-analysis" class="w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all hover:bg-slate-800 text-slate-400">
                    <i data-lucide="bar-chart-3" class="w-5 h-5"></i>
                    <span class="font-semibold">Analiz</span>
                </button>
                <button onclick="switchTab('balance')" id="nav-balance" class="w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all hover:bg-slate-800 text-slate-400">
                    <i data-lucide="wallet" class="w-5 h-5"></i>
                    <span class="font-semibold">Bakiye</span>
                </button>
                <button onclick="switchTab('notes')" id="nav-notes" class="w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all hover:bg-slate-800 text-slate-400">
                    <i data-lucide="sticky-note" class="w-5 h-5"></i>
                    <span class="font-semibold">Notlar</span>
                </button>
                <button onclick="switchTab('settings')" id="nav-settings" class="w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all hover:bg-slate-800 text-slate-400">
                    <i data-lucide="settings" class="w-5 h-5"></i>
                    <span class="font-semibold">Ayarlar</span>
                </button>
            </div>
        </nav>

        <div id="bottom-home-nav" class="hidden px-4 mb-2">
            <button onclick="switchTab('home')" class="w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all hover:bg-slate-800 text-slate-400">
                <i data-lucide="chevron-left" class="w-5 h-5"></i>
                <span class="font-semibold">Ana Sayfa</span>
            </button>
        </div>

        <div class="p-4 border-t border-slate-800 flex justify-around items-center">
            <button onclick="backupData()" class="p-3 hover:bg-slate-800 rounded-xl text-slate-400 hover:text-sky-400 transition-all" title="Verileri Yedekle">
                <i data-lucide="save" class="w-5 h-5"></i>
            </button>
            <button onclick="document.getElementById('restore-input').click()" class="p-3 hover:bg-slate-800 rounded-xl text-slate-400 hover:text-emerald-400 transition-all" title="Yedekten Geri Yükle">
                <i data-lucide="upload-cloud" class="w-5 h-5"></i>
            </button>
            <input type="file" id="restore-input" class="hidden" accept=".json" onchange="restoreData(event)">
        </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-grow overflow-y-auto h-screen scrollbar-hide relative">

        <!-- Header -->
        <header class="bg-slate-900/80 backdrop-blur-md border-b border-slate-800 px-8 py-4 sticky top-0 z-40 flex justify-between items-center">
            <h2 id="page-title" class="text-xl font-bold text-slate-100">Takvim</h2>
            <div class="flex items-center space-x-4">
                <span id="current-date-display" class="text-sm font-medium text-slate-400"></span>
                <div id="account-badge" class="px-3 py-1.5 rounded-full bg-sky-900/50 flex items-center justify-center text-sky-400 font-bold border border-sky-800 text-sm">
                    MT
                </div>
            </div>
        </header>

        <!-- Sections Container -->
        <div class="p-8">

            <!-- Home Section (Account Management) -->
            <section id="section-home" class="hidden space-y-8">
                <div class="flex justify-between items-center">
                    <h3 class="text-2xl font-bold text-slate-100">Hesaplar</h3>
                    <button onclick="openAccountModal()" class="bg-sky-600 text-white px-6 py-2.5 rounded-xl font-bold hover:bg-sky-700 transition-all flex items-center space-x-2 shadow-lg shadow-sky-900/20">
                        <i data-lucide="plus" class="w-5 h-5"></i>
                        <span>Yeni Hesap Ekle</span>
                    </button>
                </div>

                <div class="space-y-6">
                    <div>
                        <h4 class="text-sm font-bold text-slate-500 uppercase tracking-wider mb-4">Aktif Hesaplar</h4>
                        <div id="active-accounts-list" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                            <!-- Active accounts will be injected here -->
                        </div>
                    </div>

                    <div>
                        <h4 class="text-sm font-bold text-slate-500 uppercase tracking-wider mb-4">Pasif Hesaplar</h4>
                        <div id="passive-accounts-list" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                            <!-- Passive accounts will be injected here -->
                        </div>
                    </div>
                </div>
            </section>

            <!-- Calendar Section -->
            <section id="section-calendar" class="space-y-6">
                <div class="flex justify-between items-center">
                    <div class="flex items-center space-x-4">
                        <button onclick="changeMonth(-1)" class="p-2 hover:bg-slate-800 rounded-lg transition-colors">
                            <i data-lucide="chevron-left" class="w-5 h-5 text-slate-400"></i>
                        </button>
                        <h3 id="calendar-month-year" class="text-2xl font-bold text-slate-100 min-w-[150px] text-center">Mart 2026</h3>
                        <button onclick="changeMonth(1)" class="p-2 hover:bg-slate-800 rounded-lg transition-colors">
                            <i data-lucide="chevron-right" class="w-5 h-5 text-slate-400"></i>
                        </button>
                    </div>
                    <button onclick="openTradeModal()" class="bg-sky-600 text-white px-6 py-2.5 rounded-xl font-bold hover:bg-sky-700 transition-all flex items-center space-x-2 shadow-lg shadow-sky-900/20">
                        <i data-lucide="plus" class="w-5 h-5"></i>
                        <span>Yeni İşlem</span>
                    </button>
                </div>

                <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
                    <div class="lg:col-span-3 bg-slate-900 rounded-3xl border border-slate-800 overflow-hidden shadow-sm">
                        <div class="calendar-grid bg-slate-800/50 border-b border-slate-800">
                            <div class="py-3 text-center text-xs font-bold text-slate-500 uppercase tracking-widest">Pzt</div>
                            <div class="py-3 text-center text-xs font-bold text-slate-500 uppercase tracking-widest">Sal</div>
                            <div class="py-3 text-center text-xs font-bold text-slate-500 uppercase tracking-widest">Çar</div>
                            <div class="py-3 text-center text-xs font-bold text-slate-500 uppercase tracking-widest">Per</div>
                            <div class="py-3 text-center text-xs font-bold text-slate-500 uppercase tracking-widest">Cum</div>
                            <div class="py-3 text-center text-xs font-bold text-slate-500 uppercase tracking-widest text-sky-500/70">Cmt</div>
                            <div class="py-3 text-center text-xs font-bold text-slate-500 uppercase tracking-widest text-sky-500/70">Paz</div>
                        </div>
                        <div id="calendar-days" class="calendar-grid divide-x divide-y divide-slate-800">
                            <!-- Days will be injected here -->
                        </div>
                    </div>

                    <!-- Weekly Stats Column -->
                    <div class="space-y-4">
                        <div class="bg-slate-900 p-6 rounded-3xl border border-slate-800 shadow-sm">
                            <h4 class="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4">Hafta</h4>
                            <div id="weekly-stats-container" class="space-y-4">
                                <!-- Weekly stats will be injected here -->
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Monthly Trade History -->
                <div class="bg-slate-900 p-8 rounded-3xl border border-slate-800 shadow-sm">
                    <div class="flex justify-between items-center mb-6">
                        <h4 class="text-lg font-bold text-slate-100">Aylık İşlem Geçmişi</h4>
                        <div id="monthly-stats" class="text-sm font-semibold text-slate-400"></div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="w-full text-left">
                            <thead>
                                <tr class="text-slate-500 text-sm border-b border-slate-800">
                                    <th class="pb-4 font-semibold">Tarih</th>
                                    <th class="pb-4 font-semibold">Parite</th>
                                    <th class="pb-4 font-semibold">İşlem (Long/short)</th>
                                    <th class="pb-4 font-semibold">PnL</th>
                                    <th class="pb-4 font-semibold">İşlem</th>
                                </tr>
                            </thead>
                            <tbody id="monthly-trades-body" class="divide-y divide-slate-800">
                                <!-- Monthly trades will be injected here -->
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- History Section -->
            <section id="section-history" class="hidden space-y-6">
                <div class="flex justify-between items-center">
                    <h3 class="text-2xl font-bold text-slate-100">İşlemler</h3>
                    <div class="flex space-x-2">
                        <button onclick="exportTrades()" class="bg-slate-800 text-slate-300 px-4 py-2 rounded-xl font-semibold hover:bg-slate-700 transition-all flex items-center space-x-2">
                            <i data-lucide="download" class="w-4 h-4"></i>
                            <span>Dışa Aktar</span>
                        </button>
                    </div>
                </div>

                <div id="detailed-history-container" class="space-y-8">
                    <!-- Detailed history grouped by month will be injected here -->
                </div>
            </section>

            <!-- Analysis Section -->
            <section id="section-analysis" class="hidden space-y-8">
                <!-- Summary Cards -->
                <div class="grid grid-cols-2 md:grid-cols-5 gap-4 md:gap-6">
                    <div class="bg-slate-900 p-4 md:p-6 rounded-3xl border border-slate-800 shadow-sm">
                        <p class="text-xs md:text-sm font-medium text-slate-500 mb-1">Anlık Bütçe</p>
                        <p id="stat-current-budget" class="text-xl md:text-3xl font-bold text-slate-100">$0</p>
                    </div>
                    <div class="bg-slate-900 p-4 md:p-6 rounded-3xl border border-slate-800 shadow-sm">
                        <p class="text-xs md:text-sm font-medium text-slate-500 mb-1">Toplam PnL</p>
                        <p id="stat-total-pnl" class="text-xl md:text-3xl font-bold text-slate-100">$0</p>
                    </div>
                    <div class="bg-slate-900 p-4 md:p-6 rounded-3xl border border-slate-800 shadow-sm">
                        <p class="text-xs md:text-sm font-medium text-slate-500 mb-1">Win Rate</p>
                        <p id="stat-win-rate" class="text-xl md:text-3xl font-bold text-sky-500">0%</p>
                    </div>
                    <div class="bg-slate-900 p-4 md:p-6 rounded-3xl border border-slate-800 shadow-sm">
                        <p class="text-xs md:text-sm font-medium text-slate-500 mb-1">Profit Factor</p>
                        <p id="stat-profit-factor" class="text-xl md:text-3xl font-bold text-slate-100">0.00</p>
                    </div>
                    <div class="bg-slate-900 p-4 md:p-6 rounded-3xl border border-slate-800 shadow-sm col-span-2 md:col-span-1">
                        <p class="text-xs md:text-sm font-medium text-slate-500 mb-1">Expectancy</p>
                        <p id="stat-expectancy" class="text-xl md:text-3xl font-bold text-slate-100">$0.00</p>
                    </div>
                </div>

                <!-- Charts Row 1 -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 space-y-2 md:space-y-0">
                            <h4 class="text-lg font-bold text-slate-100">Equity Curve (Sermaye Eğrisi)</h4>
                            <span id="report-drawdown" class="text-xs font-bold text-rose-500 bg-rose-500/10 px-2 py-1 rounded-lg">Max DD: 0%</span>
                        </div>
                        <div id="equity-chart" class="w-full h-64 bg-slate-950/50 rounded-2xl overflow-hidden"></div>
                    </div>
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">P&L Dağılımı (Sembol Bazlı)</h4>
                        <div id="symbol-chart" class="w-full h-64 bg-slate-950/50 rounded-2xl overflow-hidden"></div>
                    </div>
                </div>

                <!-- Charts Row 2 -->
                <div class="grid grid-cols-1 gap-8">
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Günlere Göre Performans</h4>
                        <div id="day-chart" class="w-full h-64 bg-slate-950/50 rounded-2xl overflow-hidden"></div>
                    </div>
                </div>

                <!-- Hourly Performance & Daily Win Rate -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <!-- Hourly Performance -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Saatlik Verimliliği</h4>
                        <div id="hourly-performance-table" class="overflow-x-auto">
                            <table class="w-full text-sm">
                                <thead>
                                    <tr class="text-slate-500 border-b border-slate-800">
                                        <th class="pb-3 text-left font-semibold min-w-[80px]">Saat</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">İşlem</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">WR %</th>
                                        <th class="pb-3 text-right font-semibold min-w-[80px]">PnL</th>
                                    </tr>
                                </thead>
                                <tbody id="hourly-perf-body" class="divide-y divide-slate-800">
                                    <!-- Hourly data injected here -->
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Daily Win Rate -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Günlük Win Rate</h4>
                        <div id="daily-winrate-table" class="overflow-x-auto">
                            <table class="w-full text-sm">
                                <thead>
                                    <tr class="text-slate-500 border-b border-slate-800">
                                        <th class="pb-3 text-left font-semibold min-w-[80px]">Gün</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">İşlem</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">WR %</th>
                                        <th class="pb-3 text-right font-semibold min-w-[80px]">PnL</th>
                                    </tr>
                                </thead>
                                <tbody id="daily-wr-body" class="divide-y divide-slate-800">
                                    <!-- Daily WR data injected here -->
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Setup Performance & Bias Accuracy -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <!-- Setup Performance -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Setup Performansı</h4>
                        <div id="setup-performance-table" class="overflow-x-auto">
                            <table class="w-full text-sm">
                                <thead>
                                    <tr class="text-slate-500 border-b border-slate-800">
                                        <th class="pb-3 text-left font-semibold min-w-[100px]">Setup</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">İşlem</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">WR %</th>
                                        <th class="pb-3 text-right font-semibold min-w-[80px]">Ort RR</th>
                                    </tr>
                                </thead>
                                <tbody id="setup-perf-body" class="divide-y divide-slate-800">
                                    <!-- Setup data injected here -->
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Bias Accuracy -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Bias M15 Doğruluğu</h4>
                        <div id="bias-accuracy-table" class="overflow-x-auto">
                            <table class="w-full text-sm">
                                <thead>
                                    <tr class="text-slate-500 border-b border-slate-800">
                                        <th class="pb-3 text-left font-semibold min-w-[80px]">Bias</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">İşlem</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">WR %</th>
                                        <th class="pb-3 text-right font-semibold min-w-[80px]">PnL</th>
                                    </tr>
                                </thead>
                                <tbody id="bias-acc-body" class="divide-y divide-slate-800">
                                    <!-- Bias accuracy data injected here -->
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Session Analysis & Heatmap -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <!-- Session Performance -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Seans Performansı (TR Saati)</h4>
                        <div id="session-performance-table" class="overflow-x-auto">
                            <table class="w-full text-sm">
                                <thead>
                                    <tr class="text-slate-500 border-b border-slate-800">
                                        <th class="pb-3 text-left font-semibold min-w-[120px]">Seans</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">İşlem</th>
                                        <th class="pb-3 text-center font-semibold min-w-[60px]">WR %</th>
                                        <th class="pb-3 text-right font-semibold min-w-[80px]">PnL</th>
                                    </tr>
                                </thead>
                                <tbody id="session-perf-body" class="divide-y divide-slate-800">
                                    <!-- Session data injected here -->
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Heatmap -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Isı Haritası (Gün × Saat)</h4>
                        <div id="heatmap-container" class="overflow-x-auto min-h-[300px]">
                            <!-- Heatmap grid injected here -->
                        </div>
                    </div>
                </div>

                <!-- Charts Row 3 -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">RR Dağılımı (Histogram)</h4>
                        <div id="rr-distribution-chart" class="w-full h-64 bg-slate-950/50 rounded-2xl overflow-hidden"></div>
                    </div>
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Killzone/Seans Analizi (Win Rate)</h4>
                        <div id="killzone-winrate-chart" class="w-full h-64 bg-slate-950/50 rounded-2xl overflow-hidden"></div>
                    </div>
                </div>

                <!-- Detailed Analysis Report -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    <!-- Periodical & Risk Performance -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm space-y-6">
                        <h4 class="text-lg font-bold text-slate-100 border-b border-slate-800 pb-4">Risk & Verimlilik</h4>
                        <div class="space-y-4">
                            <div class="flex justify-between items-center">
                                <span class="text-slate-400 text-sm md:text-base">Günlük P&L</span>
                                <span id="report-daily-pnl" class="font-bold text-sm md:text-base">$0</span>
                            </div>
                            <div class="flex justify-between items-center">
                                <span class="text-slate-400 text-sm md:text-base">Haftalık P&L</span>
                                <span id="report-weekly-pnl" class="font-bold text-sm md:text-base">$0</span>
                            </div>
                            <div class="flex justify-between items-center">
                                <span class="text-slate-400 text-sm md:text-base">Aylık P&L</span>
                                <span id="report-monthly-pnl" class="font-bold text-sm md:text-base">$0</span>
                            </div>
                            <div class="pt-4 border-t border-slate-800 space-y-4">
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400 text-sm md:text-base">Ort. Kazanç / Kayıp (R:R)</span>
                                    <span id="report-rr-ratio" class="font-bold text-sky-500 text-sm md:text-base">0.00</span>
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400 text-sm md:text-base">Expectancy (Beklenti)</span>
                                    <span id="stat-expectancy-report" class="font-bold text-slate-100 text-sm md:text-base">$0</span>
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400 text-sm md:text-base">Max Win Streak</span>
                                    <span id="report-win-streak" class="font-bold text-emerald-500 text-sm md:text-base">0</span>
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400 text-sm md:text-base">Max Loss Streak</span>
                                    <span id="report-loss-streak" class="font-bold text-rose-500 text-sm md:text-base">0</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Best/Worst Pairs -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm space-y-6">
                        <h4 class="text-lg font-bold text-slate-100 border-b border-slate-800 pb-4">Sembol Analizi</h4>
                        <div class="space-y-6">
                            <div>
                                <p class="text-xs font-bold text-slate-500 uppercase mb-2">En Başarılı Pariteler</p>
                                <div id="report-best-pairs" class="space-y-2">
                                    <!-- Best pairs injected here -->
                                </div>
                            </div>
                            <div>
                                <p class="text-xs font-bold text-slate-500 uppercase mb-2">En Başarısız Pariteler</p>
                                <div id="report-worst-pairs" class="space-y-2">
                                    <!-- Worst pairs injected here -->
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Trading Insights & Plan -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm space-y-6">
                        <h4 class="text-lg font-bold text-slate-100 border-b border-slate-800 pb-4">Yol Planı & Öngörüler</h4>
                        <div id="report-insights" class="space-y-4 text-sm text-slate-400 leading-relaxed">
                            <!-- Insights injected here -->
                        </div>
                    </div>
                </div>
            </section>

            <!-- Balance Section -->
            <section id="section-balance" class="hidden space-y-8">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="bg-slate-900 p-6 rounded-3xl border border-slate-800 shadow-sm">
                        <p class="text-sm font-medium text-slate-500 mb-1">Anlık Bakiye</p>
                        <p id="balance-current" class="text-3xl font-bold text-slate-100">$0</p>
                    </div>
                    <div class="bg-slate-900 p-6 rounded-3xl border border-slate-800 shadow-sm">
                        <p class="text-sm font-medium text-slate-500 mb-1">Toplam Yatırılan</p>
                        <p id="balance-total-deposit" class="text-3xl font-bold text-emerald-400">$0</p>
                    </div>
                    <div class="bg-slate-900 p-6 rounded-3xl border border-slate-800 shadow-sm">
                        <p class="text-sm font-medium text-slate-500 mb-1">Toplam Çekilen</p>
                        <p id="balance-total-withdraw" class="text-3xl font-bold text-rose-400">$0</p>
                    </div>
                </div>

                <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                    <h4 class="text-lg font-bold text-slate-100 mb-6">2026 Yılı Bakiye / Aylık</h4>
                    <div id="balance-chart" class="w-full h-80 bg-slate-950/50 rounded-2xl overflow-hidden"></div>
                </div>

                <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                    <h4 class="text-lg font-bold text-slate-100 mb-6">İşlem Geçmişi (Yatırma/Çekme)</h4>
                    <div class="overflow-x-auto">
                        <table class="w-full text-left min-w-[400px]">
                            <thead>
                                <tr class="text-slate-500 text-sm border-b border-slate-800">
                                    <th class="pb-4 font-semibold">Tarih</th>
                                    <th class="pb-4 font-semibold">İşlem Tipi</th>
                                    <th class="pb-4 font-semibold text-right">Miktar</th>
                                </tr>
                            </thead>
                            <tbody id="balance-history-body" class="divide-y divide-slate-800">
                                <!-- Balance history will be injected here -->
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- Notes Section -->
            <section id="section-notes" class="hidden space-y-6">
                <div class="flex justify-between items-center">
                    <h3 class="text-2xl font-bold text-slate-100">Strateji Notları</h3>
                    <button onclick="openNoteModal()" class="bg-sky-600 text-white px-4 md:px-6 py-2 md:py-2.5 rounded-xl font-bold hover:bg-sky-700 transition-all flex items-center space-x-2 shadow-lg shadow-sky-900/20 text-sm md:text-base">
                        <i data-lucide="plus" class="w-5 h-5"></i>
                        <span class="hidden md:inline">Not Ekle</span>
                    </button>
                </div>
                <div id="notes-container" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    <!-- Notes will be injected here -->
                </div>
            </section>

            <!-- Settings Section -->
            <section id="section-settings" class="hidden space-y-8">
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <!-- Setup Management -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Setup Yönetimi</h4>
                        <div class="space-y-4">
                            <div class="flex space-x-2">
                                <input type="text" id="new-entry-type" placeholder="Yeni Setup..." class="flex-grow px-4 py-3 rounded-xl bg-slate-800 border border-slate-700 text-slate-100 focus:ring-2 focus:ring-sky-500 outline-none transition-all">
                                <button onclick="addEntryType()" class="bg-sky-600 text-white px-4 py-3 rounded-xl font-bold hover:bg-sky-700 transition-all shrink-0">
                                    <i data-lucide="plus" class="w-5 h-5"></i>
                                </button>
                            </div>
                            <div id="entry-types-list" class="space-y-2 max-h-64 overflow-y-auto pr-2 scrollbar-hide">
                                <!-- Entry types will be injected here -->
                            </div>
                        </div>
                    </div>

                    <!-- Balance Management -->
                    <div class="bg-slate-900 p-4 md:p-8 rounded-3xl border border-slate-800 shadow-sm">
                        <h4 class="text-lg font-bold text-slate-100 mb-6">Bakiye Yönetimi</h4>
                        <div class="space-y-6">
                            <div>
                                <label class="block text-sm font-semibold text-slate-400 mb-2">Başlangıç Bakiyesi ($)</label>
                                <input type="number" id="initial-balance-input" step="0.01" placeholder="0.00" class="w-full px-4 py-3 rounded-xl bg-slate-800 border border-slate-700 text-slate-100 focus:ring-2 focus:ring-sky-500 outline-none transition-all mb-4">
                                <button id="save-balance-btn" onclick="saveInitialBalance()" class="w-full bg-sky-600 text-white px-8 py-3 rounded-xl font-bold hover:bg-sky-700 transition-all">
                                    Bakiyeyi Gir
                                </button>
                            </div>
                            <div class="pt-4 border-t border-slate-800">
                                <label class="block text-sm font-semibold text-slate-400 mb-2">Miktar ($)</label>
                                <input type="number" id="transaction-amount-input" step="0.01" placeholder="0.00" class="w-full px-4 py-3 rounded-xl bg-slate-800 border border-slate-700 text-slate-100 focus:ring-2 focus:ring-sky-500 outline-none transition-all mb-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <button onclick="executeTransaction('deposit')" class="bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 px-4 md:px-6 py-3 rounded-xl font-bold hover:bg-emerald-600/30 transition-all flex items-center justify-center space-x-1 md:space-x-2 text-sm md:text-base">
                                        <i data-lucide="arrow-down-left" class="w-4 h-4 md:w-5 md:h-5"></i>
                                        <span>Para Yatır</span>
                                    </button>
                                    <button onclick="executeTransaction('withdraw')" class="bg-rose-600/20 text-rose-400 border border-rose-500/30 px-4 md:px-6 py-3 rounded-xl font-bold hover:bg-rose-600/30 transition-all flex items-center justify-center space-x-1 md:space-x-2 text-sm md:text-base">
                                        <i data-lucide="arrow-up-right" class="w-4 h-4 md:w-5 md:h-5"></i>
                                        <span>Para Çek</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

        </div>
    </main>

    <!-- ... Diğer Modallar ... -->
"""
# Need to append the rest of the file so I will just extract parts properly instead of doing it this way.
