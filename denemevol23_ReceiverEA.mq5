//+------------------------------------------------------------------+
//|                                     denemevol23_ReceiverEA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

input double InpFixedRiskUSD = 50.0;    // İşlem Başına Sabit Risk (USD)
input ulong  InpMagicNumber  = 454545;  // Magic Number (İzole İşlem İçin)
input double InpDefaultLot   = 0.01;    // Test veya Hata Durumu İçin Sabit Lot

int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   EventSetTimer(1); // Her saniye sinyal dosyasını kontrol et
   Print("🟢 EA Başlatıldı. Sinyaller Bekleniyor...");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   Print("🔴 EA Kapatıldı.");
  }

void OnTimer()
  {
   string filename = "denemevol23_signal_" + Symbol() + ".txt";

   // 1. Sinyal dosyası ortak klasörde (FILE_COMMON) var mı kontrol et
   if (FileIsExist(filename, FILE_COMMON)) {
       int handle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_COMMON);
       if (handle != INVALID_HANDLE) {
           string data = FileReadString(handle);
           FileClose(handle);

           // 2. Sinyal dosyasını işledikten HEMEN SONRA SİL (Tekrar işleme girmesini engellemek için)
           FileDelete(filename, FILE_COMMON);

           Print("🔔 Yeni Sinyal Alındı: ", data);

           // 3. Veriyi Parçala (Sembol, Yön, Giriş Fiyatı, SL Mesafesi, TP Mesafesi)
           string args[];
           StringSplit(data, ',', args);

           if(ArraySize(args) == 5) {
               string sym = args[0];
               string dir_str = args[1];
               double entry_price = StringToDouble(args[2]);
               double sl_dist_raw = StringToDouble(args[3]);
               double tp_dist_raw = StringToDouble(args[4]);

               double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
               double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

               double sl_price = 0, tp_price = 0;
               int dir = 0;
               double volume = InpDefaultLot;

               // Eğer test değilse riske göre dinamik lot hesapla
               if(dir_str == "BUY" || dir_str == "SELL") {
                  double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
                  double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
                  if (sl_dist_raw > 0 && tick_size > 0 && tick_value > 0) {
                      double risk_ticks = sl_dist_raw / tick_size;
                      double required_lot = InpFixedRiskUSD / (risk_ticks * tick_value);

                      double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
                      double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
                      double step_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

                      volume = MathRound(required_lot / step_lot) * step_lot;
                      if(volume < min_lot) volume = min_lot;
                      if(volume > max_lot) volume = max_lot;
                  }
               }

               if(dir_str == "BUY" || dir_str == "TEST_BUY") {
                   sl_price = ask - sl_dist_raw;
                   tp_price = ask + tp_dist_raw;
                   Print("🚀 Alış (BUY) İşlemi Açılıyor... Lot: ", volume);
                   trade.Buy(volume, Symbol(), ask, sl_price, tp_price, "5Parite Signal");
               }
               else if(dir_str == "SELL" || dir_str == "TEST_SELL") {
                   sl_price = bid + sl_dist_raw;
                   tp_price = bid - tp_dist_raw;
                   Print("📉 Satış (SELL) İşlemi Açılıyor... Lot: ", volume);
                   trade.Sell(volume, Symbol(), bid, sl_price, tp_price, "5Parite Signal");
               }
           } else {
               Print("❌ Hata: Geçersiz Sinyal Formatı!");
           }
       }
   }
  }
//+------------------------------------------------------------------+
