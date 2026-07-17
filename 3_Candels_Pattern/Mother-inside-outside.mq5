//+------------------------------------------------------------------+
//|                                        Mother-inside-outside.mq5 |
//|                                                    Fardin Marabi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Fardin Marabi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                    AliNezhad.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//|                       inputs                                     |
//+------------------------------------------------------------------+


input group "Setup Selection"
enum ENUM_SETUP_TYPE
{
   SETUP_BOLLINGER = 0,
   SETUP_MOTHER_INSIDE_OUTSIDE = 1
};
input ENUM_SETUP_TYPE setup_type = SETUP_BOLLINGER;


input group "Trading Hours"
input bool use_trading_time = true;

input int trading_start_hour = 8;
input int trading_end_hour = 17;



input group "♠ Candle Properties ♠"
input int body_percent = 80;//Body Percent(%)
input int period = 100;//Period
input double coefficient = 1.5;//Coefficient
input bool use_body_percent = true;//Use Body Percent
input bool use_average_body_size = true;//Use Average body Size

input group "♠ Bollinger Bands Properties ♠"
input int bb_period = 20;//Period
input int shift = 0;//Shift
input int deviations = 2;//Deviations
input ENUM_APPLIED_PRICE bb_app = PRICE_CLOSE;//Apply To

input group "♠ Trade Properties ♠"
input string trade_comment = "";//Trade Comment

input group ""
input double rr1 = 1.5;//Reward(Step 1)
input double rr2 = 1.5;//Reward(Step 2)
input double rr3 = 1.5;//Reward(Step 3)
input double rr4 = 1.5;//Reward(Step 4)
input double rr5 = 1.5;//Reward(Step 5)
input double rr6 = 1.5;//Reward(Step 6)
input double rr7 = 1.5;//Reward(Step 7)
input double rr8 = 1.5;//Reward(Step 8)

input group ""
enum volume_options 
  {
   v0 = 0,     // Percent
   v1 = 1,     // Lot
  };
input volume_options volume_option = v0;//Volume Option

input group ""
input double volume1 = 0.01;//Volume(Step 1-Lot)
input double volume2 = 0.01;//Volume(Step 2-Lot)
input double volume3 = 0.01;//Volume(Step 3-Lot)
input double volume4 = 0.01;//Volume(Step 4-Lot)
input double volume5 = 0.01;//Volume(Step 5-Lot)
input double volume6 = 0.01;//Volume(Step 6-Lot)
input double volume7 = 0.01;//Volume(Step 7-Lot)
input double volume8 = 0.01;//Volume(Step 8-Lot)

input group ""
input double volumep1 = 0.25;//Volume(Step 1-Percent)
input double volumep2 = 0.25;//Volume(Step 2-Percent)
input double volumep3 = 0.25;//Volume(Step 3-Percent)
input double volumep4 = 0.25;//Volume(Step 4-Percent)
input double volumep5 = 0.25;//Volume(Step 5-Percent)
input double volumep6 = 0.25;//Volume(Step 6-Percent)
input double volumep7 = 0.25;//Volume(Step 7-Percent)
input double volumep8 = 0.25;//Volume(Step 8-Percent)





//+------------------------------------------------------------------+
//|                       variable                                   |
//+------------------------------------------------------------------+
int bb_handle;
double bb_upper[];
double bb_lower[];

int object_counter = 0;

string upper_line;
string lower_line;

double upper_value;
double lower_value;

int step = 0;
string position_type;
double position_sl;
double position_tp;
ulong position_ticket;

double volume_L[8] = {volume1, volume2, volume3, volume4, volume5, volume6, volume7, volume8};;
double volume_P[8] = {volumep1, volumep2, volumep3, volumep4, volumep5, volumep6, volumep7, volumep8};
double rr_list[8] = {rr1, rr2, rr3, rr4, rr5, rr6, rr7, rr8};

datetime step_zero_controler;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   bb_handle = iBands(Symbol(), PERIOD_CURRENT, bb_period, shift, deviations, bb_app);
   ArraySetAsSeries(bb_lower, true);
   ArraySetAsSeries(bb_upper, true);
   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   CopyBuffer(bb_handle, 1, 0, 3, bb_upper);
   CopyBuffer(bb_handle, 2, 0, 3, bb_lower);
   
   
   
   
   set_initial_position_lines_function();
   open_first_step_position_function();
   open_next_steps_function();
   step_zero_function();


   // محاسبه اطلاعات کندل قبلی برای نمایش
   double previous_body =
      MathAbs(
         iClose(Symbol(), PERIOD_CURRENT, 1) -
         iOpen(Symbol(), PERIOD_CURRENT, 1)
      );


   double previous_range =
      iHigh(Symbol(), PERIOD_CURRENT, 1) -
      iLow(Symbol(), PERIOD_CURRENT, 1);


   string previous_body_percent_condition = "False";


   if(previous_range > 0)
   {
      previous_body_percent_condition =
      (
         previous_body / previous_range > body_percent / 100.0
      )
      ? "True" : "False";
   }


   if(step >= 2)
   {
      Comment(
         "Step: ", IntegerToString(step - 1), "\n",
         "Average Body Size: ",
         (string)DoubleToString(
            average_body_size(period),
            (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)
         ),
         "\n",

         "Previous Body Size: ",
         (string)DoubleToString(
            previous_body,
            (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)
         ),
         "\n",

         "Previous Body Percent Condition: ",
         previous_body_percent_condition
      );
   }
   else
   {
      Comment(
         "Average Body Size: ",
         (string)DoubleToString(
            average_body_size(period),
            (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)
         ),
         "\n",

         "Previous Body Size: ",
         (string)DoubleToString(
            previous_body,
            (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)
         ),
         "\n",

         "Previous Body Percent Condition: ",
         previous_body_percent_condition
      );
   }
}
//+------------------------------------------------------------------+
//|                    create objects                                |
//+------------------------------------------------------------------+
//trend line
string line_creator(double p1, datetime t1, double p2, datetime t2, color _color, int _style, int _width)
   {
   ObjectCreate(ChartID(), "TL" + IntegerToString(object_counter), OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(ChartID(), "TL" + IntegerToString(object_counter), OBJPROP_COLOR, _color);
   ObjectSetInteger(ChartID(), "TL" + IntegerToString(object_counter), OBJPROP_STYLE, _style);
   ObjectSetInteger(ChartID(), "TL" + IntegerToString(object_counter), OBJPROP_WIDTH, _width);
   ObjectSetInteger(ChartID(), "TL" + IntegerToString(object_counter), OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(ChartID(), "TL" + IntegerToString(object_counter), OBJPROP_SELECTABLE, false);
   object_counter += 1;
   return "TL" + IntegerToString(object_counter - 1);
   }
//+------------------------------------------------------------------+
//|                       average body size                          |
//+------------------------------------------------------------------+
double average_body_size(int _period)
   {
   double _sum = 0;
   for (int i = _period; i >= 1; i--)
      {
      _sum += MathAbs(iOpen(Symbol(), PERIOD_CURRENT, i) - iClose(Symbol(), PERIOD_CURRENT, i));
      }
   return _sum / _period;
   }
//+------------------------------------------------------------------+
//|                      set initial position lines                  |
//+------------------------------------------------------------------+
void set_initial_position_lines_function()
{
   if(step != 0)
      return;

   //====================================================
   // BOLLINGER SETUP
   //====================================================
   if(setup_type == SETUP_BOLLINGER)
   {
      if ((
         iOpen(Symbol(), PERIOD_CURRENT, 1) < bb_upper[1] &&
         iClose(Symbol(), PERIOD_CURRENT, 1) > bb_upper[1] &&
         ((use_body_percent &&
         MathAbs(iOpen(Symbol(), PERIOD_CURRENT, 1) - iClose(Symbol(), PERIOD_CURRENT, 1)) /
         (iHigh(Symbol(), PERIOD_CURRENT, 1) - iLow(Symbol(), PERIOD_CURRENT, 1))
         > body_percent / 100) || !use_body_percent) &&
         ((use_average_body_size &&
         MathAbs(iOpen(Symbol(), PERIOD_CURRENT, 1) - iClose(Symbol(), PERIOD_CURRENT, 1))
         > average_body_size(period) * coefficient) || !use_average_body_size)
         )
         ||
         (
         iOpen(Symbol(), PERIOD_CURRENT, 1) > bb_lower[1] &&
         iClose(Symbol(), PERIOD_CURRENT, 1) < bb_lower[1] &&
         ((use_body_percent &&
         MathAbs(iOpen(Symbol(), PERIOD_CURRENT, 1) - iClose(Symbol(), PERIOD_CURRENT, 1)) /
         (iHigh(Symbol(), PERIOD_CURRENT, 1) - iLow(Symbol(), PERIOD_CURRENT, 1))
         > body_percent / 100) || !use_body_percent) &&
         ((use_average_body_size &&
         MathAbs(iOpen(Symbol(), PERIOD_CURRENT, 1) - iClose(Symbol(), PERIOD_CURRENT, 1))
         > average_body_size(period) * coefficient) || !use_average_body_size)
         ))
      {
         upper_value = iHigh(Symbol(), PERIOD_CURRENT, 1) + Point();
         lower_value = iLow(Symbol(), PERIOD_CURRENT, 1) - Point();

         upper_line = line_creator(
            upper_value,
            iTime(Symbol(), PERIOD_CURRENT, 1),
            upper_value,
            iTime(Symbol(), PERIOD_CURRENT, 1) + 5 * PeriodSeconds(PERIOD_CURRENT),
            clrOrange,
            STYLE_SOLID,
            2
         );

         lower_line = line_creator(
            lower_value,
            iTime(Symbol(), PERIOD_CURRENT, 1),
            lower_value,
            iTime(Symbol(), PERIOD_CURRENT, 1) + 5 * PeriodSeconds(PERIOD_CURRENT),
            clrOrange,
            STYLE_SOLID,
            2
         );

         step = 1;
      }
   }

   //====================================================
   // MOTHER-INSIDE-OUTSIDE SETUP
   //====================================================
   else if(setup_type == SETUP_MOTHER_INSIDE_OUTSIDE)
   {
      if(detect_mother_inside_outside())
      {
         upper_line = line_creator(
            upper_value,
            iTime(Symbol(), PERIOD_CURRENT, 1),
            upper_value,
            iTime(Symbol(), PERIOD_CURRENT, 1) + 5 * PeriodSeconds(PERIOD_CURRENT),
            clrOrange,
            STYLE_SOLID,
            2
         );

         lower_line = line_creator(
            lower_value,
            iTime(Symbol(), PERIOD_CURRENT, 1),
            lower_value,
            iTime(Symbol(), PERIOD_CURRENT, 1) + 5 * PeriodSeconds(PERIOD_CURRENT),
            clrOrange,
            STYLE_SOLID,
            2
         );

         step = 1;
      }
   }
}

//+------------------------------------------------------------------+
//|                   open position                                  |
//+------------------------------------------------------------------+
void open_first_step_position_function()
   {
   if (step == 1)
      {
      
      if(!is_trading_time()) // check allowed hours for trading
         return;
         
         
      //buy
      if (SymbolInfoDouble(Symbol(), SYMBOL_ASK) >= upper_value)
         {
         int stop_level = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
         
         double _entry = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         double _sl = MathMin(lower_value, SymbolInfoDouble(Symbol(), SYMBOL_BID) - stop_level * Point() - Point());
         int _sl_in_point = (int)MathFloor((_entry - _sl) / Point());
         double _tp = 0;
         
         if (rr1 <= 0)
            {
            _tp = 0;
            }
         else if (rr1 > 0)
            {
            _tp = MathMax(_entry + (_entry - _sl) * rr1, _entry + stop_level * Point() + Point());
            }
         
         double lot = 0;
         
         if (volume_option == v0)
            {
            if (volumep1 != 0)
               {
               lot = NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE) * (volumep1 / 100)) / (_sl_in_point * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE)), 2);
               
               //final controls
               if (lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN))
                  {
                  lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
                  }
               if (lot > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX))
                  {
                  lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
                  }
               lot = MathFloor(lot / SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP)) * SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
               }
            else if (volumep1 == 0)
               {
               step = 2;
               position_type = "buy";
               position_sl = _sl;
               position_tp = _tp;
               position_ticket = -1;
               }
            }
         else if (volume_option == v1)
            {
            if (volume1 != 0)
               {
               lot = volume1;
               }
            else if (volume1 == 0)
               {
               step = 2;
               position_type = "buy";
               position_sl = _sl;
               position_tp = _tp;
               position_ticket = -1;
               }
            }
            
         if (step == 1)
            {
            if (trade.Buy(lot, Symbol(), _entry, _sl, _tp, trade_comment))
               {
               step = 2;
               position_type = "buy";
               position_sl = _sl;
               position_tp = _tp;
               position_ticket = trade.ResultOrder();
               }
            }
         }
      
      //sell
      if (SymbolInfoDouble(Symbol(), SYMBOL_BID) <= lower_value)
         {
         int stop_level = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
         
         double _entry = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double _sl = MathMax(upper_value, SymbolInfoDouble(Symbol(), SYMBOL_ASK) + stop_level * Point() + Point());
         int _sl_in_point = (int)MathFloor((_sl - _entry) / Point());
         double _tp = 0;
         
         if (rr1 <= 0)
            {
            _tp = 0;
            }
         else if (rr1 > 0)
            {
            _tp = MathMin(_entry - (_sl - _entry) * rr1, _entry - stop_level * Point() - Point());
            }
         
         double lot = 0;
         
         if (volume_option == v0)
            {
            if (volumep1 != 0)
               {
               lot = NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE) * (volumep1 / 100)) / (_sl_in_point * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE)), 2);
               
               //final controls
               if (lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN))
                  {
                  lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
                  }
               if (lot > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX))
                  {
                  lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
                  }
               lot = MathFloor(lot / SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP)) * SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
               }
            else if (volumep1 == 0)
               {
               step = 2;
               position_type = "sell";
               position_sl = _sl;
               position_tp = _tp;
               position_ticket = -1;
               }
            }
         else if (volume_option == v1)
            {
            if (volume1 != 0)
               {
               lot = volume1;
               }
            else if (volume1 == 0)
               {
               step = 2;
               position_type = "sell";
               position_sl = _sl;
               position_tp = _tp;
               position_ticket = -1;
               }
            }
            
         if (step == 1)
            {
            if (trade.Sell(lot, Symbol(), _entry, _sl, _tp, trade_comment))
               {
               step = 2;
               position_type = "sell";
               position_sl = _sl;
               position_tp = _tp;
               position_ticket = trade.ResultOrder();
               }
            }
         }
      }
   }
//+------------------------------------------------------------------+
//|                 open next steps                                  |
//+------------------------------------------------------------------+
void open_next_steps_function()
   {
   int i_step = step;
   
   if (step >= 2 && step < 9)
      {
      if (is_tp_sl_touched_function(position_ticket) == "sl")
         {
         //buy
         if (position_type == "buy")
            {
            int stop_level = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
         
            double _entry = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            double _sl = MathMax(upper_value, SymbolInfoDouble(Symbol(), SYMBOL_ASK) + stop_level * Point() + Point());
            int _sl_in_point = (int)MathFloor((_sl - _entry) / Point());
            double _tp = 0;
            
            if (rr_list[step - 1] <= 0)
               {
               _tp = 0;
               }
            else if (rr_list[step - 1] > 0)
               {
               _tp = MathMin(_entry - (_sl - _entry) * rr_list[step - 1], _entry - stop_level * Point() - Point());
               }

            double lot = 0;
            
            if (volume_option == v0)
               {
               if (volume_P[step - 1] != 0)
                  {
                  lot = NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE) * (volume_P[step - 1] / 100)) / (_sl_in_point * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE)), 2);
                  
                  //final controls
                  if (lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN))
                     {
                     lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
                     }
                  if (lot > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX))
                     {
                     lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
                     }
                  lot = MathFloor(lot / SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP)) * SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
                  }
               else if (volume_P[step - 1] == 0)
                  {
                  step += 1;
                  position_type = "sell";
                  position_sl = _sl;
                  position_tp = _tp;
                  position_ticket = -1;
                  }
               }
            else if (volume_option == v1)
               {
               if (volume_L[step - 1] != 0)
                  {
                  lot = volume_L[step - 1];
                  }
               else if (volume_L[step - 1] == 0)
                  {
                  step += 1;
                  position_type = "sell";
                  position_sl = _sl;
                  position_tp = _tp;
                  position_ticket = -1;
                  }
               }
               
            if (step == i_step)
               {
               if (trade.Sell(lot, Symbol(), _entry, _sl, _tp, trade_comment))
                  {
                  step += 1;
                  position_type = "sell";
                  position_sl = _sl;
                  position_tp = _tp;
                  position_ticket = trade.ResultOrder();
                  }
               }
            }
         
         //sell
         else if (position_type == "sell")
            {
            int stop_level = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
         
            double _entry = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            double _sl = MathMin(lower_value, SymbolInfoDouble(Symbol(), SYMBOL_BID) - stop_level * Point() - Point());
            int _sl_in_point = (int)MathFloor((_entry - _sl) / Point());
            double _tp = 0;
            
            if (rr_list[step - 1] <= 0)
               {
               _tp = 0;
               }
            else if (rr_list[step - 1] > 0)
               {
               _tp = MathMax(_entry + (_entry - _sl) * rr_list[step - 1], _entry + stop_level * Point() + Point());
               }
            
            double lot = 0;
            
            if (volume_option == v0)
               {
               if (volume_P[step - 1] != 0)
                  {
                  lot = NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE) * (volume_P[step - 1] / 100)) / (_sl_in_point * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE)), 2);
                  
                  //final controls
                  if (lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN))
                     {
                     lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
                     }
                  if (lot > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX))
                     {
                     lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
                     }
                  lot = MathFloor(lot / SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP)) * SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
                  }
               else if (volume_P[step - 1] == 0)
                  {
                  step += 1;
                  position_type = "buy";
                  position_sl = _sl;
                  position_tp = _tp;
                  position_ticket = -1;
                  }
               }
            else if (volume_option == v1)
               {
               if (volume_L[step - 1] != 0)
                  {
                  lot = volume_L[step - 1];
                  }
               else if (volume_L[step - 1] == 0)
                  {
                  step += 1;
                  position_type = "buy";
                  position_sl = _sl;
                  position_tp = _tp;
                  position_ticket = -1;
                  }
               }
               
            if (step == i_step)
               {
               if (trade.Buy(lot, Symbol(), _entry, _sl, _tp, trade_comment))
                  {
                  step += 1;
                  position_type = "buy";
                  position_sl = _sl;
                  position_tp = _tp;
                  position_ticket = trade.ResultOrder();
                  }
               }
            }
         }
         
      if (is_tp_sl_touched_function(position_ticket) == "tp")
         {
         step = -1;
         position_type = NULL;
         position_sl = NULL;
         position_tp = NULL;
         position_ticket = NULL;
         }
      }
   
   else if (step >= 9 && (is_tp_sl_touched_function(position_ticket) == "tp" || is_tp_sl_touched_function(position_ticket) == "sl"))
      {
      step = -1;
      position_type = NULL;
      position_sl = NULL;
      position_tp = NULL;
      position_ticket = NULL;
      }
   }
//+------------------------------------------------------------------+
//|                 is tp touched                                    |
//+------------------------------------------------------------------+
string is_tp_sl_touched_function(ulong _ticket)
   {
   if(!HistorySelect(0, TimeCurrent()))
      {
      return "nan";
      }
   
   ulong deal_ticket;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
      {
      deal_ticket = HistoryDealGetTicket(i);
      
      ulong order_ticket = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
      
      if(order_ticket != _ticket)
         {
         continue;
         }
         
      int reason = (int)HistoryDealGetInteger(deal_ticket, DEAL_REASON);
      if(reason == DEAL_REASON_SL)
         {
         return "sl";
         }
      else if (reason == DEAL_REASON_TP)
         {
         return "tp";
         }
      }
      
   if (_ticket == -1)
      {
      if (position_type == "buy")
         {
         if (SymbolInfoDouble(Symbol(), SYMBOL_BID) <= position_sl)
            {
            return "sl";
            }
         if (SymbolInfoDouble(Symbol(), SYMBOL_BID) >= position_tp)
            {
            return "tp";
            }
         }
      if (position_type == "sell")
         {
         if (SymbolInfoDouble(Symbol(), SYMBOL_ASK) >= position_sl)
            {
            return "sl";
            }
         if (SymbolInfoDouble(Symbol(), SYMBOL_ASK) <= position_tp)
            {
            return "tp";
            }
         }
      }
      
   return "nan";
   }
//+------------------------------------------------------------------+
//|                   step 0                                         |
//+------------------------------------------------------------------+
void step_zero_function()
   {
   if (step_zero_controler != iTime(Symbol(), PERIOD_CURRENT, 0))
      {
      step_zero_controler = iTime(Symbol(), PERIOD_CURRENT, 0);
      
      if (step == -1)
         {
         step = 0;
         }
      }
   }


bool is_momentum_candle(int shift)
{
   double body =
   MathAbs(
      iOpen(Symbol(),PERIOD_CURRENT,shift) -
      iClose(Symbol(),PERIOD_CURRENT,shift)
   );


   double range =
   iHigh(Symbol(),PERIOD_CURRENT,shift) -
   iLow(Symbol(),PERIOD_CURRENT,shift);


   // جلوگیری از تقسیم بر صفر
   if(range <= 0)
      return false;


   bool body_ok =
   (
      (use_body_percent &&
       body / range > body_percent / 100.0)
      ||
      !use_body_percent
   );


   bool average_ok =
   (
      (use_average_body_size &&
       body > average_body_size(period)*coefficient)
      ||
      !use_average_body_size
   );


   return body_ok && average_ok;
}


bool detect_mother_inside_outside()
{

   int mother = 3;


   double mother_high =
   iHigh(Symbol(),PERIOD_CURRENT,mother);


   double mother_low =
   iLow(Symbol(),PERIOD_CURRENT,mother);



   // inside bar
   bool inside =
   (
      iHigh(Symbol(),PERIOD_CURRENT,2) <= mother_high &&
      iLow(Symbol(),PERIOD_CURRENT,2) >= mother_low
   );


   if(!inside)
      return false;
      
   Print("Inside Found");


   // outside bar
   bool outside =
   (
      iHigh(Symbol(),PERIOD_CURRENT,1) >
      iHigh(Symbol(),PERIOD_CURRENT,2)

      ||

      iLow(Symbol(),PERIOD_CURRENT,1) <
      iLow(Symbol(),PERIOD_CURRENT,2)
   );

   
   if(!outside)
      return false;
   
   Print("Outside Found");


   // momentum
   if(!is_momentum_candle(1))
      return false;

   Print("Momentum Found");
   
   
   upper_value =
   iHigh(Symbol(),PERIOD_CURRENT,1)+Point();


   lower_value =
   iLow(Symbol(),PERIOD_CURRENT,1)-Point();


   return true;
}



bool is_trading_time()
{
   if(!use_trading_time)
      return true;

   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);

   int hour = tm.hour;

   if(trading_start_hour <= trading_end_hour)
   {
      return (hour >= trading_start_hour &&
              hour < trading_end_hour);
   }
   else
   {
      return (hour >= trading_start_hour ||
              hour < trading_end_hour);
   }
}