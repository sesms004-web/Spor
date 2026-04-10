//+------------------------------------------------------------------+
//|                                                   ReceiverEA.mq5 |
//|                                      Mükemmeliyet JSON Alıcı EA  |
//+------------------------------------------------------------------+
#property copyright "Jules"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Input Parameters ---
input string   InpListenSymbol = "XAUUSD";   // Sinyali Gönderen Sembol (Örn: XAUUSD)
input double   InpLotSize      = 0.01;       // İşlem Hacmi (Lot)
input ulong    InpMagicNumber  = 454545;     // EA Magic Number
input ulong    InpSlippage     = 10;         // Maksimum Kayma (Slippage)

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK); // veya brokerinize göre ORDER_FILLING_IOC

   // 1 saniyede bir ortak klasörü kontrol et
   EventSetTimer(1);

   Print("🟢 [RECEIVER EA] Başlatıldı. Dinlenen Sinyal: ", InpListenSymbol, " -> İşlem Açılacak Sembol: ", Symbol());

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   Print("🔴 [RECEIVER EA] Durduruldu.");
  }

//+------------------------------------------------------------------+
//| Helper: Extract String from JSON                                 |
//+------------------------------------------------------------------+
string GetJsonString(string json_data, string key)
  {
   string search = "\"" + key + "\": \"";
   int start = StringFind(json_data, search);
   if(start < 0) return "";

   start += StringLen(search);
   int end = StringFind(json_data, "\"", start);
   if(end < 0) return "";

   return StringSubstr(json_data, start, end - start);
  }

//+------------------------------------------------------------------+
//| Helper: Extract Double from JSON                                 |
//+------------------------------------------------------------------+
double GetJsonDouble(string json_data, string key)
  {
   string search = "\"" + key + "\": ";
   int start = StringFind(json_data, search);
   if(start < 0) return 0.0;

   start += StringLen(search);
   int end = StringFind(json_data, ",", start);
   if(end < 0) end = StringFind(json_data, "\n", start);
   if(end < 0) end = StringFind(json_data, "}", start);

   string val = StringSubstr(json_data, start, end - start);
   StringReplace(val, " ", "");
   StringReplace(val, "\r", "");

   return StringToDouble(val);
  }

//+------------------------------------------------------------------+
//| Timer function: Poll for signal file                             |
//+------------------------------------------------------------------+
void OnTimer()
  {
   string filename = "signal_" + InpListenSymbol + ".json";

   // Dosya Common klasöründe var mı kontrol et
   if(FileIsExist(filename, FILE_COMMON))
     {
      // Dosyayı okumak için aç
      int handle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_COMMON);
      if(handle != INVALID_HANDLE)
        {
         string json_content = "";
         while(!FileIsEnding(handle))
           {
            json_content += FileReadString(handle) + "\n";
           }
         FileClose(handle);

         // Okuduktan hemen sonra dosyayı sil ki aynı işleme tekrar girmesin!
         FileDelete(filename, FILE_COMMON);

         Print("📩 [RECEIVER EA] Sinyal Yakalandı ve Silindi:\n", json_content);

         // JSON'u Parse Et
         string direction = GetJsonString(json_content, "direction");
         double sl = GetJsonDouble(json_content, "sl");
         double tp = GetJsonDouble(json_content, "tp");

         if(direction == "") {
             Print("❌ [RECEIVER EA] JSON parse hatası, direction bulunamadı!");
             return;
         }

         ExecuteSignal(direction, sl, tp);
        }
     }
  }

//+------------------------------------------------------------------+
//| Execute the Trade Safely (ECN/STP Support)                       |
//+------------------------------------------------------------------+
void ExecuteSignal(string direction, double sl, double tp)
  {
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   // Market order execution without SL/TP first (ECN/STP broker compatibility)
   bool success = false;
   ulong ticket = 0;

   if(direction == "BUY")
     {
      success = trade.Buy(InpLotSize, Symbol(), ask, 0, 0, "JSON Signal BUY");
     }
   else if(direction == "SELL")
     {
      success = trade.Sell(InpLotSize, Symbol(), bid, 0, 0, "JSON Signal SELL");
     }

   if(success)
     {
      ticket = trade.ResultOrder();
      Print("✅ [RECEIVER EA] ", direction, " İşlemi Başarıyla Açıldı. Bilet: ", ticket);

      // Stop Loss ve Take Profit'i sonradan modifiye et (Sıfır Stop Hatasını Önler)
      if(sl > 0 || tp > 0)
        {
         // ECN brokerlarda pozisyonu güncelle
         if(trade.PositionModify(Symbol(), sl, tp))
           {
            Print("✅ [RECEIVER EA] SL/TP Başarıyla Ayarlandı. SL: ", sl, " TP: ", tp);
           }
         else
           {
            Print("⚠️ [RECEIVER EA] SL/TP ayarlanamadı! Hata: ", GetLastError());
           }
        }
     }
   else
     {
      Print("❌ [RECEIVER EA] İşlem Açılamadı! Hata Kodu: ", GetLastError());
     }
  }
