#property strict

#include <Trade/Trade.mqh>

CTrade trade;

//=========================== INPUTS ================================//
input double StopLoss_Pips      = 15;
input double TakeProfit_Pips    = 30;
input ulong  MagicNumber        = 777777;

// Daily Drawdown Protection
input bool   UseDailyDrawdown   = false;
input double MaxDailyDrawdown   = 5.0; // Max Daily Drawdown

//===================== VOLUME SETTINGS =============================//
enum ENUM_VOLUME_MODE
{
   Constant_Coefficient = 0,
   Constant_Volume      = 1
};

input ENUM_VOLUME_MODE Add_Volume_Options = Constant_Coefficient;

input double Constant_Coefficient_Value = 2.0;
input double Constant_Volume_Value      = 0.01;

//=========================== LICENSE ===============================//
datetime ExpiryDate = StringToTime("2026.06.29 23:59");

//========================== VARIABLES ==============================//
ulong lastManualPositionTicket = 0;
bool  cycleActive = false;

double pip;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // بررسی تاریخ انقضا
   if(TimeCurrent() > ExpiryDate)
   {
      Alert("EA Expired!");

      return(INIT_FAILED);
   }

   pip = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(_Digits == 3 || _Digits == 5)
      pip *= 10;

   Print("EA Initialized");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   // بررسی تاریخ انقضا
   if(TimeCurrent() > ExpiryDate)
      return;

   DetectManualTrades();
}

//+------------------------------------------------------------------+
//| Detect Manual Trades                                             |
//+------------------------------------------------------------------+
void DetectManualTrades()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);

      if(PositionSelectByTicket(ticket))
      {
         long magic = PositionGetInteger(POSITION_MAGIC);

         // فقط معاملات دستی
         if(magic == 0)
         {
            if(ticket != lastManualPositionTicket)
            {
               lastManualPositionTicket = ticket;

               cycleActive = true;

               SetSLTP(ticket);

               Print("Manual Trade Detected");
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Set SL/TP if Missing                                             |
//+------------------------------------------------------------------+
void SetSLTP(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
      return;

   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);

   // اگر هر دو وجود دارند کاری نکن
   if(currentSL != 0 && currentTP != 0)
      return;

   ENUM_POSITION_TYPE type =
      (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double openPrice =
      PositionGetDouble(POSITION_PRICE_OPEN);

   double sl = 0;
   double tp = 0;

   // BUY
   if(type == POSITION_TYPE_BUY)
   {
      sl = openPrice - (StopLoss_Pips * pip);
      tp = openPrice + (TakeProfit_Pips * pip);
   }

   // SELL
   else if(type == POSITION_TYPE_SELL)
   {
      sl = openPrice + (StopLoss_Pips * pip);
      tp = openPrice - (TakeProfit_Pips * pip);
   }

   trade.PositionModify(ticket, sl, tp);

   Print("SL/TP Set Automatically");
}

//+------------------------------------------------------------------+
//| Check Daily Drawdown                                             |
//+------------------------------------------------------------------+
bool CheckDailyDrawdown()
{
   // اگر غیرفعال بود همیشه اجازه معامله بده
   if(!UseDailyDrawdown)
      return true;

   datetime dayStart =
      StringToTime(TimeToString(TimeCurrent(), TIME_DATE));

   if(!HistorySelect(dayStart, TimeCurrent()))
      return true;

   double todayProfit = 0;

   int total = HistoryDealsTotal();

   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);

      long entry =
         HistoryDealGetInteger(ticket, DEAL_ENTRY);

      // فقط معاملات بسته شده
      if(entry != DEAL_ENTRY_OUT)
         continue;

      double profit =
         HistoryDealGetDouble(ticket, DEAL_PROFIT);

      double commission =
         HistoryDealGetDouble(ticket, DEAL_COMMISSION);

      double swap =
         HistoryDealGetDouble(ticket, DEAL_SWAP);

      todayProfit += (profit + commission + swap);
   }

   // بالانس فعلی
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   // درصد ضرر روزانه
   double ddPercent = 0;

   if(balance > 0)
      ddPercent = (-todayProfit / balance) * 100.0;

   // اگر بیشتر از حد مجاز بود
   if(todayProfit < 0 && ddPercent >= MaxDailyDrawdown)
   {
      Print("Max Daily Drawdown Reached");

      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Trade Transaction Event                                          |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   // بررسی تاریخ انقضا
   if(TimeCurrent() > ExpiryDate)
      return;

   // فقط زمانی که Deal جدید ثبت شود
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;

   ulong dealTicket = trans.deal;

   if(!HistoryDealSelect(dealTicket))
      return;

   long entryType =
      HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

   // فقط معاملات خروج
   if(entryType != DEAL_ENTRY_OUT)
      return;

   long reason =
      HistoryDealGetInteger(dealTicket, DEAL_REASON);

   // اگر دستی بسته شد
   if(reason == DEAL_REASON_CLIENT)
   {
      cycleActive = false;

      Print("Cycle Stopped By User");

      return;
   }

   // اگر TP خورد
   if(reason == DEAL_REASON_TP)
   {
      cycleActive = false;

      Print("Take Profit Reached");

      return;
   }

   // اگر SL خورد
   if(reason == DEAL_REASON_SL && cycleActive)
   {
      ReverseTrade(dealTicket);
   }
}

//+------------------------------------------------------------------+
//| Reverse Trade                                                    |
//+------------------------------------------------------------------+
void ReverseTrade(ulong closedDeal)
{
   ulong positionID =
      HistoryDealGetInteger(closedDeal, DEAL_POSITION_ID);

   if(positionID == 0)
      return;

   if(!HistorySelect(0, TimeCurrent()))
      return;

   long originalType = -1;
   double volume = 0;

   int total = HistoryDealsTotal();

   // پیدا کردن معامله اولیه
   for(int i = 0; i < total; i++)
   {
      ulong dealTicket = HistoryDealGetTicket(i);

      if(HistoryDealGetInteger(dealTicket,
         DEAL_POSITION_ID) == positionID)
      {
         long entry =
            HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

         if(entry == DEAL_ENTRY_IN)
         {
            originalType =
               HistoryDealGetInteger(dealTicket, DEAL_TYPE);

            volume =
               HistoryDealGetDouble(dealTicket, DEAL_VOLUME);

            break;
         }
      }
   }

   if(originalType == -1)
      return;

   // بررسی دراودان روزانه
   if(!CheckDailyDrawdown())
   {
      Print("New Trade Blocked By Daily Drawdown");

      cycleActive = false;

      return;
   }

   //============================================================//
   // محاسبه حجم جدید
   //============================================================//

   double newVolume = volume;

   // حالت ضریب ثابت
   if(Add_Volume_Options == Constant_Coefficient)
   {
      newVolume =
         volume * Constant_Coefficient_Value;
   }

   // حالت حجم ثابت
   else if(Add_Volume_Options == Constant_Volume)
   {
      newVolume =
         volume + Constant_Volume_Value;
   }

   newVolume = NormalizeDouble(newVolume, 2);

   // رعایت محدودیت لات بروکر
   double minLot =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   double maxLot =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double lotStep =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   newVolume =
      MathMax(minLot, MathMin(maxLot, newVolume));

   newVolume =
      NormalizeDouble(
         MathFloor(newVolume / lotStep) * lotStep,
         2
      );

   double ask =
      SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double bid =
      SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double sl = 0;
   double tp = 0;

   trade.SetExpertMagicNumber(MagicNumber);

   //============================================================//
   // اگر معامله اولیه BUY بوده => SELL باز کن
   //============================================================//
   if(originalType == DEAL_TYPE_BUY)
   {
      sl = bid + (StopLoss_Pips * pip);
      tp = bid - (TakeProfit_Pips * pip);

      bool sellResult =
         trade.Sell(
            newVolume,
            _Symbol,
            0,
            sl,
            tp,
            "Reverse Sell"
         );

      if(sellResult)
         Print("Reverse SELL Opened");
      else
         Print("SELL Error: ", GetLastError());
   }

   //============================================================//
   // اگر معامله اولیه SELL بوده => BUY باز کن
   //============================================================//
   else if(originalType == DEAL_TYPE_SELL)
   {
      sl = ask - (StopLoss_Pips * pip);
      tp = ask + (TakeProfit_Pips * pip);

      bool buyResult =
         trade.Buy(
            newVolume,
            _Symbol,
            0,
            sl,
            tp,
            "Reverse Buy"
         );

      if(buyResult)
         Print("Reverse BUY Opened");
      else
         Print("BUY Error: ", GetLastError());
   }
}
//+------------------------------------------------------------------+