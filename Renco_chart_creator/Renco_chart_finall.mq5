//+------------------------------------------------------------------+
//| Renko_ATR_MultiTF.mq5                                            |
//| Dual Independent Renko Charts                                    |
//| TradingView Style Reversal                                       |
//+------------------------------------------------------------------+
#property strict
#property version   "6.00"
#property copyright "Developed by @Fardin76m"
//-------------------------------------------------------------------
// INPUTS
//-------------------------------------------------------------------
input group "=== RENKO #1 ==="

input ENUM_TIMEFRAMES InpSourceTF1       = PERIOD_M2;
input int             InpATRPeriod1      = 14;
input double          InpATRMultiplier1  = 0.9;
input bool            InpShowWicks1      = false;
input string          InpCustomName1     = "";

input group "=== RENKO #2 ==="

input ENUM_TIMEFRAMES InpSourceTF2       = PERIOD_M15;
input int             InpATRPeriod2      = 14;
input double          InpATRMultiplier2  = 0.9;
input bool            InpShowWicks2      = false;
input string          InpCustomName2     = "";

input group "=== GENERAL ==="

input int             InpMaxBricks       = 5000;
input bool            InpOpenCharts      = true;

//-------------------------------------------------------------------
// STRUCT
//-------------------------------------------------------------------
struct RenkoBrick
{
   datetime time;
   double   open;
   double   high;
   double   low;
   double   close;
};

//-------------------------------------------------------------------
// TF TO STRING
//-------------------------------------------------------------------
string TFToString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";
      case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";
      case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";
      case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";
      case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";

      case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";
      case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";
      case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";
      case PERIOD_H12: return "H12";

      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
   }

   return "TF";
}

//-------------------------------------------------------------------
// CLASS
//-------------------------------------------------------------------
class CRenkoGenerator
{
public:

   string symbolName;

   ENUM_TIMEFRAMES sourceTF;

   int    atrPeriod;
   double atrMultiplier;

   bool   showWicks;

   int    atrHandle;

   double renkoLevel;

   bool   lastBull;

   long   chartID;

   RenkoBrick bricks[];

   //---------------------------------------------------------------
   // INIT
   //---------------------------------------------------------------
   bool Init(
      string customName,
      ENUM_TIMEFRAMES tf,
      int atrP,
      double atrM,
      bool wicks
   )
   {
      sourceTF      = tf;
      atrPeriod     = atrP;
      atrMultiplier = atrM;
      showWicks     = wicks;

      lastBull = true;

      //------------------------------------------------------------
      // AUTO SYMBOL NAME
      //------------------------------------------------------------
      string tfName = TFToString(sourceTF);

      if(StringLen(customName) <= 0)
      {
         symbolName =
            _Symbol
            + "_RENKO_"
            + tfName;
      }
      else
      {
         symbolName =
            _Symbol
            + "_"
            + customName;
      }

      //------------------------------------------------------------
      // ATR
      //------------------------------------------------------------
      atrHandle =
         iATR(
            _Symbol,
            sourceTF,
            atrPeriod
         );

      if(atrHandle == INVALID_HANDLE)
      {
         Print("ATR Handle Error");
         return false;
      }

      //------------------------------------------------------------
      // CREATE CUSTOM SYMBOL
      //------------------------------------------------------------
      bool isCustom;

      if(!SymbolExist(symbolName,isCustom))
      {
         if(!CustomSymbolCreate(
               symbolName,
               SymbolInfoString(
                  _Symbol,
                  SYMBOL_PATH
               ),
               _Symbol))
         {
            Print(
               "CustomSymbolCreate Error: ",
               GetLastError()
            );

            return false;
         }
      }

      //------------------------------------------------------------
      // SYMBOL SETTINGS
      //------------------------------------------------------------
      CustomSymbolSetInteger(
         symbolName,
         SYMBOL_DIGITS,
         (int)SymbolInfoInteger(
            _Symbol,
            SYMBOL_DIGITS
         )
      );

      CustomSymbolSetDouble(
         symbolName,
         SYMBOL_POINT,
         SymbolInfoDouble(
            _Symbol,
            SYMBOL_POINT
         )
      );

      //------------------------------------------------------------
      // BUILD HISTORY
      //------------------------------------------------------------
      BuildHistory();

      //------------------------------------------------------------
      // OPEN CHART
      //------------------------------------------------------------
      if(InpOpenCharts)
      {
         chartID =
            ChartOpen(
               symbolName,
               PERIOD_M1
            );
      }

      Print("Created Renko: ",symbolName);

      return true;
   }

   //---------------------------------------------------------------
   // GET BRICK SIZE
   //---------------------------------------------------------------
   double GetBrickSize()
   {
      double atr[];

      ArraySetAsSeries(atr,true);

      if(CopyBuffer(
            atrHandle,
            0,
            0,
            1,
            atr
         ) <= 0)
      {
         return
            SymbolInfoDouble(
               _Symbol,
               SYMBOL_POINT
            ) * 10;
      }

      return atr[0] * atrMultiplier;
   }

   //---------------------------------------------------------------
   // BUILD HISTORY
   //---------------------------------------------------------------
   void BuildHistory()
   {
      ArrayResize(bricks,0);

      int total =
         Bars(
            _Symbol,
            sourceTF
         );

      if(total < atrPeriod + 50)
         return;

      int start = total - 500;

      if(start < 1)
         start = 1;

      double bs = GetBrickSize();

      if(bs <= 0)
         return;

      double firstPrice =
         iClose(
            _Symbol,
            sourceTF,
            start
         );

      renkoLevel =
         MathFloor(firstPrice / bs)
         * bs;

      //------------------------------------------------------------
      // BUILD
      //------------------------------------------------------------
      for(int i=start;i>=0;i--)
      {
         double price =
            iClose(
               _Symbol,
               sourceTF,
               i
            );

         while(true)
         {
            double bullThreshold =
               lastBull ? bs : bs * 2.0;

            double bearThreshold =
               lastBull ? bs * 2.0 : bs;

            //-----------------------------------------------------
            // BULL
            //-----------------------------------------------------
            if(price >= renkoLevel + bullThreshold)
            {
               double newClose =
                  renkoLevel + bs;

               AddBrick(
                  renkoLevel,
                  newClose,
                  true
               );

               renkoLevel = newClose;

               continue;
            }

            //-----------------------------------------------------
            // BEAR
            //-----------------------------------------------------
            if(price <= renkoLevel - bearThreshold)
            {
               double newClose =
                  renkoLevel - bs;

               AddBrick(
                  renkoLevel,
                  newClose,
                  false
               );

               renkoLevel = newClose;

               continue;
            }

            break;
         }
      }

      //------------------------------------------------------------
      // UPDATE CHART
      //------------------------------------------------------------
      UpdateChart();
   }

   //---------------------------------------------------------------
   // ADD BRICK
   //---------------------------------------------------------------
   void AddBrick(
      double prevLevel,
      double newClose,
      bool isBull
   )
   {
      int size = ArraySize(bricks);

      ArrayResize(bricks,size+1);

      RenkoBrick brick;

      //------------------------------------------------------------
      // TIME
      //------------------------------------------------------------
      brick.time =
         TimeCurrent()
         + size * 60;

      double bs = GetBrickSize();

      //------------------------------------------------------------
      // FIRST BRICK
      //------------------------------------------------------------
      if(size == 0)
      {
         brick.open  = prevLevel;
         brick.close = newClose;
      }
      else
      {
         //---------------------------------------------------------
         // SAME DIRECTION
         //---------------------------------------------------------
         if(isBull == lastBull)
         {
            brick.open =
               bricks[size-1].close;

            brick.close =
               newClose;
         }
         //---------------------------------------------------------
         // REVERSAL
         //---------------------------------------------------------
         else
         {
            //------------------------------------------------------
            // START FROM PREVIOUS OPEN
            //------------------------------------------------------
            brick.open =
               bricks[size-1].open;

            //------------------------------------------------------
            // FORCE FULL BODY
            //------------------------------------------------------
            brick.close =
               brick.open
               + (isBull ? bs : -bs);
         }
      }

      //------------------------------------------------------------
      // SAFETY
      //------------------------------------------------------------
      double point =
         SymbolInfoDouble(
            _Symbol,
            SYMBOL_POINT
         );

      if(MathAbs(
            brick.close - brick.open
         ) < point)
      {
         brick.close =
            brick.open
            + (isBull ? bs : -bs);
      }

      //------------------------------------------------------------
      // HIGH LOW
      //------------------------------------------------------------
      if(showWicks)
      {
         double body =
            MathAbs(
               brick.close - brick.open
            );

         if(isBull)
         {
            brick.high =
               MathMax(
                  brick.open,
                  brick.close
               );

            brick.low =
               MathMin(
                  brick.open,
                  brick.close
               ) - body * 0.4;
         }
         else
         {
            brick.high =
               MathMax(
                  brick.open,
                  brick.close
               ) + body * 0.4;

            brick.low =
               MathMin(
                  brick.open,
                  brick.close
               );
         }
      }
      else
      {
         brick.high =
            MathMax(
               brick.open,
               brick.close
            );

         brick.low =
            MathMin(
               brick.open,
               brick.close
            );
      }

      //------------------------------------------------------------
      // SAVE
      //------------------------------------------------------------
      bricks[size] = brick;

      lastBull = isBull;

      //------------------------------------------------------------
      // LIMIT
      //------------------------------------------------------------
      if(ArraySize(bricks) > InpMaxBricks)
      {
         for(int i=0;i<ArraySize(bricks)-1;i++)
            bricks[i] = bricks[i+1];

         ArrayResize(
            bricks,
            ArraySize(bricks)-1
         );
      }
   }

   //---------------------------------------------------------------
   // UPDATE CHART
   //---------------------------------------------------------------
   void UpdateChart()
   {
      int total = ArraySize(bricks);

      if(total <= 0)
         return;

      MqlRates rates[];

      ArrayResize(rates,total);

      datetime baseTime =
         TimeCurrent()
         - total * 60;

      for(int i=0;i<total;i++)
      {
         rates[i].time =
            baseTime + i * 60;

         rates[i].open =
            bricks[i].open;

         rates[i].high =
            bricks[i].high;

         rates[i].low =
            bricks[i].low;

         rates[i].close =
            bricks[i].close;

         rates[i].tick_volume = 1;
         rates[i].spread      = 0;
         rates[i].real_volume = 0;
      }

      //------------------------------------------------------------
      // DELETE OLD
      //------------------------------------------------------------
      CustomRatesDelete(
         symbolName,
         0,
         LONG_MAX
      );

      //------------------------------------------------------------
      // UPDATE
      //------------------------------------------------------------
      if(!CustomRatesUpdate(
            symbolName,
            rates
         ))
      {
         Print(
            "CustomRatesUpdate Error: ",
            GetLastError()
         );

         return;
      }

      //------------------------------------------------------------
      // REDRAW
      //------------------------------------------------------------
      if(chartID > 0)
         ChartRedraw(chartID);
   }

   //---------------------------------------------------------------
   // REALTIME UPDATE
   //---------------------------------------------------------------
   void OnTickUpdate()
   {
      double price =
         SymbolInfoDouble(
            _Symbol,
            SYMBOL_BID
         );

      double brickSize =
         GetBrickSize();

      if(brickSize <= 0)
         return;

      bool updated = false;

      while(true)
      {
         double bullThreshold =
            lastBull
            ? brickSize
            : brickSize * 2.0;

         double bearThreshold =
            lastBull
            ? brickSize * 2.0
            : brickSize;

         //---------------------------------------------------------
         // BULL
         //---------------------------------------------------------
         if(price >= renkoLevel + bullThreshold)
         {
            double newClose =
               renkoLevel + brickSize;

            AddBrick(
               renkoLevel,
               newClose,
               true
            );

            renkoLevel = newClose;

            updated = true;

            continue;
         }

         //---------------------------------------------------------
         // BEAR
         //---------------------------------------------------------
         if(price <= renkoLevel - bearThreshold)
         {
            double newClose =
               renkoLevel - brickSize;

            AddBrick(
               renkoLevel,
               newClose,
               false
            );

            renkoLevel = newClose;

            updated = true;

            continue;
         }

         break;
      }

      if(updated)
         UpdateChart();
   }
};

//-------------------------------------------------------------------
// GLOBAL OBJECTS
//-------------------------------------------------------------------
CRenkoGenerator Renko1;
CRenkoGenerator Renko2;

//+------------------------------------------------------------------+
//| INIT                                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   bool ok1 =
      Renko1.Init(
         InpCustomName1,
         InpSourceTF1,
         InpATRPeriod1,
         InpATRMultiplier1,
         InpShowWicks1
      );

   bool ok2 =
      Renko2.Init(
         InpCustomName2,
         InpSourceTF2,
         InpATRPeriod2,
         InpATRMultiplier2,
         InpShowWicks2
      );

   if(!ok1 || !ok2)
      return INIT_FAILED;

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| DEINIT                                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| TICK                                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   Renko1.OnTickUpdate();

   Renko2.OnTickUpdate();
}
//+------------------------------------------------------------------+