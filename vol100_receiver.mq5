//+------------------------------------------------------------------+
//|                                             vol100_receiver.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

input double InpRiskUSD = 20.0; // İşlem Başına Riske Atılacak Tutar ($)
input string InpSignalSymbol = ""; // Sinyal Dosyasındaki Sembol Adı (Örn: XAUUSD) Boşsa Grafiği Kullanır
input int InpPollDelayMs = 500; // Dosya Okuma Gecikmesi (Milisaniye)

CTrade trade;

//+------------------------------------------------------------------+
//| Ayni sembolde acik pozisyon var mi kontrol et                    |
//+------------------------------------------------------------------+
bool HasOpenPosition(string target_symbol)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         string pos_sym = PositionGetString(POSITION_SYMBOL);
         if(pos_sym == target_symbol)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Get Base Symbol (Strips broker suffixes like 'r', '.m', '_c')    |
//+------------------------------------------------------------------+
string GetBaseSymbol(string full_symbol)
  {
   // Genellikle Forex ve Altın (Metaller) 6 karakterdir (Örn: EURUSD, XAUUSD)
   // Eğer sembol 6 karakterden uzunsa (Örn: XAUUSDr, EURUSD.m), sadece ilk 6 karakteri al.
   if (StringLen(full_symbol) > 6) {
       return StringSubstr(full_symbol, 0, 6);
   }
   return full_symbol;
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetMillisecondTimer(InpPollDelayMs);
   Print("🟢 [VOL100 RECEIVER] Başlatıldı. Ortak klasör dinleniyor... Risk: $", InpRiskUSD);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   Print("🔴 [VOL100 RECEIVER] Kapatıldı.");
  }

//+------------------------------------------------------------------+
//| Timer function (Dosya Taraması)                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   string base_sym = GetBaseSymbol(Symbol()); // Otomatik 'XAUUSDr' -> 'XAUUSD' çevirici
   string listen_sym = (InpSignalSymbol != "") ? InpSignalSymbol : base_sym;
   string filename = "vol100_signal_" + listen_sym + ".txt";

   // Eğer dosya yoksa direkt çık
   if (!FileIsExist(filename, FILE_COMMON)) return;

   int handle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_COMMON);
   if(handle == INVALID_HANDLE)
     {
      Print("⚠️ [VOL100 RECEIVER] Dosya okunamadı! Hata Kodu: ", GetLastError());
      return;
     }

   string signal_data = FileReadString(handle);
   FileClose(handle);

   // Dosyayı okuduktan hemen sonra sil (Aynı işlemi tekrar açmamak için)
   if (!FileDelete(filename, FILE_COMMON)) {
       Print("🚨 [VOL100 RECEIVER] DİKKAT: Sinyal dosyası silinemedi! Hata: ", GetLastError());
       return; // Silinemezse isleme girmeyelim, yoksa sonsuz islem acar
   }

   // Format: SYMBOL,DIR,ENTRY,SL,TP
   // Örn: EURUSD,BUY,1.08500,1.08400,1.08800
   string parts[];
   int count = StringSplit(signal_data, ',', parts);

   if (count != 5) {
       Print("❌ [VOL100 RECEIVER] Sinyal formatı hatalı: ", signal_data);
       return;
   }

   string sym = parts[0];
   string dir = parts[1];
   double entry_p = StringToDouble(parts[2]);
   double sl_p = StringToDouble(parts[3]);
   double tp_p = StringToDouble(parts[4]);

   // Sinyalin ait olduğu sembol kontrolü
   // Eğer özel bir sinyal sembolü tanımladıysak, dosyanın o isme ait olduğunu doğrula.
   if (sym != listen_sym) {
       Print("⚠️ [VOL100 RECEIVER] Yanlış Sembol! Gelen Sinyal: ", sym, " Beklenen Sinyal: ", listen_sym);
       return;
   }

   // --- AÇIK POZİSYON (CONCURRENT TRADE) KONTROLÜ ---
   if (HasOpenPosition(Symbol())) {
       Print("⚠️ [VOL100 RECEIVER] Hali hazırda açık bir ", Symbol(), " işlemi bulunuyor. Yeni sinyal reddedildi (Sinyal dosyası silindi).");
       return;
   }

   // --- RİSK & LOT HESAPLAMASI (20$ SABİT RİSK) ---
   // İşlemi HER ZAMAN grafiğin kendi orijinal sembolü üzerinden açacağız (Örn: XAUUSDr)
   double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE); // 1 lot için 1 tick/puan değeri ($)
   double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);

   if (tick_value <= 0 || tick_size <= 0) {
       Print("❌ [VOL100 RECEIVER] Sembol tick değeri okunamadı: ", Symbol());
       return;
   }

   // SL mesafesini puan (point/tick) cinsinden bul
   double distance_in_price = MathAbs(entry_p - sl_p);
   double ticks_to_sl = distance_in_price / tick_size;

   if (ticks_to_sl <= 0) {
       Print("❌ [VOL100 RECEIVER] SL mesafesi çok küçük veya 0!");
       return;
   }

   // 1 Lot açsaydık SL olunca kaç dolar kaybederdik?
   double loss_per_lot = ticks_to_sl * tick_value;

   // 20$ kaybetmek için kaç lot açmalıyız?
   double calculated_lot = InpRiskUSD / loss_per_lot;

   // Lot Miktarını Limitle (Örn: En az 0.01, Step 0.01)
   double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double step_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   double final_lot = MathRound(calculated_lot / step_lot) * step_lot;

   if (final_lot < min_lot) final_lot = min_lot;
   if (final_lot > max_lot) final_lot = max_lot;

   // --- İŞLEME GİR ---
   if (dir == "BUY") {
       double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
       if (trade.Buy(final_lot, Symbol(), ask, sl_p, tp_p, "VOL100 Auto-Trade")) {
           Print("✅ [VOL100 RECEIVER] BUY İşlemi Açıldı (", Symbol(), ")! Lot: ", final_lot, " SL: ", sl_p, " TP: ", tp_p, " (Risk: $", InpRiskUSD, ")");
       } else {
           Print("❌ [VOL100 RECEIVER] BUY İşlemi BAŞARISIZ! Sembol: ", Symbol(), " Hata Kodu: ", trade.ResultRetcode());
       }
   }
   else if (dir == "SELL") {
       double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
       if (trade.Sell(final_lot, Symbol(), bid, sl_p, tp_p, "VOL100 Auto-Trade")) {
           Print("✅ [VOL100 RECEIVER] SELL İşlemi Açıldı (", Symbol(), ")! Lot: ", final_lot, " SL: ", sl_p, " TP: ", tp_p, " (Risk: $", InpRiskUSD, ")");
       } else {
           Print("❌ [VOL100 RECEIVER] SELL İşlemi BAŞARISIZ! Sembol: ", Symbol(), " Hata Kodu: ", trade.ResultRetcode());
       }
   }
  }
//+------------------------------------------------------------------+
