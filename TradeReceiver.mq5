//+------------------------------------------------------------------+
//|                                                TradeReceiver.mq5 |
//|   Reads common CSV signal files and executes trades dynamically. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

//--- Ayarlar
input double InpLotSize = 0.01;      // Islem Hacmi (Lot)
input int    InpMagicNumber = 12345; // Magic Number
input bool   InpUseMagicOnly = false;// Sadece kendi actigimiz islemleri say

string g_last_signal = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);
   Print("TradeReceiver initialized for symbol: ", Symbol(), " with digits: ", _Digits);

   // Clean up any existing file for this base symbol prefix to avoid old trades
   // Symbol might be XAUUSD on sender and XAUUSD.b on receiver, so we will match prefix
   // This logic is mostly reading though, so let's just parse whatever is there
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("TradeReceiver deinitialized.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for signal files matching our base symbol
   // Assuming sender writes to "CHoCH_Signal_[SenderSymbol].csv"

   // We will try to open any file that starts with "CHoCH_Signal_" and contains the first 6 chars of our symbol (e.g. XAUUSD)
   string base_sym = StringSubstr(Symbol(), 0, 6); // "XAUUSD"
   string file_name = "CHoCH_Signal_" + base_sym + ".csv";

   // XAUUSDb (receiver) looking for XAUUSD (sender)

   // We check if file exists by trying to open it in read mode from COMMON folder
   int h = FileOpen(file_name, FILE_READ | FILE_CSV | FILE_COMMON | FILE_ANSI, ',');
   if(h == INVALID_HANDLE) {
      // It might be exactly the receiver symbol (if both are same)
      file_name = "CHoCH_Signal_" + Symbol() + ".csv";
      h = FileOpen(file_name, FILE_READ | FILE_CSV | FILE_COMMON | FILE_ANSI, ',');
   }

   if(h != INVALID_HANDLE)
   {
      string sender_sym = FileReadString(h);
      string direction = FileReadString(h);
      double entry_price = StringToDouble(FileReadString(h));
      double sl = StringToDouble(FileReadString(h));
      double tp = StringToDouble(FileReadString(h));
      string time_str = FileReadString(h);

      FileClose(h);

      // Prevent duplicate executions
      string sig_id = time_str + direction + DoubleToString(entry_price, 5);
      if(sig_id != g_last_signal)
      {
         g_last_signal = sig_id;

         // Normalize prices to the current chart's digits (fixes 4444.44 vs 4444.444 issue)
         double norm_sl = NormalizeDouble(sl, _Digits);
         double norm_tp = NormalizeDouble(tp, _Digits);

         PrintFormat("Yeni Sinyal Alindi: Yön=%s, Cift=%s (Hedef=%s), SL=%.*f, TP=%.*f, Zaman=%s",
                     direction, sender_sym, Symbol(), _Digits, norm_sl, _Digits, norm_tp, time_str);

         // Execute trade
         if(direction == "BUY")
         {
            double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            // Optionally, check if price is somewhat close to entry, but for now we execute Market Order
            trade.Buy(InpLotSize, Symbol(), ask, norm_sl, norm_tp, "CHoCH Auto");
            Print("BUY islem acildi. Fiyat: ", ask, " SL: ", norm_sl, " TP: ", norm_tp);
         }
         else if(direction == "SELL")
         {
            double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            trade.Sell(InpLotSize, Symbol(), bid, norm_sl, norm_tp, "CHoCH Auto");
            Print("SELL islem acildi. Fiyat: ", bid, " SL: ", norm_sl, " TP: ", norm_tp);
         }
      }

      // Delete file after reading so it's not processed again across restarts
      FileDelete(file_name, FILE_COMMON);
   }
}
