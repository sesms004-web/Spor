//+------------------------------------------------------------------+
//|                                                    TrackerEA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Trade\DealInfo.mqh>

CPositionInfo  m_position;

//--- Webhook/API URL for testing ---
// This is where MT5 will send the JSON data.
input string InpApiUrl = "https://webhook.site/YOUR-UNIQUE-WEBHOOK-ID";

struct PositionState {
   long   ticket;
   string symbol;
   int    type;
   double volume;
   double open_price;
   double sl;
   double tp;
   datetime open_time;
   bool   is_active;
};

PositionState g_active_positions[];

//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Tracker EA Started - Broadcasting via WebRequest...");
   ArrayResize(g_active_positions, 0);
   SyncActivePositions();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
  }

void OnTimer()
  {
   // 1. Check for new or modified positions
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(m_position.SelectByIndex(i))
        {
         long ticket = m_position.Ticket();
         int index = FindPositionIndex(ticket);

         if(index == -1) // New position
           {
            int new_idx = ArraySize(g_active_positions);
            ArrayResize(g_active_positions, new_idx + 1);
            g_active_positions[new_idx].ticket = ticket;
            g_active_positions[new_idx].symbol = m_position.Symbol();
            g_active_positions[new_idx].type = (int)m_position.PositionType();
            g_active_positions[new_idx].volume = m_position.Volume();
            g_active_positions[new_idx].open_price = m_position.PriceOpen();
            g_active_positions[new_idx].sl = m_position.StopLoss();
            g_active_positions[new_idx].tp = m_position.TakeProfit();
            g_active_positions[new_idx].open_time = m_position.Time();
            g_active_positions[new_idx].is_active = true;

            Print("✅ NEW Trade Detected: ", ticket);
            SendTradeToApi(g_active_positions[new_idx], "OPEN");
           }
         else // Existing position, check if SL/TP modified
           {
            if(g_active_positions[index].sl != m_position.StopLoss() || g_active_positions[index].tp != m_position.TakeProfit())
              {
               g_active_positions[index].sl = m_position.StopLoss();
               g_active_positions[index].tp = m_position.TakeProfit();
               Print("✏️ Trade Modified (SL/TP): ", ticket);
               SendTradeToApi(g_active_positions[index], "MODIFIED");
              }
           }
        }
     }

   // 2. Check for closed positions
   for(int i = ArraySize(g_active_positions) - 1; i >= 0; i--)
     {
      if(g_active_positions[i].is_active)
        {
         if(!PositionSelectByTicket(g_active_positions[i].ticket))
           {
            g_active_positions[i].is_active = false;

            HistorySelect(g_active_positions[i].open_time, TimeCurrent());
            string close_reason = "CLOSED_MANUAL";

            for(int d = 0; d < HistoryDealsTotal(); d++)
              {
               ulong deal_ticket = HistoryDealGetTicket(d);
               if(HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID) == g_active_positions[i].ticket)
                 {
                  if(HistoryDealGetInteger(deal_ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
                    {
                     string comment = HistoryDealGetString(deal_ticket, DEAL_COMMENT);
                     if(StringFind(comment, "sl") >= 0) close_reason = "CLOSED_SL";
                     else if(StringFind(comment, "tp") >= 0) close_reason = "CLOSED_TP";
                    }
                 }
              }
            Print("❌ Trade Closed: ", g_active_positions[i].ticket, " Reason: ", close_reason);
            SendTradeToApi(g_active_positions[i], close_reason);
           }
        }
     }
  }

int FindPositionIndex(long ticket)
  {
   for(int i = 0; i < ArraySize(g_active_positions); i++)
     {
      if(g_active_positions[i].ticket == ticket) return i;
     }
   return -1;
  }

void SyncActivePositions()
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(m_position.SelectByIndex(i))
        {
         int new_idx = ArraySize(g_active_positions);
         ArrayResize(g_active_positions, new_idx + 1);
         g_active_positions[new_idx].ticket = m_position.Ticket();
         g_active_positions[new_idx].symbol = m_position.Symbol();
         g_active_positions[new_idx].type = (int)m_position.PositionType();
         g_active_positions[new_idx].volume = m_position.Volume();
         g_active_positions[new_idx].open_price = m_position.PriceOpen();
         g_active_positions[new_idx].sl = m_position.StopLoss();
         g_active_positions[new_idx].tp = m_position.TakeProfit();
         g_active_positions[new_idx].open_time = m_position.Time();
         g_active_positions[new_idx].is_active = true;
        }
     }
  }

//+------------------------------------------------------------------+
//| Send JSON Payload via WebRequest to the API/Webhook              |
//+------------------------------------------------------------------+
void SendTradeToApi(PositionState &pos, string status)
  {
   if(InpApiUrl == "" || StringFind(InpApiUrl, "YOUR-UNIQUE") >= 0)
     {
      Print("⚠️ Please set a valid Webhook URL in EA settings to test data transmission.");
      return;
     }

   // 1. Build JSON Payload
   string json = "{";
   json += "\"ticket\": " + IntegerToString(pos.ticket) + ",";
   json += "\"symbol\": \"" + pos.symbol + "\",";
   json += "\"type\": \"" + (pos.type == 0 ? "BUY" : "SELL") + "\",";
   json += "\"volume\": " + DoubleToString(pos.volume, 2) + ",";
   json += "\"open_price\": " + DoubleToString(pos.open_price, 5) + ",";
   json += "\"sl\": " + DoubleToString(pos.sl, 5) + ",";
   json += "\"tp\": " + DoubleToString(pos.tp, 5) + ",";
   json += "\"status\": \"" + status + "\"";
   json += "}";

   // 2. Prepare WebRequest
   char post_data[];
   char result_data[];
   string result_headers;

   StringToCharArray(json, post_data, 0, WHOLE_ARRAY, CP_UTF8);

   // We need to remove the terminating null character added by StringToCharArray
   if(ArraySize(post_data) > 0) ArrayResize(post_data, ArraySize(post_data)-1);

   string headers = "Content-Type: application/json\r\n";

   // 3. Send HTTP POST Request
   int res = WebRequest("POST", InpApiUrl, headers, 5000, post_data, result_data, result_headers);

   if(res == 200 || res == 201)
     {
      Print("✅ Successfully sent data to server! Status: ", status);
     }
   else
     {
      Print("❌ Failed to send data. Error code: ", GetLastError(), " HTTP Code: ", res);
      Print("ℹ️ Make sure '", InpApiUrl, "' is allowed in MT5 -> Tools -> Options -> Expert Advisors -> Allow WebRequest.");
     }
  }
