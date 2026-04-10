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

   // Format: SYMBOL, DIR, ENTRY, SL, TP, BASE_EXTREME
   // Örn: EURUSD,BUY,1.08500,1.08400,1.08800,1.08450
   string parts[];
   int count = StringSplit(signal_data, ',', parts);

   if (count != 6) {
       Print("❌ [VOL100 RECEIVER] Sinyal formatı hatalı (6 Parça bekleniyor): ", signal_data);
       return;
   }

   string sym = parts[0];
   string dir = parts[1];
   double entry_p = StringToDouble(parts[2]);
   double sl_p = StringToDouble(parts[3]);
   double tp_p = StringToDouble(parts[4]);
   double ext_pt = StringToDouble(parts[5]); // 1.0x (Sıfır Çarpanlı) Ana SL Mesafesi İçin Referans

   // Sinyalin ait olduğu sembol kontrolü
   if (sym != listen_sym) {
       Print("⚠️ [VOL100 RECEIVER] Yanlış Sembol! Gelen Sinyal: ", sym, " Beklenen Sinyal: ", listen_sym);
       return;
   }

   // --- AÇIK POZİSYON (CONCURRENT TRADE) KONTROLÜ ---
   if (HasOpenPosition(Symbol())) {
       Print("⚠️ [VOL100 RECEIVER] Hali hazırda açık bir ", Symbol(), " işlemi bulunuyor. Yeni sinyal reddedildi (Sinyal dosyası silindi).");
       return;
   }

   // --- RİSK & LOT HESAPLAMASI (20$ SABİT BAZ RİSK) ---
   // Kullanıcı çarpanı (örn: 2.0x SL) arttırsa bile, lot hesabı DAİMA 1.0x ana kırılım (ext_pt) mesafesine göre yapılır.
   // Bu sayede SL ne kadar uzağa çekilirse çekilsin, kayıp orantılı olarak artar (örn: 2.0x SL = 40$ Risk olur).
   double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE); // 1 lot için 1 tick/puan değeri ($)
   double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);

   if (tick_value <= 0 || tick_size <= 0) {
       Print("❌ [VOL100 RECEIVER] Sembol tick değeri okunamadı: ", Symbol());
       return;
   }

   // BAZ SL MESAFESİ: Canlı giriş noktası (entry) ile ana kırılım noktası (ext_pt) arasındaki 1.0x mesafe
   double base_distance_in_price = MathAbs(entry_p - ext_pt);
   double base_ticks_to_sl = base_distance_in_price / tick_size;

   if (base_ticks_to_sl <= 0) {
       Print("❌ [VOL100 RECEIVER] SL baz mesafesi çok küçük veya 0!");
       return;
   }

   // 1 Lot açsaydık bu BAZ MESAFEDE (1.0x) kaç dolar kaybederdik?
   double loss_per_lot = base_ticks_to_sl * tick_value;

   // Tam 20$ (veya ayarlanan InpRiskUSD) riski bu 1.0x BAZ MESAFEYE gömmek için kaç lot açmalıyız?
   double calculated_lot = InpRiskUSD / loss_per_lot;

   // Lot Miktarını Limitle (Örn: En az 0.01, Step 0.01)
   double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double step_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   if (step_lot <= 0) step_lot = 0.01;

   double final_lot = MathRound(calculated_lot / step_lot) * step_lot;

   if (final_lot < min_lot) final_lot = min_lot;
   if (final_lot > max_lot) final_lot = max_lot;

   // FİİLİ (GERÇEK) SL MESAFESİ: Kullanıcının çarpanla (örn: 1.5x) belirlediği SL.
   // Bu fiyatları doğrudan göstergeden alıp EA'nın fiyatıyla birleştireceğiz (eski sağlam sisteme dönüş).
   double live_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double live_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   if (dir == "BUY") {
       // Kendi Ask fiyatımızdan, göstergeden gelen SL mesafesini çıkar
       double raw_sl_dist = entry_p - sl_p;
       double raw_tp_dist = tp_p - entry_p;
       double local_sl = live_ask - raw_sl_dist;
       double local_tp = live_ask + raw_tp_dist;

       if (trade.Buy(final_lot, Symbol(), live_ask, local_sl, local_tp, "VOL100 Auto-Trade")) {
           Print("✅ [VOL100 RECEIVER] BUY İşlemi Açıldı! Lot: ", final_lot, " SL: ", local_sl, " TP: ", local_tp, " (Baz Risk: $", InpRiskUSD, ")");
       } else {
           Print("❌ [VOL100 RECEIVER] BUY İşlemi BAŞARISIZ! Hata Kodu: ", trade.ResultRetcode());
       }
   }
   else if (dir == "SELL") {
       // Kendi Bid fiyatımıza, göstergeden gelen SL mesafesini ekle
       double raw_sl_dist = sl_p - entry_p;
       double raw_tp_dist = entry_p - tp_p;
       double local_sl = live_bid + raw_sl_dist;
       double local_tp = live_bid - raw_tp_dist;

       if (trade.Sell(final_lot, Symbol(), live_bid, local_sl, local_tp, "VOL100 Auto-Trade")) {
           Print("✅ [VOL100 RECEIVER] SELL İşlemi Açıldı! Lot: ", final_lot, " SL: ", local_sl, " TP: ", local_tp, " (Baz Risk: $", InpRiskUSD, ")");
       } else {
           Print("❌ [VOL100 RECEIVER] SELL İşlemi BAŞARISIZ! Hata Kodu: ", trade.ResultRetcode());
       }
   }
  }
//+------------------------------------------------------------------+
