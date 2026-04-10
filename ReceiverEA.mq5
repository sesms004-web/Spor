//+------------------------------------------------------------------+
//|                                                 ReceiverEA.mq5   |
//|                                     5parite Sinyal Alıcı EA      |
//+------------------------------------------------------------------+
#property copyright "Jules"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>

input double InpRiskAmountUSD = 20.0;    // İşlem Başına Risk (USD)
input double InpMaxLotSize    = 10.0;    // Maksimum Lot Sınırı
input double InpMinLotSize    = 0.01;    // Minimum Lot Sınırı

CTrade trade;
string base_symbol = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Aracı kurum eklerini temizle (Örn: XAUUSDr -> XAUUSD)
   base_symbol = StringSubstr(Symbol(), 0, 6);

   // Her 1 saniyede bir klasörü kontrol et
   EventSetTimer(1);

   trade.SetExpertMagicNumber(454545);

   Print("📡 [ReceiverEA] Başlatıldı. Beklenen sinyal dosyası: vol100_signal_", base_symbol, ".txt");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   string filename = "vol100_signal_" + base_symbol + ".txt";

   // Dosya yoksa çık
   if(!FileIsExist(filename, FILE_COMMON)) return;

   // Dosya varsa oku
   int handle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_COMMON);
   if(handle == INVALID_HANDLE)
     {
      Print("❌ Sinyal dosyası açılamadı! Hata: ", GetLastError());
      return;
     }

   string line = FileReadString(handle);
   FileClose(handle);

   // Okuduktan hemen sonra sil (Aynı işlemi tekrar açmamak için)
   FileDelete(filename, FILE_COMMON);

   if(line == "") return;

   // Gelen Format: XAUUSD,BUY,2350.50,5.91,17.73
   string parts[];
   int count = StringSplit(line, ',', parts);

   if(count < 5)
     {
      Print("❌ Hatalı sinyal formatı: ", line);
      return;
     }

   string sig_sym  = parts[0];
   string sig_dir  = parts[1];
   double sig_ent  = StringToDouble(parts[2]);
   double sl_dist_raw = StringToDouble(parts[3]);
   double tp_dist_raw = StringToDouble(parts[4]);

   Print("📥 [YENİ SİNYAL] Yön: ", sig_dir, " | SL Net Mesafe: ", sl_dist_raw, " | TP Net Mesafe: ", tp_dist_raw);

   // Test işlemi değilse: SADECE BİZİM BOTA AİT (Magic Number) açık işlem var mı kontrol et.
   bool is_test_signal = (sig_dir == "TEST_BUY" || sig_dir == "TEST_SELL");

   if(PositionsTotal() > 0 && !is_test_signal)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         string pos_sym = PositionGetSymbol(i);
         if(pos_sym == Symbol())
           {
            long pos_magic = PositionGetInteger(POSITION_MAGIC);
            if(pos_magic == 454545) // Sadece bizim sihirli numaramız
              {
               Print("⚠️ Bizim botun " + Symbol() + " üzerinde zaten açık bir işlemi var. Yeni sinyal reddedildi.");
               return;
              }
           }
        }
     }

   // Lot hesaplama (Risk bazlı)
   double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tick_size  = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double point      = SymbolInfoDouble(Symbol(), SYMBOL_POINT);

   if(tick_size == 0 || point == 0) return;

   // EA tarafında kendi puan değerini (point) bulup net fiyat mesafesini puana çevirelim (Lot hesabı için)
   double ea_sl_pts = sl_dist_raw / point;

   // 1 lot için puan başına zarar
   double loss_per_point_1_lot = tick_value / (tick_size / point);
   double total_loss_1_lot = ea_sl_pts * loss_per_point_1_lot;

   double lot = InpMinLotSize;
   if(total_loss_1_lot > 0)
     {
      lot = InpRiskAmountUSD / total_loss_1_lot;
     }

   // Lot yuvarlama
   double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   lot = MathRound(lot / lot_step) * lot_step;

   if(lot < InpMinLotSize) lot = InpMinLotSize;
   if(lot > InpMaxLotSize) lot = InpMaxLotSize;

   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   double sl_price = 0.0;
   double tp_price = 0.0;

   // Test Sinyali ise Lot Miktarını zorla 0.01 yap
   if(sig_dir == "TEST_BUY" || sig_dir == "TEST_SELL")
     {
      lot = InpMinLotSize;
      Print("🧪 TEST SİNYALİ ALGILANDI: Lot miktarı güvenli test için ", DoubleToString(lot, 2), " olarak ayarlandı.");
     }

   if(sig_dir == "BUY" || sig_dir == "TEST_BUY")
     {
      sl_price = ask - sl_dist_raw;
      tp_price = ask + tp_dist_raw;

      Print("🚀 BUY İşlemi Açılıyor... Lot: ", DoubleToString(lot, 2), " (ECN Modu: Önce işlemsiz açıp sonra SL/TP eklenecek)");

      if(trade.Buy(lot, Symbol(), ask, 0.0, 0.0, "5parite Receiver"))
        {
         // ECN hesaplarında işlemin anında Position'a dönüşmesi beklenir.
         // Position Modify fonksiyonuna mutlaka yeni açılan Ticket numarasını vermeliyiz!
         // Eğer Symbol() verirsek, grafikte çalışan DİĞER botların eski işlemlerini (Hedging) hedefleyip kendi SL'mizi bozabilir.
         ulong ticket = trade.ResultOrder();
         if (ticket == 0) ticket = trade.ResultDeal();

         // Eğer trade sınıfı ticketi doğrudan veremiyorsa, son açılan Magic Number uyumlu pozisyonu bulalım
         if (ticket == 0) {
             for(int i = PositionsTotal() - 1; i >= 0; i--) {
                 if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == 454545) {
                     ticket = PositionGetInteger(POSITION_TICKET);
                     break;
                 }
             }
         }

         if (ticket > 0 && trade.PositionModify(ticket, sl_price, tp_price))
           {
            Print("✅ BUY İşlemine (Ticket: ", ticket, ") SL: ", DoubleToString(sl_price, 5), " ve TP: ", DoubleToString(tp_price, 5), " başarıyla eklendi.");
           }
         else
           {
            Print("❌ BUY İşlemi açıldı ANCAK SL/TP Eklenemedi! Ticket: ", ticket, " Hata: ", trade.ResultRetcodeDescription());
           }
        }
      else
        {
         Print("❌ BUY İşlemi AÇILAMADI! Hata: ", trade.ResultRetcodeDescription());
        }
     }
   else if(sig_dir == "SELL" || sig_dir == "TEST_SELL")
     {
      sl_price = bid + sl_dist_raw;
      tp_price = bid - tp_dist_raw;

      Print("🚀 SELL İşlemi Açılıyor... Lot: ", DoubleToString(lot, 2), " (ECN Modu: Önce işlemsiz açıp sonra SL/TP eklenecek)");

      if(trade.Sell(lot, Symbol(), bid, 0.0, 0.0, "5parite Receiver"))
        {
         ulong ticket = trade.ResultOrder();
         if (ticket == 0) ticket = trade.ResultDeal();

         if (ticket == 0) {
             for(int i = PositionsTotal() - 1; i >= 0; i--) {
                 if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == 454545) {
                     ticket = PositionGetInteger(POSITION_TICKET);
                     break;
                 }
             }
         }

         if (ticket > 0 && trade.PositionModify(ticket, sl_price, tp_price))
           {
            Print("✅ SELL İşlemine (Ticket: ", ticket, ") SL: ", DoubleToString(sl_price, 5), " ve TP: ", DoubleToString(tp_price, 5), " başarıyla eklendi.");
           }
         else
           {
            Print("❌ SELL İşlemi açıldı ANCAK SL/TP Eklenemedi! Ticket: ", ticket, " Hata: ", trade.ResultRetcodeDescription());
           }
        }
      else
        {
         Print("❌ SELL İşlemi AÇILAMADI! Hata: ", trade.ResultRetcodeDescription());
        }
     }
  }
//+------------------------------------------------------------------+