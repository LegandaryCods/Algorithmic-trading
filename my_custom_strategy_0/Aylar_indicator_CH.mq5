//+------------------------------------------------------------------+
//| XAUUSD Ultra Scalper - CopyRates Test Version                    |
//+------------------------------------------------------------------+
#property strict

#property indicator_chart_window

#property indicator_buffers 9
#property indicator_plots 9


#property indicator_label6 "BB Upper"
#property indicator_type6 DRAW_LINE
#property indicator_color6 clrAqua

#property indicator_label7 "BB Lower"
#property indicator_type7 DRAW_LINE
#property indicator_color7 clrMagenta


#property indicator_label3 "EMA Fast"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrDodgerBlue
#property indicator_width3 2

#property indicator_label4 "EMA Slow"
#property indicator_type4 DRAW_LINE
#property indicator_color4 clrOrange
#property indicator_width4 2

#property indicator_label5 "BB Middle"
#property indicator_type5 DRAW_LINE
#property indicator_color5 clrYellow
#property indicator_width5 1



#property indicator_width5 1
#property indicator_width6 1
#property indicator_width7 1


#property indicator_label1 "BUY"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLime
#property indicator_width1 5

#property indicator_label2 "SELL"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrRed
#property indicator_width2 5

#property indicator_label8 "BUY PREVIEW"
#property indicator_type8 DRAW_ARROW
#property indicator_color8 clrDarkGreen
#property indicator_width8 3

#property indicator_label9 "SELL PREVIEW"
#property indicator_type9 DRAW_ARROW
#property indicator_color9 clrIndianRed
#property indicator_width9 3

input int EMAFastLength = 5;
input int EMASlowLength = 20;

input int BBLength      = 14;
input double BBMult     = 1.5;
input int MomLength     = 3;

int FastEMAHandle;
int SlowEMAHandle;
int BandsHandle;

double EMAFastBuffer[];
double EMASlowBuffer[];
double BBMiddleBuffer[];
double BBUpperBuffer[];
double BBLowerBuffer[];

double BuyBuffer[];
double SellBuffer[];

double BuyPreviewBuffer[];
double SellPreviewBuffer[];


input bool ShowDebugLines = false; // for back testing

//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0,BuyBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
   
   SetIndexBuffer(7,BuyPreviewBuffer,INDICATOR_DATA);
   SetIndexBuffer(8,SellPreviewBuffer,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   
   PlotIndexSetInteger(7,PLOT_ARROW,241);
   PlotIndexSetInteger(8,PLOT_ARROW,242);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   ArraySetAsSeries(BuyBuffer,true);
   ArraySetAsSeries(SellBuffer,true);
   
   ArraySetAsSeries(BuyPreviewBuffer,true);
   ArraySetAsSeries(SellPreviewBuffer,true);

   FastEMAHandle=iMA(_Symbol,_Period,EMAFastLength,0,MODE_EMA,PRICE_CLOSE);
   SlowEMAHandle=iMA(_Symbol,_Period,EMASlowLength,0,MODE_EMA,PRICE_CLOSE);

   if(FastEMAHandle==INVALID_HANDLE)
      return(INIT_FAILED);

   if(SlowEMAHandle==INVALID_HANDLE)
      return(INIT_FAILED);
      
      
   BandsHandle=iBands(
      _Symbol,
      _Period,
      BBLength,
      0,
      BBMult,
      PRICE_CLOSE
   );
   
   if(BandsHandle==INVALID_HANDLE)
      return(INIT_FAILED);
      
   SetIndexBuffer(2,EMAFastBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,EMASlowBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,BBMiddleBuffer,INDICATOR_DATA);
   
   SetIndexBuffer(5,BBUpperBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,BBLowerBuffer,INDICATOR_DATA);
   
   ArraySetAsSeries(BBUpperBuffer,true);
   ArraySetAsSeries(BBLowerBuffer,true);
   
   ArraySetAsSeries(EMAFastBuffer,true);
   ArraySetAsSeries(EMASlowBuffer,true);
   ArraySetAsSeries(BBMiddleBuffer,true);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
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
   MqlRates rates[];

   int copied=CopyRates(_Symbol,_Period,0,1000,rates);

   if(copied<100)
      return(rates_total);

   ArraySetAsSeries(rates,true);

   //================ EMA =================
   double FastEMA[];
   double SlowEMA[];

   ArrayResize(FastEMA,copied);
   ArrayResize(SlowEMA,copied);

   ArraySetAsSeries(FastEMA,true);
   ArraySetAsSeries(SlowEMA,true);

   if(CopyBuffer(FastEMAHandle,0,0,copied,FastEMA)<=0)
      return(rates_total);

   if(CopyBuffer(SlowEMAHandle,0,0,copied,SlowEMA)<=0)
      return(rates_total);

   //================ BOLLINGER =================
   double Upper[];
   double Lower[];
   double Middle[];

   ArrayResize(Upper,copied);
   ArrayResize(Lower,copied);
   ArrayResize(Middle,copied);

   ArraySetAsSeries(Upper,true);
   ArraySetAsSeries(Lower,true);
   ArraySetAsSeries(Middle,true);

   // MQL5:
   // 0 = Upper
   // 1 = Lower
   // 2 = Middle

   if(CopyBuffer(BandsHandle,0,0,copied,Middle)<=0)
   return(rates_total);

   if(CopyBuffer(BandsHandle,1,0,copied,Upper)<=0)
      return(rates_total);
   
   if(CopyBuffer(BandsHandle,2,0,copied,Lower)<=0)
      return(rates_total);
         
   
   //Print("BUF0 = ",Upper[1]);
   //Print("BUF1 = ",Lower[1]);
   //Print("BUF2 = ",Middle[1]);

   //================ DRAW EMA & BB =================

   for(int i=0;i<copied;i++)
   {
         if(ShowDebugLines)
      {
         EMAFastBuffer[i]=FastEMA[i];
         EMASlowBuffer[i]=SlowEMA[i];
      
         BBUpperBuffer[i]=Upper[i];
         BBMiddleBuffer[i]=Middle[i];
         BBLowerBuffer[i]=Lower[i];
      }
      else
      {
         EMAFastBuffer[i]=EMPTY_VALUE;
         EMASlowBuffer[i]=EMPTY_VALUE;
      
         BBUpperBuffer[i]=EMPTY_VALUE;
         BBMiddleBuffer[i]=EMPTY_VALUE;
         BBLowerBuffer[i]=EMPTY_VALUE;
      }
   
   }

   //================ MOMENTUM (PINE VERSION) =================

   double MomSource[];
   double MomEMA[];
   double MomPine[];

   ArrayResize(MomSource,copied);
   ArrayResize(MomEMA,copied);
   ArrayResize(MomPine,copied);

   ArraySetAsSeries(MomSource,false);
   ArraySetAsSeries(MomEMA,false);

   for(int i=0;i<copied;i++)
   {
      int r=copied-1-i;

      MomSource[i]=
         rates[r].close-
         rates[r].open;
   }

   double alpha=2.0/(MomLength+1.0);

   MomEMA[0]=MomSource[0];

   for(int i=1;i<copied;i++)
   {
      MomEMA[i]=
         alpha*MomSource[i]
         +(1.0-alpha)*MomEMA[i-1];
   }

   ArraySetAsSeries(MomPine,true);

   for(int i=0;i<copied;i++)
   {
      MomPine[i]=
         MomEMA[copied-1-i];
   }

   //================ CLEAR BUFFERS =================

   for(int i=0;i<copied;i++)
   {
      BuyBuffer[i]=EMPTY_VALUE;
      SellBuffer[i]=EMPTY_VALUE;
   
      BuyPreviewBuffer[i]=EMPTY_VALUE;
      SellPreviewBuffer[i]=EMPTY_VALUE;
   }

   //================ SIGNALS =================

   for(int i=copied-5;i>=1;i--)
   {
      bool CrossUp=
         FastEMA[i] > SlowEMA[i] &&
         FastEMA[i+1] <= SlowEMA[i+1];

      bool CrossDown=
         FastEMA[i] < SlowEMA[i] &&
         FastEMA[i+1] >= SlowEMA[i+1];

      bool BuyCond=
         (
            rates[i].close < Lower[i]
            ||
            CrossUp
         )
         &&
         MomPine[i] > 0;

      bool SellCond=
         (
            rates[i].close > Upper[i]
            ||
            CrossDown
         )
         &&
         MomPine[i] < 0;

      double Offset=
         (rates[i].high-rates[i].low)*0.8;

      if(Offset < 80*_Point)
         Offset=80*_Point;

      if(BuyCond)
         BuyBuffer[i]=rates[i].low-Offset;

      if(SellCond)
         SellBuffer[i]=rates[i].high+Offset;
   }
   
   // for signals in i = 0 and before close of it
   int liveBar=0;

   bool CrossUpLive=
      FastEMA[liveBar] > SlowEMA[liveBar] &&
      FastEMA[liveBar+1] <= SlowEMA[liveBar+1];
   
   bool CrossDownLive=
      FastEMA[liveBar] < SlowEMA[liveBar] &&
      FastEMA[liveBar+1] >= SlowEMA[liveBar+1];
   
   bool BuyPreview=
   (
      rates[liveBar].close < Lower[liveBar]
      ||
      CrossUpLive
   )
   &&
   MomPine[liveBar] > 0;
   
   bool SellPreview=
   (
      rates[liveBar].close > Upper[liveBar]
      ||
      CrossDownLive
   )
   &&
   MomPine[liveBar] < 0;
   
   double PreviewOffset=
      (rates[0].high-rates[0].low)*0.80;
   
   if(PreviewOffset<80*_Point)
      PreviewOffset=80*_Point;
   
   /*
   if(BuyPreview)
      BuyPreviewBuffer[0]=rates[0].low-PreviewOffset;
   
   if(SellPreview)
      SellPreviewBuffer[0]=rates[0].high+PreviewOffset;
   */
   
   if(BuyPreview)
   {
      BuyPreviewBuffer[0]=rates[0].low-PreviewOffset;
   
      /*Print(
         TimeToString(rates[0].time),
         " BUY PREVIEW"
      );*/
   }
   
   if(SellPreview)
   {
      SellPreviewBuffer[0]=rates[0].high+PreviewOffset;
   
      /*Print(
         TimeToString(rates[0].time),
         " SELL PREVIEW"
      );*/
   }
   
   //================ ALERTS =================

   static datetime LastAlertBar=0;

   int bar=1;

   bool CrossUpNow=
      FastEMA[bar] > SlowEMA[bar] &&
      FastEMA[bar+1] <= SlowEMA[bar+1];

   bool CrossDownNow=
      FastEMA[bar] < SlowEMA[bar] &&
      FastEMA[bar+1] >= SlowEMA[bar+1];

   bool BuyNow=
      (
         rates[bar].close < Lower[bar]
         ||
         CrossUpNow
      )
      &&
      MomPine[bar] > 0;

   bool SellNow=
      (
         rates[bar].close > Upper[bar]
         ||
         CrossDownNow
      )
      &&
      MomPine[bar] < 0;

   if(rates[bar].time!=LastAlertBar)
   {
      if(BuyNow)
      {
         Alert("XAUUSD Fast BUY Signal (Ultra Scalper)");
         LastAlertBar=rates[bar].time;
      }

      if(SellNow)
      {
         Alert("XAUUSD Fast SELL Signal (Ultra Scalper)");
         LastAlertBar=rates[bar].time;
      }
   }
   
   
   return(rates_total);
}