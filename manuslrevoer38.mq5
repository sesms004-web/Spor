//+------------------------------------------------------------------+
//|                                             manuslrevoer38.mq5   |
//|                       Receiver EA for CHoCH_Trade_Signal         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "1.00"

#include <Trade\Trade.mqh>

input bool InpIgnoreSymbol = true; // Sinyal sembolünden bağımsız olarak kendi sembolünde işlem aç

CTrade trade;
long last_signal_time = 0;

int OnInit()
{
   EventSetTimer(1); // Check every second
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
}

void OnTimer()
{
   string fname = "CHoCH_Trade_Signal.csv";
   int fh = FileOpen(fname, FILE_READ | FILE_COMMON | FILE_CSV | FILE_ANSI, ';');
   if(fh == INVALID_HANDLE) return; // File might not exist yet

   if(FileIsEnding(fh)) { FileClose(fh); return; }

   string sig_sym = FileReadString(fh);
   int dir = (int)StringToInteger(FileReadString(fh));
   double entry = StringToDouble(FileReadString(fh));
   double sl = StringToDouble(FileReadString(fh));
   double tp = StringToDouble(FileReadString(fh));
   double lot = StringToDouble(FileReadString(fh));
   long sig_time = (long)StringToInteger(FileReadString(fh));

   FileClose(fh);

   if(sig_time <= last_signal_time) return; // Zaten işlenmiş
   last_signal_time = sig_time;
   if(TimeCurrent() - (datetime)sig_time > 60) return; // Eski sinyal (60 saniyeden eski)

   if(!InpIgnoreSymbol && sig_sym != Symbol())
   {
       Print("Sinyal sembolu (", sig_sym, ") mevcut sembol (", Symbol(), ") ile eslesmiyor.");
       return;
   }

   // Fiyatları mevcut chart'ın precision (Digits) seviyesine adapte et (xauusd -> xauusdb veya tersi)
   double norm_sl = NormalizeDouble(sl, _Digits);
   double norm_tp = NormalizeDouble(tp, _Digits);

   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   Print("YENI SINYAL ALINDI -> DIR: ", dir, " LOT: ", lot, " SL: ", norm_sl, " TP: ", norm_tp);

   trade.SetExpertMagicNumber(123456); // Belli bir magic numara

   if(dir == 1) // BUY
   {
      trade.Buy(lot, Symbol(), ask, norm_sl, norm_tp, "Sinyal Buy");
   }
   else if(dir == -1) // SELL
   {
      trade.Sell(lot, Symbol(), bid, norm_sl, norm_tp, "Sinyal Sell");
   }
}
