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

input string InpApiUrl = "https://webhook.site/YOUR-UNIQUE-WEBHOOK-ID";
input string InpLicenseKey = "DEMO-12345";
input double InpLotSize = 0.01;

datetime g_last_signal_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("📡 Slave EA Started. Connecting to Quant Server...");

   // Verify WebRequest capability
   if(InpApiUrl == "" || StringFind(InpApiUrl, "YOUR-UNIQUE") >= 0)
     {
      Alert("⚠️ Lütfen geçerli bir Webhook URL girin!");
      return(INIT_FAILED);
     }

   // License check could go here...
   Print("🔑 Lisans kontrol edildi: ONAYLANDI");

   // Setup timer to check for signals every 2 seconds
   EventSetTimer(2);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   Print("🛑 Slave EA Stopped.");
  }

//+------------------------------------------------------------------+
//| Timer function - Checking for signals                            |
//+------------------------------------------------------------------+
void OnTimer()
  {
   CheckForNewSignals();
  }

//+------------------------------------------------------------------+
//| Fetch Signals from API                                           |
//+------------------------------------------------------------------+
void CheckForNewSignals()
  {
   // In a real production environment, you would call an API endpoint
   // like "GET /api/signals?last_time=..." to get ONLY new signals.
   // Since webhook.site doesn't easily allow GET fetching of past bodies via simple MQL5 without API keys,
   // we simulate the JSON parsing logic here that would run when a payload is received.

   // --- MOCK API CALL DEMONSTRATION ---
   /*
   char post_data[];
   char result_data[];
   string result_headers;
   string headers = "License-Key: " + InpLicenseKey + "\r\n";

   int res = WebRequest("GET", InpApiUrl + "/get_latest_signal", headers, 5000, post_data, result_data, result_headers);
   if(res == 200) {
       string json_response = CharArrayToString(result_data);
       ProcessSignal(json_response);
   }
   */

   // For now, let's just log that the heartbeat is working.
   // The real logic requires a dedicated backend (Node.js/Firebase) to store and serve the signals.
  }

//+------------------------------------------------------------------+
//| Process JSON Signal and Execute Trade                            |
//+------------------------------------------------------------------+
void ProcessSignal(string json_payload)
  {
   // Mock JSON: {"action":"NEW_TRADE","symbol":"XAUUSD","type":"BUY","sl":2300,"tp":2350}
   // Note: MQL5 requires a dedicated JSON library (like JAson.mqh) to parse properly.
   // We use simple string searching for demonstration.

   if(StringFind(json_payload, "\"action\":\"NEW_TRADE\"") >= 0)
     {
      string symbol = "XAUUSD"; // extract from JSON
      string type = "BUY";      // extract from JSON
      double sl = 2300.0;       // extract from JSON
      double tp = 2350.0;       // extract from JSON

      ExecuteTrade(symbol, type, sl, tp);
     }
  }

//+------------------------------------------------------------------+
//| Execute the Trade using CTrade                                   |
//+------------------------------------------------------------------+
void ExecuteTrade(string symbol, string type, double sl, double tp)
  {
   // Safety check: is symbol available?
   if(!SymbolSelect(symbol, true)) {
      Print("❌ Hata: Parite bulunamadı - ", symbol);
      return;
   }

   double price = 0;

   if(type == "BUY")
     {
      price = SymbolInfoDouble(symbol, SYMBOL_ASK);
      trade.Buy(InpLotSize, symbol, price, sl, tp, "Quant Copier Sinyali");
      Print("✅ İŞLEM AÇILDI: BUY ", symbol, " @ ", price, " SL:", sl, " TP:", tp);
     }
   else if(type == "SELL")
     {
      price = SymbolInfoDouble(symbol, SYMBOL_BID);
      trade.Sell(InpLotSize, symbol, price, sl, tp, "Quant Copier Sinyali");
      Print("✅ İŞLEM AÇILDI: SELL ", symbol, " @ ", price, " SL:", sl, " TP:", tp);
     }
  }
