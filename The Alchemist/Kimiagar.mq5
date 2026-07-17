//+------------------------------------------------------------------+
//|                    Kimiagar Indicator                            |


#property strict
#property indicator_chart_window


//========================================================
//Setup_Selection : Upper/Middle Setup
//========================================================

input string  __SETUP_SELECTION = "========== Upper/Middle Setup ==========";

input bool EnableUpperBandSetup  = true;
input bool EnableMiddleBandSetup = true;

// for handling conditions for middle / upper setups
enum SetupType
{
   SETUP_UPPER = 0,
   SETUP_MIDDLE = 1
};



//========================================================
// GENERAL
//========================================================
input string  __GENERAL = "========== GENERAL ==========";

input ENUM_TIMEFRAMES SignalTF = PERIOD_CURRENT;


// drawing inputs
input int HistoryScanBars = 10000;

input int MaxSignalBars = 1000;
input int MaxZoneBars = 200;
input int ArrowDistancePoints = 30;

//========================================================
// ALERT
//========================================================
input string  __ALERT = "========== ALERT ==========";
input bool EnablePopupAlert = true;
input bool EnableSoundAlert = true;



// ALERT
//========================================================
input string  __SIGNALZONE = "========== SIGNAL ZONE ==========";
/// avoiding repetetive signals

datetime LastSellSignalBar = 0;
//========================================================
// SIGNAL ZONE
//========================================================
input bool  ShowSignalZone   = true;
input color SignalZoneColor  = clrRed;
input int   SignalZoneBars   = 1;   // تعداد کندل قبل و بعد





//========================================================
// BOLLINGER BAND
//========================================================
input string  __BB = "========== BOLLINGER BAND ==========";


//==================================================================
// تنظیمات بولینگر
//==================================================================
input int      BB_Period            = 20;
input double   BB_Deviation         = 2.0;
input int      BB_Shift             = 0;

// درصد تلرانس برخورد به باند
input double   BB_TolerancePercent  = 10.0;
input bool Show_Bollinger_On_Chart = true;


//========================================================
// RSI - UPPER SETUP
//========================================================
input string  __RSI_UPPER = "========== RSI UPPER SETUP ==========";
//==================================================================
// تنظیمات RSI ستاپ باند بالا
//==================================================================
input int      RSI_Period_Upper      = 14;
input double   RSI_Level1_Upper      = 70;
input double   RSI_Level0_Upper      = 70;
input ENUM_APPLIED_PRICE RSI_ApplyTo_Upper = PRICE_CLOSE;


//========================================================
// RSI - MIDDLE SETUP
//========================================================
input string  __RSI_MIDDLE = "========== RSI MIDDLE SETUP ==========";

// RSI Levels - Middle Setup
input int      RSI_Period_Middle    = 14;
input double   RSI_Level1_Middle    = 50.0;
input double   RSI_Level0_Middle    = 50.0;
input ENUM_APPLIED_PRICE RSI_ApplyTo_Middle = PRICE_CLOSE;

// فعال/غیرفعال شرط 3
input bool     Use_RSI_Condition3    = true;




//==================================================================
// شرط 4
//==================================================================
input string  __COND4 = "========== CONDITION 4 ==========";

input bool     Use_HighCondition     = true;
input double   HighPercentLimit      = 20.0;


//==================================================================
// شرط 5
// RSI کندل صفر حداکثر X درصد RSI کندل 1
// مثال:
// RSI1 = 50
// X = 80
// RSI0 <= 40

//========================================================
input string  __COND5 = "========== CONDITION 5 ==========";

//==================================================================
input bool     Use_RSIPercentLimit   = true;
input double   RSI_PercentLimit      = 80.0;


//==================================================================
// شرط 6
//==================================================================
input string  __COND6 = "========== CONDITION 4 OR 5 ==========";

input bool     Use_OR_Condition45    = true;


//==================================================================
// تنظیمات ZigZag تایم فریم فعلی
//==================================================================
//========================================================
// ZIGZAG CURRENT TF
//========================================================
input string  __ZZ1 = "========== ZIGZAG CURRENT TF ==========";

//==================================================================
// ZigZag Handle
//==================================================================
int ZigZag_Handle;
int ZigZag_Handle_HTF;

input bool     Use_Zigzag_CurrentTF  = true;

input int      Zigzag_Depth          = 12;
input int      Zigzag_Deviation      = 5;
input int      Zigzag_Backstep       = 3;

input double   ZigzagTolerancePercent = 10.0;

input bool Show_ZigZag_CurrentTF = false;
input bool Show_ZigZag_HTF       = false;

input bool Show_HTF_ZigZag_Levels = false;

input color HTF_High_Color = clrRed;
input color HTF_Low_Color = clrBlue;
input color HTF_MaxAllowed_Color = clrOrange;




//==================================================================
// تنظیمات ZigZag تایم فریم دوم
//==================================================================
// ZIGZAG HIGHER TF
//========================================================
input string  __ZZ2 = "========== ZIGZAG HIGHER TF ==========";

input bool     Use_Zigzag_HTF        = true;

input ENUM_TIMEFRAMES ZigzagHTF = PERIOD_H1;


//==================================================================
// شرط OR بین 7 و 8
//==================================================================
input string  __COND9 = "========== CONDITION 7 OR 8 ==========";

input bool     Use_OR_Condition78 = true;


//==================================================================
// شرط 10
//==================================================================
//========================================================
input string  __COND10 = "========== CONDITION 10 ==========";

input bool   Use_OpenPriceFilter = true;

input double Condition10_Percent = 80.0;


//==================================================================
// تنظیمات ستاپ لاین وسط
//==================================================================
// MIDDLE BAND SETUP
//========================================================
input string  __MIDDLE = "========== MIDDLE BAND SETUP ==========";

input bool     Use_BB_MiddleSlope = true;
input bool     Use_PriceSlope     = true;
input bool     Use_OR_Slope       = true;


//==================================================================
// هندل ها
//==================================================================
int BB_Handle;
int RSI_Handle_Upper;
int RSI_Handle_Middle;


//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{  

   if(SignalTF == PERIOD_CURRENT)
   {
      ObjectsDeleteAll(0,"SELL_");
      ObjectsDeleteAll(0,"ZONE_");
   }
   
   
   BB_Handle =
      iBands(_Symbol,SignalTF,BB_Period,BB_Shift,BB_Deviation,PRICE_CLOSE);

   RSI_Handle_Upper =
      iRSI(_Symbol,SignalTF,RSI_Period_Upper,RSI_ApplyTo_Upper);

   RSI_Handle_Middle =
      iRSI(_Symbol,SignalTF,RSI_Period_Middle,RSI_ApplyTo_Middle);
           
   ZigZag_Handle =
      iCustom(_Symbol,SignalTF,"Examples\\ZigZag",Zigzag_Depth,Zigzag_Deviation,Zigzag_Backstep);
      
   
   ZigZag_Handle_HTF =
      iCustom(_Symbol,ZigzagHTF,"Examples\\ZigZag",Zigzag_Depth,Zigzag_Deviation, Zigzag_Backstep);
      
      
   if(BB_Handle == INVALID_HANDLE)
   {
      //Print("Failed to create Bollinger handle");
      return(INIT_FAILED);
   }
   
   if(Show_Bollinger_On_Chart)
   {
      ChartIndicatorAdd(ChartID(),0,BB_Handle);
   };

   if(RSI_Handle_Upper == INVALID_HANDLE)
   {
      //Print("Failed to create RSI Upper handle");
      return(INIT_FAILED);
   }

   if(RSI_Handle_Middle == INVALID_HANDLE)
   {
      //Print("Failed to create RSI Middle handle");
      return(INIT_FAILED);
   }  

   if(ZigZag_Handle_HTF == INVALID_HANDLE)
   {
      //Print("Failed to create HTF ZigZag handle");
      return(INIT_FAILED);
      
      
   }
   if(Show_ZigZag_CurrentTF)
   {
      ChartIndicatorAdd(
         ChartID(),
         0,
         ZigZag_Handle
      );
   }
   
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| شرط 1 ستاپ باند بالا                                             |
//| Check Bollinger Upper Band Touch                                 |
//+------------------------------------------------------------------+
// touch 1    no touch 0 tolerance touch 2

int Condition1_BBTouch(
      int shift,
      SetupType setup
   )
{
   double upperBand[];
   double middleBand[];
   double lowerBand[];

   ArraySetAsSeries(upperBand,true);
   ArraySetAsSeries(middleBand,true);
   ArraySetAsSeries(lowerBand,true);

   if(CopyBuffer(BB_Handle,1,shift,2,upperBand)<=0)
      return(0);

   if(CopyBuffer(BB_Handle,0,shift,2,middleBand)<=0)
      return(0);

   if(CopyBuffer(BB_Handle,2,shift,2,lowerBand)<=0)
      return(0);

   //--------------------------------------------------
   // قیمت کندل
   //--------------------------------------------------

   double candleHigh =
      iHigh(_Symbol,SignalTF,shift);

   //--------------------------------------------------
   // انتخاب باند مورد نظر
   //--------------------------------------------------

   double targetBand;
   double bandDistance;

   if(setup==SETUP_UPPER)
   {
      // Upper Setup
      targetBand   = upperBand[0];
      bandDistance = upperBand[0]-middleBand[0];
   }
   else
   {
      // Middle Setup
      targetBand   = middleBand[0];
      bandDistance = middleBand[0]-lowerBand[0];
   }

   //--------------------------------------------------
   // برخورد مستقیم
   //--------------------------------------------------

   if(candleHigh>=targetBand)
      return(2);

   //--------------------------------------------------
   // برخورد با تلورانس
   //--------------------------------------------------

   double toleranceDistance =
      bandDistance *
      BB_TolerancePercent /
      100.0;

   double toleranceLevel =
      targetBand -
      toleranceDistance;

   if(candleHigh>=toleranceLevel)
      return(22);

   return(0);
}


//+------------------------------------------------------------------+
//| شرط 2
//| Check RSI of candle #1                                            |
//+------------------------------------------------------------------+
// 2 sell 0 nothing

int Condition2_RSIBar1(int shift, int rsiHandle,double level)
{
   double rsiBuffer[];

   ArraySetAsSeries(rsiBuffer,true);

   if(CopyBuffer(
         rsiHandle,
         0,
         shift,
         3,
         rsiBuffer) <= 0)
   {
      return(0);
   }

   double rsiBar1 = rsiBuffer[1];

   if(rsiBar1 < level)
      return(2);

   return(0);
}


//+------------------------------------------------------------------+
//| شرط 3                                                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Check RSI of candle #0                                            |
//+------------------------------------------------------------------+
// Condition 3:
// Check whether RSI of candle #0 is below the user-defined level.
//
// Candle #0 = current candle.
//
// Note:
// The enable/disable logic and the mandatory check for
// Bollinger tolerance touches will be handled later
// in the main setup evaluation function.

int Condition3_RSIBar0(int shift,int rsiHandle, double level)
{
   double rsiBuffer[];

   ArraySetAsSeries(rsiBuffer,true);

   if(CopyBuffer(
         rsiHandle,
         0,
         shift,
         2,
         rsiBuffer) <= 0)
   {
      return(0);
   }

   double rsiBar0 = rsiBuffer[0];

   if(rsiBar0 < level)
      return(2);

   return(0);
}

//+------------------------------------------------------------------+
//| شرط 4                                                           |
//+------------------------------------------------------------------+
// Condition 4:
// Check whether the high of candle #0 exceeds the high of
// candle #1 by no more than a user-defined percentage
// of candle #1 length.
//
// CandleLength1 = High[1] - Low[1]
//
// Valid if:
// High[0] <= High[1] + (CandleLength1 * Percent / 100)

int Condition4_HighLimit(int shift)
{
   double High0 =
      iHigh(NULL,SignalTF,shift);

   double High1 =
      iHigh(NULL,SignalTF,shift+1);

   double Low1 =
      iLow(NULL,SignalTF,shift+1);

   double candleLength1 = High1 - Low1;

   if(candleLength1 <= 0)
      return(0);

   double allowedDistance = candleLength1 * HighPercentLimit / 100.0;

   if(High0 <= High1 + allowedDistance)
      return(2);

   return(0);
}



//+------------------------------------------------------------------+
//| شرط 5                                                           |
//+------------------------------------------------------------------+


// Condition 5:
// Check whether RSI of candle #0 is less than or equal to
// a user-defined percentage of RSI of candle #1.
//
// Example:
// RSI[1] = 50
// Percent = 80
//
// Maximum allowed RSI[0] = 40
//
// Valid if:
// RSI[0] <= RSI[1] * (Percent / 100)

int Condition5_RSIPercent(int shift)
{
   double rsiBuffer[];

   ArraySetAsSeries(rsiBuffer,true);

   if(CopyBuffer(
         RSI_Handle_Upper,
         0,
         shift,
         3,
         rsiBuffer) <= 0)
   {
      return(0);
   }

   double rsiBar0 = rsiBuffer[0];
   double rsiBar1 = rsiBuffer[1];

   double maxAllowedRSI =rsiBar1 * RSI_PercentLimit / 100.0;

   if(rsiBar0 <= maxAllowedRSI)
      return(2);

   return(0);
}


//+------------------------------------------------------------------+
//| شرط 6                                                           |
//+------------------------------------------------------------------+
// Condition 6:
// Logical OR between Condition 4 and Condition 5.
//
// Valid if at least one of the following is true:
// - Condition 4 (High limit)
// - Condition 5 (RSI percentage limit)
//
// Result:
// Condition4 || Condition5

//+------------------------------------------------------------------+
//| Condition 6                                                      |
//+------------------------------------------------------------------+
int Condition6_OR45(int shift)
{
   bool cond4 = Condition4_HighLimit(shift);
   bool cond5 = Condition5_RSIPercent(shift);

   if(cond4 || cond5)
      return(2);

   return(0);
}

//+------------------------------------------------------------------+
//| شرط 7                                                           |
//+------------------------------------------------------------------+
// Condition 7:
// Check whether candle #0 high is below or equal to the
// latest ZigZag swing high.
//
// A tolerance above the swing high is allowed.
// The tolerance is calculated as a percentage of the
// previous ZigZag leg length.
//
// Valid if:
// High[0] <= LastSwingHigh + AllowedTolerance
//+------------------------------------------------------------------+
//| Condition 7                                                      |
//+------------------------------------------------------------------+



int Condition7_ZigzagCurrentTF(int shift)
{
   double High0 =
      iHigh(_Symbol, SignalTF, shift);

   double zzBuffer[];

   ArraySetAsSeries(zzBuffer,true);

   //---------------------------------------------------------
   // Read ZigZag buffer
   //---------------------------------------------------------
   if(CopyBuffer(
         ZigZag_Handle,
         0,
         shift,
         500,
         zzBuffer) <= 0)
   {
      return(0);
   }

   //---------------------------------------------------------
   // Find latest swing high BEFORE shift
   //---------------------------------------------------------
   double lastSwingHigh   = 0.0;
   double previousSwingLow = 0.0;

   bool highFound = false;

   for(int i=1; i<500; i++)
   {
      if(zzBuffer[i] == 0.0)
         continue;

      //------------------------------------------------------
      // First swing high
      //------------------------------------------------------
      if(!highFound)
      {
         if(MathAbs(
               zzBuffer[i]
               - iHigh(_Symbol,SignalTF,shift+i)
            ) < (_Point*5))
         {
            lastSwingHigh = zzBuffer[i];
            highFound = true;
         }
      }
      //------------------------------------------------------
      // Previous swing low
      //------------------------------------------------------
      else
      {
         if(MathAbs(
               zzBuffer[i]
               - iLow(_Symbol,SignalTF,shift+i)
            ) < (_Point*5))
         {
            previousSwingLow = zzBuffer[i];
            break;
         }
      }
   }

   //---------------------------------------------------------
   // Validation
   //---------------------------------------------------------
   if(lastSwingHigh <= 0.0)
      return(0);

   if(previousSwingLow <= 0.0)
      return(0);

   //---------------------------------------------------------
   // Last leg length
   //---------------------------------------------------------
   double lastLegLength =
      lastSwingHigh - previousSwingLow;

   if(lastLegLength <= 0)
      return(0);

   //---------------------------------------------------------
   // Allowed tolerance
   //---------------------------------------------------------
   double allowedDistance =
      lastLegLength *
      ZigzagTolerancePercent /
      100.0;

   double maxAllowedHigh =
      lastSwingHigh + allowedDistance;

   //---------------------------------------------------------
   // Final condition
   //---------------------------------------------------------


   if(High0 <= maxAllowedHigh)
      return(2);

   return(0);
}



//+------------------------------------------------------------------+
//| شرط 8                                                           |
//+------------------------------------------------------------------+
// Condition 8:
// Multi-timeframe ZigZag confirmation.
//
// Same logic as Condition 7, but ZigZag is calculated
// on a higher/lower timeframe selected by user.
//
// The condition checks whether candle #0 high is below
// or within tolerance of the last confirmed ZigZag swing
// from the selected timeframe.

int Condition8_ZigzagHigherTF(int shift)
{
   //---------------------------------------------------------
   // Current signal high
   //---------------------------------------------------------
   double High0 =
      iHigh(_Symbol, SignalTF, shift);

   //---------------------------------------------------------
   // Find corresponding HTF bar
   //---------------------------------------------------------
   datetime signalTime =
      iTime(_Symbol, SignalTF, shift);

   int htfShift =
      iBarShift(
         _Symbol,
         ZigzagHTF,
         signalTime,
         false
      );

   if(htfShift < 0)
      return(0);

   //---------------------------------------------------------
   // Read ZigZag HTF buffer
   //---------------------------------------------------------
   double zzBuffer[];

   ArraySetAsSeries(zzBuffer,true);

   if(CopyBuffer(
         ZigZag_Handle_HTF,
         0,
         htfShift,
         500,
         zzBuffer) <= 0)
   {
      return(0);
   }

   //---------------------------------------------------------
   // Find latest swing high
   //---------------------------------------------------------
   double lastSwingHigh    = 0.0;
   double previousSwingLow = 0.0;

   bool highFound = false;

   for(int i=1; i<500; i++)
   {
      if(zzBuffer[i] == 0.0)
         continue;

      //------------------------------------------------------
      // Swing High
      //------------------------------------------------------
      if(!highFound)
      {
         if(
            MathAbs(
               zzBuffer[i]
               -
               iHigh(
                  _Symbol,
                  ZigzagHTF,
                  htfShift + i
               )
            ) < (_Point*5)
         )
         {
            lastSwingHigh = zzBuffer[i];
            highFound = true;
         }
      }
      //------------------------------------------------------
      // Swing Low
      //------------------------------------------------------
      else
      {
         if(
            MathAbs(
               zzBuffer[i]
               -
               iLow(
                  _Symbol,
                  ZigzagHTF,
                  htfShift + i
               )
            ) < (_Point*5)
         )
         {
            previousSwingLow = zzBuffer[i];
            break;
         }
      }
   }

   //---------------------------------------------------------
   // Validation
   //---------------------------------------------------------
   if(lastSwingHigh <= 0.0)
      return(0);

   if(previousSwingLow <= 0.0)
      return(0);

   //---------------------------------------------------------
   // Leg length
   //---------------------------------------------------------
   double lastLegLength =
      lastSwingHigh - previousSwingLow;

   if(lastLegLength <= 0)
      return(0);

   //---------------------------------------------------------
   // Tolerance
   //---------------------------------------------------------
   double allowedDistance =
      lastLegLength *
      ZigzagTolerancePercent /
      100.0;

   double maxAllowedHigh =
      lastSwingHigh + allowedDistance;


   //---------------------------------------------------------
   // Final condition
   //---------------------------------------------------------
   if(High0 <= maxAllowedHigh)
      return(2);

   return(0);
}

//+------------------------------------------------------------------+
//| شرط 9                                                           |
//+------------------------------------------------------------------+
// Condition 9:
// Logical OR between Condition 7 and Condition 8.
//
// The condition is satisfied if at least one of the
// following is true:
// - Current timeframe ZigZag condition (Condition 7)
// - Higher timeframe ZigZag condition (Condition 8)
//+------------------------------------------------------------------+
//| Condition 9                                                      |
//+------------------------------------------------------------------+
int Condition9_OR78(int shift)
{
   bool cond7 = Condition7_ZigzagCurrentTF(shift);
   bool cond8 = Condition8_ZigzagHigherTF(shift);

   //Print("Shift=",shift," Cond7=",cond7," Cond8=",cond8);

   if(cond7 || cond8)
      return(2);

   return(0);
}


//+------------------------------------------------------------------+
//| شرط 10                                                          |
//+------------------------------------------------------------------+
// Condition 10:
// Check whether the current market price is above
// the open price of candle #0.
//
// This condition ensures momentum confirmation
// at the moment of signal generation.
//+------------------------------------------------------------------+
//| Condition 10                                                     |
//+------------------------------------------------------------------+

// for realtime is ok -> but for history there is two options :
//وقتی این شرط را طراحی کردی، منظورت کدام بود؟

//Close کندل از Open خودش بالاتر باشد؟
//قیمت لحظه‌ای بازار از Open کندل فعلی بالاتر باشد؟

//اگر پاسخ 1 باشد، تابع را همین الان History-Aware می‌کنیم.

//اگر پاسخ 2 باشد، باید این شرط را هنگام اسکن تاریخچه غیرفعال کنیم، چون داده تاریخی معادل ندارد.

// for now we consider case 1 , in case of case 2 , we need to disable this condition for historic cadnedls

/*
int Condition10_OpenPrice()
{
   double currentPrice =
      SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double openPrice =
      iOpen(_Symbol, SignalTF, 0);
   
   if (currentPrice > openPrice){
      return 2;
   }
   return 0;
}
*/
// for case 1
/*
int Condition10_OpenPrice(int shift)
{
   double closePrice =
      iClose(_Symbol,SignalTF,shift);

   double openPrice =
      iOpen(_Symbol,SignalTF,shift);

   if(closePrice > openPrice)
      return(2);

   return(0);
}*/

// Condition 10
// Candle High >= X% of Bollinger Upper-Middle range
//==================================================================
// High کندل باید حداقل X درصد مسیر بین
// Middle Band و Upper Band بولینگر را طی کرده باشد
//==================================================================

int Condition10_OpenPrice(
   int shift,
   SetupType setup
   )
{
   double upperBand[];
   double middleBand[];
   double lowerBand[];

   ArraySetAsSeries(upperBand,true);
   ArraySetAsSeries(middleBand,true);
   ArraySetAsSeries(lowerBand,true);

   if(CopyBuffer(
         BB_Handle,
         1,
         shift,
         1,
         upperBand)<=0)
   {
      return(0);
   }

   if(CopyBuffer(
         BB_Handle,
         0,
         shift,
         1,
         middleBand)<=0)
   {
      return(0);
   }

   if(CopyBuffer(
         BB_Handle,
         2,
         shift,
         1,
         lowerBand)<=0)
   {
      return(0);
   }

   //--------------------------------------------------
   // فاصله مورد نیاز
   //--------------------------------------------------

   double requiredLevel;

   if(setup==SETUP_UPPER)
   {
      // Upper Setup

      double bandDistance =
         upperBand[0]-middleBand[0];

      requiredLevel =
         middleBand[0] +
         bandDistance *
         Condition10_Percent /
         100.0;
   }
   else
   {
      // Middle Setup

      double bandDistance =
         middleBand[0]-lowerBand[0];

      requiredLevel =
         lowerBand[0] +
         bandDistance *
         Condition10_Percent /
         100.0;
   }

   //--------------------------------------------------

   double signalPrice =
      iHigh(_Symbol,SignalTF,shift);

   if(signalPrice>=requiredLevel)
      return(2);

   return(0);
}


//+------------------------------------------------------------------+
//| ستاپ لاین وسط                                                   |
//+------------------------------------------------------------------+

// Middle Setup Condition 1:
// Check whether the open price of candle #0 is below
// the middle Bollinger Band.
//
// This confirms bearish bias relative to the midline.
//+------------------------------------------------------------------+
//| Middle Setup Condition 1                                         |
//+------------------------------------------------------------------+
int MiddleSetup_OpenBelowMiddle(int shift)
{
   double middleBand[];
   
   ArraySetAsSeries(middleBand,true);

   if(CopyBuffer(
         BB_Handle,
         0,      // Middle Band
         shift,
         2,
         middleBand) <= 0)
   {
      return(0);
   }

   double openPrice =
      iOpen(_Symbol,SignalTF,shift);
   
   //Print("Middle= (calculated must be check with the bb middle band)",middleBand[0]); 
   // if not correct change 2 to 1 in copy buffer
   
   if(openPrice < middleBand[0]){
      
      return(2);
   }
      

   return(0);
}


// Middle Setup Condition 2:
// Check whether the middle Bollinger Band slope is downward.
//
// A downtrend is confirmed if the middle band value
// at candle #0 is lower than candle #1.
//+------------------------------------------------------------------+
//| Middle Setup Condition 2                                         |
//+------------------------------------------------------------------+
int MiddleSetup_BBSlope(int shift)
{
   double middleBand[];

   ArraySetAsSeries(middleBand,true);

   if(CopyBuffer(
         BB_Handle,
         0,          // Middle Band
         shift,
         3,
         middleBand) <= 0)
   {
      return(0);
   }

   double middle0 = middleBand[0];
   double middle1 = middleBand[1];
   
   if(middle0 < middle1){
      return(2);
   }
      

   return(0);
}


// شرط 3
// Middle Setup Condition 3:
// Check whether price momentum is downward.
//
// A bearish slope is confirmed if price is decreasing
// from candle #2 to #0.
//+------------------------------------------------------------------+
//| Middle Setup Condition 3                                         |
//+------------------------------------------------------------------+
int MiddleSetup_PriceSlope(int shift)
{
   double close0 = iClose(_Symbol, SignalTF, shift);
   double close1 = iClose(_Symbol, SignalTF, shift + 1);
   double close2 = iClose(_Symbol, SignalTF, shift + 2);

   if(close0 < close1 && close1 < close2)
      return(2);

   return(0);
}

// Middle Setup Condition 4:
// Logical OR between:
// - Bollinger middle band slope (Condition 2)
// - Price slope (Condition 3)
//
// At least one must confirm bearish momentum.


//+------------------------------------------------------------------+
//| بررسی ستاپ سل                                                   |
//| فعلا هیچ شرطی در تصمیم گیری استفاده نشده است                     |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Middle Setup Condition 4                                         |
//+------------------------------------------------------------------+
int MiddleSetup_OR(int shift)
{
   bool bbSlope =
      MiddleSetup_BBSlope(shift);

   bool priceSlope =
      MiddleSetup_PriceSlope(shift);

   if(bbSlope || priceSlope)
      return(2);

   return(0);
}

bool CheckSellSetup(int shift)
{
   if(EnableUpperBandSetup)
   {
      if(CheckSellSetup_UpperBand(shift))
         return true;
   }

   if(EnableMiddleBandSetup)
   {
      if(CheckSellSetup_MiddleBand(shift))
         return true;
   }

   return false;
}


bool CheckSellSetup_UpperBand(int shift)
{
   //--------------------------------------------------
   // Condition 1
   //--------------------------------------------------
   if(!Condition1_BBTouch(shift,SETUP_UPPER))
      return(false);

   //--------------------------------------------------
   // RSI Condition 2
   //--------------------------------------------------
   if(Condition2_RSIBar1(
         shift,
         RSI_Handle_Upper,
         RSI_Level1_Upper)==0)
   {
      return(false);
   }

   //--------------------------------------------------
   // RSI Condition 3
   //--------------------------------------------------
   if(Use_RSI_Condition3)
   {
      if(Condition3_RSIBar0(
            shift,
            RSI_Handle_Upper,
            RSI_Level0_Upper)==0)
      {
         return(false);
      }
   }

   //--------------------------------------------------
   // Conditions 4-5-6
   //--------------------------------------------------
   if(Use_OR_Condition45)
   {
      if(Condition6_OR45(shift)==0)
         return(false);
   }
   else
   {
      if(Use_HighCondition)
      {
         if(Condition4_HighLimit(shift)==0)
            return(false);
      }

      if(Use_RSIPercentLimit)
      {
         if(Condition5_RSIPercent(shift)==0)
            return(false);
      }
   }

   //--------------------------------------------------
   // Conditions 7-8-9
   //--------------------------------------------------
   if(Use_OR_Condition78)
   {
      if(Condition9_OR78(shift)==0)
         return(false);
   }
   else
   {
      if(Use_Zigzag_CurrentTF)
      {
         if(Condition7_ZigzagCurrentTF(shift)==0)
            return(false);
      }

      if(Use_Zigzag_HTF)
      {
         if(Condition8_ZigzagHigherTF(shift)==0)
            return(false);
      }
   }

   //--------------------------------------------------
   // Condition 10
   //--------------------------------------------------
   if(Use_OpenPriceFilter)
   {
      if(!Condition10_OpenPrice(
            shift,
            SETUP_UPPER))
      {
         return(false);
      }
   }

   return(true);
}



//+------------------------------------------------------------------+
//| Sell Setup - Middle Bollinger Band                               |
//+------------------------------------------------------------------+
bool CheckSellSetup_MiddleBand(int shift)
{
   //--------------------------------------------------
   // Middle Condition 1
   //--------------------------------------------------
   if(!MiddleSetup_OpenBelowMiddle(shift))
      return(false);

   //--------------------------------------------------
   // Middle Conditions 2-3-4
   //--------------------------------------------------
   if(Use_OR_Slope)
   {
      if(!MiddleSetup_OR(shift))
         return(false);
   }
   else
   {
      if(Use_BB_MiddleSlope)
      {
         if(!MiddleSetup_BBSlope(shift))
            return(false);
      }

      if(Use_PriceSlope)
      {
         if(!MiddleSetup_PriceSlope(shift))
            return(false);
      }
   }
   
   //--------------------------------------------------
   // BB Condition 1
   //--------------------------------------------------
   if(!Condition1_BBTouch(shift,SETUP_MIDDLE))
      return(false);
   
   //--------------------------------------------------
   
   
   // RSI Condition 2
   //--------------------------------------------------
   if(!Condition2_RSIBar1(shift,RSI_Handle_Middle,RSI_Level1_Middle))
   {
      return(false);
   }

   //--------------------------------------------------
   // RSI Condition 3
   //--------------------------------------------------
   if(Use_RSI_Condition3)
   {
      if(!Condition3_RSIBar0(shift,RSI_Handle_Middle,RSI_Level0_Middle))
      {
         return(false);
      }
   }

   //--------------------------------------------------
   // Conditions 4-5-6
   //--------------------------------------------------
   if(Use_OR_Condition45)
   {
      if(!Condition6_OR45(shift))
         return(false);
   }
   else
   {
      if(Use_HighCondition)
      {
         if(!Condition4_HighLimit(shift))
            return(false);
      }

      if(Use_RSIPercentLimit)
      {
         if(!Condition5_RSIPercent(shift))
            return(false);
      }
   }

   //--------------------------------------------------
   // Conditions 7-8-9
   //--------------------------------------------------
   if(Use_OR_Condition78)
   {
      if(!Condition9_OR78(shift))
         return(false);
   }
   else
   {
      if(Use_Zigzag_CurrentTF)
      {
         if(!Condition7_ZigzagCurrentTF(shift))
            return(false);
      }

      if(Use_Zigzag_HTF)
      {
         if(!Condition8_ZigzagHigherTF(shift))
            return(false);
      }
   }

   //--------------------------------------------------
   // Condition 10
   //--------------------------------------------------
   if(Use_OpenPriceFilter)
   {
      if(!Condition10_OpenPrice(shift,SETUP_MIDDLE))
         return(false);
   }

   return(true);
}


//+------------------------------------------------------------------+
//| بررسی ستاپ بای                                                  |
//| نسخه معکوس سل در فاز بعدی                                       |
//+------------------------------------------------------------------+
bool CheckBuySetup()
{
   return(false);
}


//+------------------------------------------------------------------+
//| Calculation                                                     |
//+------------------------------------------------------------------+

// currentBar != LastSellSignalBar
static datetime LastAlertTime = 0;

int OnCalculate(
   const int rates_total,
   const int prev_calculated,
   const datetime &time[],
   const double &open[],
   const double &high[],
   const double &low[],
   const double &close[],
   const long &tick_volume[],
   const long &volume[],
   const int &spread[])
{

   static datetime LastClosedBarTime = 0;
   
   int startShift;
   
   datetime currentClosedBar =
      iTime(_Symbol,SignalTF,1);
   
   bool NewBar =
      (currentClosedBar != LastClosedBarTime);
   
   //--------------------------------------------------
   // First load
   //--------------------------------------------------
   if(prev_calculated == 0)
   {
      startShift =
         MathMin(rates_total - 10, HistoryScanBars);
   }
   //--------------------------------------------------
   // Real-time updates
   //--------------------------------------------------
   else
   {
      if(!NewBar)
         return(rates_total);
   
      startShift = 1;
   }

   //--------------------------------------------------
   // Scan
   //--------------------------------------------------
   
   for(int shift=startShift; shift>=1; shift--)
   {
      if(shift > MaxSignalBars)
         continue;
         
      if(CheckSellSetup(shift))
      {
         
         if(shift + 1 >= rates_total) // now it shows 1 candel earlier
            continue;
            
         DrawSellSignal(shift+1); // now it shows 1 candel earlier
         
         if(shift <= MaxZoneBars)
            DrawSignalZone(shift+1); // now it shows 1 candel earlier
            
         //------------------------------------
         // Realtime Alert Only
         //------------------------------------
         if(prev_calculated > 0 && shift == 1)
         // it is possible to ring 4-5 times during a candel // if we want 1 ring we must shift == 1 and ring will be heard when the signal candel is closed and in the begenning of next candel
         {
            datetime signalTime =
               iTime(_Symbol,SignalTF,1);
   
            if(signalTime != LastAlertTime)
            {
               if(EnablePopupAlert){
               datetime barTime = iTime(_Symbol,SignalTF,1);
               Alert(
                  _Symbol,
                  " SELL SIGNAL  BrokerTime=",
                  TimeToString(barTime,TIME_DATE|TIME_MINUTES)
               );
                  //Alert(_Symbol," SELL SIGNAL");
                  
               }
               
               if(EnableSoundAlert)
                  PlaySound("alert.wav");
   
               LastAlertTime = signalTime;
            }
         }
         
         
         
      }
   }
   
   DrawHTFLevels();
   
   
   LastClosedBarTime = currentClosedBar;
   
   return(rates_total);
}



void DrawSellSignal(int shift)
{
   datetime barTime =
      iTime(_Symbol,SignalTF,shift);

   string name =
      "SELL_" +
      IntegerToString((int)barTime);

   if(ObjectFind(0,name) >= 0)
      return;

   double price =
      iHigh(_Symbol,SignalTF,shift) +
      (ArrowDistancePoints * _Point);

   ObjectCreate(
      0,
      name,
      OBJ_ARROW_SELL,
      0,
      barTime,
      price
   );

   ObjectSetInteger(
      0,
      name,
      OBJPROP_WIDTH,
      2
   );
   
   
}

void DrawSignalZone(int shift)
{
   if(!ShowSignalZone)
      return;

   datetime signalTime =
      iTime(_Symbol,SignalTF,shift);

   string name =
      "ZONE_" +
      IntegerToString((int)signalTime);

   if(ObjectFind(0,name) >= 0)
      return;

   //--------------------------------------------------
   // زمان شروع و پایان ناحیه
   //--------------------------------------------------

   datetime startTime =
      signalTime -
      (SignalZoneBars * PeriodSeconds(SignalTF));

   datetime endTime =
      signalTime +
      (SignalZoneBars * PeriodSeconds(SignalTF));

   //--------------------------------------------------
   // محدوده قیمتی
   //--------------------------------------------------

   double zoneHigh =
      iHigh(_Symbol,SignalTF,shift);

   double zoneLow =
      iLow(_Symbol,SignalTF,shift);

   //--------------------------------------------------
   // رسم مستطیل
   //--------------------------------------------------

   if(!ObjectCreate(
         0,
         name,
         OBJ_RECTANGLE,
         0,
         startTime,
         zoneHigh,
         endTime,
         zoneLow))
   {
      //Print("Failed to create zone: ",name);
      return;
   }

   ObjectSetInteger(
      0,
      name,
      OBJPROP_COLOR,
      SignalZoneColor
   );

   ObjectSetInteger(
      0,
      name,
      OBJPROP_WIDTH,
      1
   );

   ObjectSetInteger( 
      0,
      name,
      OBJPROP_BACK,
      true
   );

   ObjectSetInteger(
      0,
      name,
      OBJPROP_FILL,
      true
   );

   ObjectSetInteger(
      0,
      name,
      OBJPROP_SELECTABLE,
      true
   );
   
   ObjectSetInteger(
   0,
   name,
   OBJPROP_SELECTED,
   false
   );
   
   ObjectSetInteger(
   0,
   name,
   OBJPROP_HIDDEN,
   false
   );
}




bool GetHTFZigZagLevels(
   double &lastSwingHigh,
   double &previousSwingLow,
   double &maxAllowedHigh
)
{
   lastSwingHigh    = 0.0;
   previousSwingLow = 0.0;
   maxAllowedHigh   = 0.0;

   double zzBuffer[];

   ArraySetAsSeries(zzBuffer,true);

   if(CopyBuffer(
         ZigZag_Handle_HTF,
         0,
         0,
         500,
         zzBuffer) <= 0)
   {
      return(false);
   }

   bool highFound = false;

   for(int i=1; i<500; i++)
   {
      if(zzBuffer[i] == 0.0)
         continue;

      if(!highFound)
      {
         if(
            MathAbs(
               zzBuffer[i]
               - iHigh(_Symbol,ZigzagHTF,i)
            ) < (_Point*5)
         )
         {
            lastSwingHigh = zzBuffer[i];
            highFound = true;
         }
      }
      else
      {
         if(
            MathAbs(
               zzBuffer[i]
               - iLow(_Symbol,ZigzagHTF,i)
            ) < (_Point*5)
         )
         {
            previousSwingLow = zzBuffer[i];
            break;
         }
      }
   }

   if(lastSwingHigh <= 0.0)
      return(false);

   if(previousSwingLow <= 0.0)
      return(false);

   double lastLegLength =
      lastSwingHigh - previousSwingLow;

   if(lastLegLength <= 0)
      return(false);

   double allowedDistance =
      lastLegLength *
      ZigzagTolerancePercent /
      100.0;

   maxAllowedHigh =
      lastSwingHigh + allowedDistance;

   return(true);
}

void DrawHTFLevels()
{
   if(!Show_HTF_ZigZag_Levels)
      return;

   double lastSwingHigh;
   double previousSwingLow;
   double maxAllowedHigh;

   if(!GetHTFZigZagLevels(
         lastSwingHigh,
         previousSwingLow,
         maxAllowedHigh))
   {
      return;
   }

   DrawLevel(
      "HTF_HIGH",
      lastSwingHigh,
      HTF_High_Color
   );

   DrawLevel(
      "HTF_LOW",
      previousSwingLow,
      HTF_Low_Color
   );

   DrawLevel(
      "HTF_MAX",
      maxAllowedHigh,
      HTF_MaxAllowed_Color
   );
}

void DrawLevel(
   string name,
   double price,
   color clr
)
{
   if(ObjectFind(0,name) < 0)
   {
      ObjectCreate(
         0,
         name,
         OBJ_HLINE,
         0,
         0,
         price
      );
   }

   ObjectSetDouble(
      0,
      name,
      OBJPROP_PRICE,
      price
   );

   ObjectSetInteger(
      0,
      name,
      OBJPROP_COLOR,
      clr
   );

   ObjectSetInteger(
      0,
      name,
      OBJPROP_WIDTH,
      2
   );
}



void OnDeinit(const int reason)
{
   //--------------------------------------------------
   // حذف کامل هنگام حذف اندیکاتور از چارت
   //--------------------------------------------------
   Print("DEINIT REASON = ",reason);
   
   if(reason == REASON_REMOVE ||
      reason == REASON_CHARTCLOSE)
   {
      ObjectsDeleteAll(0,-1,-1);

      int total = ChartIndicatorsTotal(0,0);

      for(int i=total-1; i>=0; i--)
      {
         string name =
            ChartIndicatorName(0,0,i);

         ChartIndicatorDelete(
            0,
            0,
            name
         );
      }

      ChartRedraw();
   }

   //--------------------------------------------------
   // تغییر پارامترهای اندیکاتور
   //--------------------------------------------------
   if(reason == REASON_PARAMETERS)
   {
      ObjectsDeleteAll(0,"SELL_");
      ObjectsDeleteAll(0,"ZONE_");
      ObjectsDeleteAll(0,"HTF_");

      ChartRedraw();
   }
}


void SendSellAlert()
{
   string msg =
      _Symbol +
      " SELL Signal (" +
      EnumToString(SignalTF) +
      ")";

   if(EnablePopupAlert)
      Alert(msg);

   if(EnableSoundAlert)
      PlaySound("alert.wav");
}