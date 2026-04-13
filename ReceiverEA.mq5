//+------------------------------------------------------------------+
//|                                                   ReceiverEA.mq5 |
//|                                      Mükemmeliyet JSON Alıcı EA  |
//+------------------------------------------------------------------+
#property copyright "Jules"
#property link      ""
#property version   "1.01"

#include <Trade\Trade.mqh>

//--- Input Parameters ---
input string   InpListenSymbol = "XAUUSD";   // Sinyali Dinlenen Sembol (Örn: XAUUSD)
input ulong    InpMagicNumber  = 454545;     // EA Magic Number
input ulong    InpSlippage     = 10;         // Maksimum Kayma (Slippage)

input double   InpRiskUSD      = 20.0;       // İşlem Başına Risk (USD)
input double   InpMinLot       = 0.01;       // Minimum Lot Sınırı
input double   InpMaxLot       = 5.0;        // Maksimum Lot Sınırı (Patlamayı Önler)

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   EventSetTimer(1);

   Print("🟢 [RECEIVER EA] Başlatıldı. Dinlenen: ", InpListenSymbol, " -> İşlem Sembolü: ", Symbol(), " Risk: $", InpRiskUSD);
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
//| Helpers for JSON                                                 |
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

bool GetJsonBool(string json_data, string key)
  {
   string search = "\"" + key + "\": ";
   int start = StringFind(json_data, search);
   if(start < 0) return false;
   start += StringLen(search);
   int end = StringFind(json_data, ",", start);
   if(end < 0) end = StringFind(json_data, "\n", start);
   if(end < 0) end = StringFind(json_data, "}", start);
   string val = StringSubstr(json_data, start, end - start);
   if(StringFind(val, "true") >= 0) return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   string filename = "signal_" + InpListenSymbol + ".json";

   if(FileIsExist(filename, FILE_COMMON))
     {
      int handle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_COMMON);
      if(handle != INVALID_HANDLE)
        {
         string json_content = "";
         while(!FileIsEnding(handle))
           {
            json_content += FileReadString(handle) + "\n";
           }
         FileClose(handle);

         FileDelete(filename, FILE_COMMON);
         Print("📩 [RECEIVER EA] Sinyal Alındı ve Silindi:\n", json_content);

         string direction = GetJsonString(json_content, "direction");
         double entry     = GetJsonDouble(json_content, "entry");
         double sl        = GetJsonDouble(json_content, "sl");
         double tp        = GetJsonDouble(json_content, "tp");

         if(direction == "") return;

         ExecuteSignal(direction, entry, sl, tp, GetJsonDouble(json_content, "risk_usd"));
        }
     }
  }

//+------------------------------------------------------------------+
//| Execute Signal (Lot Calculation & Execution)                     |
//+------------------------------------------------------------------+
void ExecuteSignal(string direction, double entry, double sl, double tp, double risk_usd)
  {
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   double tick_val = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);

   double lot_size = InpMinLot;

   double sl_distance_points = MathAbs(entry - sl) / point;
   if (sl_distance_points > 0 && tick_size > 0) {
       double loss_per_lot = (sl_distance_points * point / tick_size) * tick_val;
       if (loss_per_lot > 0) {
           double active_risk = (risk_usd > 0) ? risk_usd : InpRiskUSD;
           lot_size = active_risk / loss_per_lot;
           // Küsurat düzeltme (örn 0.01 hassasiyetine)
           double step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
           lot_size = MathFloor(lot_size / step) * step;

           // Min ve Max lot sınırları
           if(lot_size < InpMinLot) lot_size = InpMinLot;
           if(lot_size > InpMaxLot) lot_size = InpMaxLot;

           Print("🧮 [RECEIVER EA] SL Mesafe: ", sl_distance_points, " Point | Risk: $", active_risk, " -> Hesaplan Lot: ", lot_size);
       }
   }

   bool success = false;
   ulong ticket = 0;

   // Doğrudan SL/TP ile aç (PositionModify kullanılmıyor)
   if(direction == "BUY")
     {
      success = trade.Buy(lot_size, Symbol(), ask, sl, tp, "JSON BUY");
     }
   else if(direction == "SELL")
     {
      success = trade.Sell(lot_size, Symbol(), bid, sl, tp, "JSON SELL");
     }

   if(success)
     {
      ticket = trade.ResultOrder();
      if(ticket == 0) ticket = trade.ResultDeal();
      Print("✅ [RECEIVER EA] ", direction, " İşlemi BAŞARILI! Bilet: ", ticket, " Lot: ", lot_size, " SL: ", sl, " TP: ", tp);
     }
   else
     {
      Print("❌ [RECEIVER EA] İşlem Açılamadı! Hata Kodu: ", GetLastError());
     }
  }
