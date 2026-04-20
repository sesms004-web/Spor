//+------------------------------------------------------------------+
//|                                                      SlaveEA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

input group "--- SLAVE EA SETTINGS ---"
input int    InpMagicNumber  = 454545;
input int    InpMaxSlippage  = 10;
input double InpMaxLotSize   = 0.50; // Kasa Koruyucu: Maksimum Lot Sınırı (Pariteye Özel)
input string InpSymbolSuffix = "r";  // Master ile Slave arasındaki sembol farkı (Örn: r, .pro)

void OnInit() {
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpMaxSlippage);
    EventSetTimer(1); // 1 saniyede bir klasörü kontrol et
    Print("Slave EA Başlatıldı. Sinyaller Bekleniyor...");
}

void OnDeinit(const int reason) {
    EventKillTimer();
}

void OnTimer() {
    // Slave EA kendi sembolünün sonundan suffixi çıkarıp ana sembolü (Örn: XAUUSD) bulur
    string base_symbol = Symbol();
    int suffix_len = StringLen(InpSymbolSuffix);
    if(suffix_len > 0) {
        if(StringSubstr(base_symbol, StringLen(base_symbol) - suffix_len, suffix_len) == InpSymbolSuffix) {
            base_symbol = StringSubstr(base_symbol, 0, StringLen(base_symbol) - suffix_len);
        }
    }

    string filename = "SMC_SIGNAL_" + base_symbol + ".json";

    // Dosya var mı kontrol et
    if (FileIsExist(filename, FILE_COMMON)) {
        int handle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_COMMON);
        if (handle != INVALID_HANDLE) {
            string json = "";
            while(!FileIsEnding(handle)) {
                json += FileReadString(handle) + "\n";
            }
            FileClose(handle);

            // Okuduktan sonra dosyayı hemen sil ki tekrar tekrar girmesin
            FileDelete(filename, FILE_COMMON);

            ProcessSignal(json, base_symbol);
        }
    }
}

// Basit JSON parser (Sadece gerekli verileri çeker)
string GetJSONValue(string json, string key) {
    int start = StringFind(json, "\"" + key + "\":");
    if (start == -1) return "";

    start += StringLen(key) + 3; // atla: "key":

    // Boşlukları atla
    while(start < StringLen(json) && (StringSubstr(json, start, 1) == " " || StringSubstr(json, start, 1) == "	")) {
        start++;
    }

    int end = -1;

    // Eğer string ise
    if (StringSubstr(json, start, 1) == "\"") {
        start++;
        end = StringFind(json, "\"", start);
    } else {
        // Rakam ise virgüle veya yeni satıra kadar
        end = StringFind(json, ",", start);
        if (end == -1) end = StringFind(json, "\n", start);
        if (end == -1) end = StringFind(json, "}", start);
    }

    if (end == -1) return "";

    string val = StringSubstr(json, start, end - start);
    StringReplace(val, " ", ""); // Boşlukları temizle
    StringReplace(val, "\"", ""); // Çift tırnak kalıntısı varsa temizle
    return val;
}

void ProcessSignal(string json, string expected_base_symbol) {
    string sym = GetJSONValue(json, "symbol");
    if (sym != expected_base_symbol) return; // Başka pariteyse es geç

    string dir = GetJSONValue(json, "direction");
    double m_entry = StringToDouble(GetJSONValue(json, "entry"));
    double m_sl = StringToDouble(GetJSONValue(json, "sl"));
    double m_tp = StringToDouble(GetJSONValue(json, "tp"));
    double risk_usd = StringToDouble(GetJSONValue(json, "risk_usd"));


    if (dir == "" || m_sl == 0) {
        Print("Geçersiz Sinyal Dosyası: Eksik Veri.");
        return;
    }

    // Puan/Mesafe olarak SL ve TP'yi hesapla (Master'ın orjinal mesafesi)
    double sl_dist = MathAbs(m_entry - m_sl);
    double tp_dist = MathAbs(m_entry - m_tp);

    if (sl_dist == 0) {
        Print("Geçersiz Sinyal: SL Mesafesi 0 olamaz.");
        return;
    }

    double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);

    if (tick_value == 0 || tick_size == 0) return;

    // İşleme girerken canlı fiyatı alıyoruz (Slippage umrumuzda değil)
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    double live_entry = (dir == "BUY") ? ask : bid;

    // SL ve TP noktalarını canlı giriş fiyatımıza + master mesafesine göre hesaplıyoruz
    double live_sl = (dir == "BUY") ? (live_entry - sl_dist) : (live_entry + sl_dist);
    double live_tp = (dir == "BUY") ? (live_entry + tp_dist) : (live_entry - tp_dist);

    // Lot hesaplama (RiskUSD / (SL Puanı * TickValue))
    double sl_ticks = sl_dist / tick_size;
    double calc_lot = risk_usd / (sl_ticks * tick_value);

    // Lot sınırlandırmaları
    double min_vol = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_vol = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double step_vol = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

    if (calc_lot < min_vol) calc_lot = min_vol;
    if (calc_lot > InpMaxLotSize) calc_lot = InpMaxLotSize;
    if (calc_lot > max_vol) calc_lot = max_vol;

    calc_lot = MathRound(calc_lot / step_vol) * step_vol;



    Print("--- SİNYAL ALINDI ---");
    Print("Yön: ", dir, " | Risk: $", risk_usd, " | Hesaplan Lot: ", calc_lot);
    Print("Mesafe -> SL Dist: ", sl_dist, " | TP Dist: ", tp_dist);

    // İşlemi Gönder
    if (dir == "BUY") {
        if(trade.Buy(calc_lot, Symbol(), live_entry, live_sl, live_tp, "SMC Slave")) {
            Print("✅ BUY İşlemi Başarılı!");
        } else {
            Print("❌ BUY İşlemi BAŞARISIZ! Hata: ", GetLastError());
        }
    }
    else if (dir == "SELL") {
        if(trade.Sell(calc_lot, Symbol(), live_entry, live_sl, live_tp, "SMC Slave")) {
            Print("✅ SELL İşlemi Başarılı!");
        } else {
            Print("❌ SELL İşlemi BAŞARISIZ! Hata: ", GetLastError());
        }
    }
}
