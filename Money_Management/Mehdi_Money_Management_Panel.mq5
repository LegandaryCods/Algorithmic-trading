//+------------------------------------------------------------------+
//|                                 Mehdi_Money_Management_Panel.mq5 |
//|                                                    Fardin Marabi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Fardin Marabi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#property strict

// Enable mouse-move events on the chart

// NOTE: Mouse-move events are enabled at runtime in OnInit()
// via ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1)

#include <Trade\Trade.mqh>

//───────────────────────────────────────────────────────────────────
// USER INPUTS  (panel fields override these at runtime)
//───────────────────────────────────────────────────────────────────
input double InpRiskPercent   = 1.0;  // Default Risk % per trade
input double InpRR            = 2.0;  // Default Risk:Reward ratio
input int    InpSLCandles     = 2;    // Default SL candle lookback
input double InpTolerancePips = 5.0;  // Default tolerance (pips)

//───────────────────────────────────────────────────────────────────
// COLOURS
//───────────────────────────────────────────────────────────────────
#define COL_BG          C'28,28,42'
#define COL_HEADER      C'18,18,32'
#define COL_BORDER      C'72,72,110'
#define COL_LABEL       C'170,170,195'
#define COL_INFO_BG     C'18,18,32'
#define COL_INFO_TXT    C'100,210,255'
#define COL_INPUT_BG    C'42,42,62'
#define COL_INPUT_BDR   C'78,78,118'
#define COL_BUY         C'25,150,75'
#define COL_SELL        C'195,45,45'
#define COL_CLOSEBTN    C'70,70,95'
#define COL_GRIP        C'60,60,90'
#define COL_RF          C'160,110,0'    // Risk Free button — amber/gold
#define COL_WHITE       clrWhite

//───────────────────────────────────────────────────────────────────
// PANEL LAYOUT CONSTANTS
//───────────────────────────────────────────────────────────────────
#define HEADER_H        32   // header bar height
#define GRIP_SIZE       14   // resize grip square
#define PAD             10   // inner padding
#define ROW_H           32   // height per input row
#define EDIT_H          22   // height of edit boxes
#define INFO_H          28   // info bar height
#define BTN_H           38   // trade button height
#define RF_BTN_H        32   // risk-free button height
#define MIN_W           230  // minimum panel width
#define MIN_H           335  // minimum panel height

//───────────────────────────────────────────────────────────────────
// OBJECT NAME PREFIXES/KEYS
//───────────────────────────────────────────────────────────────────
#define PFX             "SP_"   // prefix for all objects
#define OBJ_BG          PFX"bg"
#define OBJ_HDR         PFX"hdr"
#define OBJ_TITLE       PFX"title"
#define OBJ_CLOSE       PFX"close"
#define OBJ_GRIP        PFX"grip"
#define OBJ_GRIP_ICO    PFX"grip_ico"
#define OBJ_LBL_RISK    PFX"lbl_risk"
#define OBJ_LBL_RR      PFX"lbl_rr"
#define OBJ_LBL_CDL     PFX"lbl_cdl"
#define OBJ_LBL_TOL     PFX"lbl_tol"
#define OBJ_EDT_RISK    PFX"edt_risk"
#define OBJ_EDT_RR      PFX"edt_rr"
#define OBJ_EDT_CDL     PFX"edt_cdl"
#define OBJ_EDT_TOL     PFX"edt_tol"
#define OBJ_INFO_BG     PFX"info_bg"
#define OBJ_INFO_TXT    PFX"info_txt"
#define OBJ_BTN_BUY     PFX"btn_buy"
#define OBJ_BTN_SELL    PFX"btn_sell"
#define OBJ_BTN_RF      PFX"btn_rf"
#define OBJ_DRAG_GUARD  PFX"drag_guard"

//───────────────────────────────────────────────────────────────────
// PANEL STATE  (mutable at runtime)
//───────────────────────────────────────────────────────────────────
int    g_px   = 20,  g_py  = 50;   // top-left position
int    g_pw   = 270, g_ph  = 320;  // width / height
bool   g_visible = true;

// Drag state
bool   g_dragging  = false;
int    g_drag_ox   = 0, g_drag_oy = 0;  // offset within header at drag start

// Resize state
bool   g_resizing  = false;
int    g_res_ox    = 0, g_res_oy = 0;   // mouse pos at resize start
int    g_res_pw    = 0, g_res_ph = 0;   // panel size at resize start

CTrade g_trade;

//═══════════════════════════════════════════════════════════════════
//  LOW-LEVEL OBJECT HELPERS
//═══════════════════════════════════════════════════════════════════

void _Rect(string n, int x, int y, int w, int h,
           color bg, color bdr=clrNONE, int z=0)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,       w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,       h);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0,n,OBJPROP_COLOR,       bdr==clrNONE?bg:bdr);
   ObjectSetInteger(0,n,OBJPROP_WIDTH,       bdr==clrNONE?0:1);
   ObjectSetInteger(0,n,OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_BACK,        false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,      z);
}

void _Label(string n, int x, int y, string txt,
            color clr, int fs=9, string font="Segoe UI", int z=2)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,  y);
   ObjectSetString (0,n,OBJPROP_TEXT,        txt);
   ObjectSetInteger(0,n,OBJPROP_COLOR,       clr);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,    fs);
   ObjectSetString (0,n,OBJPROP_FONT,        font);
   ObjectSetInteger(0,n,OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_BACK,        false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,      z);
}

void _Edit(string n, int x, int y, int w, int h, string txt, int z=3)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,       w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,       h);
   ObjectSetString (0,n,OBJPROP_TEXT,        txt);
   ObjectSetInteger(0,n,OBJPROP_COLOR,       COL_WHITE);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,     COL_INPUT_BG);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,COL_INPUT_BDR);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,    9);
   ObjectSetString (0,n,OBJPROP_FONT,        "Segoe UI");
   ObjectSetInteger(0,n,OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_BACK,        false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,      z);
}

// Preserve the text when resizing/moving an edit
void _EditMove(string n, int x, int y, int w, int h)
{
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,    w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,    h);
}

void _Button(string n, int x, int y, int w, int h,
             string txt, color bg, int fs=10, int z=4)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,       w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,       h);
   ObjectSetString (0,n,OBJPROP_TEXT,        txt);
   ObjectSetInteger(0,n,OBJPROP_COLOR,       COL_WHITE);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,    fs);
   ObjectSetString (0,n,OBJPROP_FONT,        "Segoe UI Bold");
   ObjectSetInteger(0,n,OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_BACK,        false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,      z);
}

//═══════════════════════════════════════════════════════════════════
//  PANEL BUILD / LAYOUT
//═══════════════════════════════════════════════════════════════════

//------------------------------------------------------------------
// ComputeLayout: derive all child positions from g_px/g_py/g_pw/g_ph
// Outputs pixel coordinates for every element.
//------------------------------------------------------------------
struct PanelLayout
{
   // backgrounds
   int bg_x,bg_y,bg_w,bg_h;
   int hdr_x,hdr_y,hdr_w,hdr_h;
   // title label
   int title_x,title_y;
   // close button
   int close_x,close_y,close_w,close_h;
   // resize grip
   int grip_x,grip_y,grip_w,grip_h;
   int grip_ico_x,grip_ico_y;
   // 4 rows of label+edit
   int row_y[4];       // top y of each row
   int lbl_x;          // x of all labels
   int edt_x,edt_w;   // x and width of all edits
   // info bar
   int info_bg_x,info_bg_y,info_bg_w,info_bg_h;
   int info_txt_x,info_txt_y;
   // trade buttons
   int btn_y,btn_buy_x,btn_sell_x,btn_w,btn_h;
   // risk-free button
   int btn_rf_x,btn_rf_y,btn_rf_w,btn_rf_h;
};

void ComputeLayout(PanelLayout &L)
{
   L.bg_x=g_px; L.bg_y=g_py; L.bg_w=g_pw; L.bg_h=g_ph;

   L.hdr_x=g_px; L.hdr_y=g_py; L.hdr_w=g_pw; L.hdr_h=HEADER_H;

   L.title_x = g_px+PAD;
   L.title_y = g_py + (HEADER_H-13)/2;

   L.close_w=24; L.close_h=24;
   L.close_x = g_px + g_pw - L.close_w - 4;
   L.close_y = g_py + (HEADER_H-L.close_h)/2;

   L.grip_w=GRIP_SIZE; L.grip_h=GRIP_SIZE;
   L.grip_x = g_px + g_pw - GRIP_SIZE;
   L.grip_y = g_py + g_ph - GRIP_SIZE;
   L.grip_ico_x = L.grip_x+2;
   L.grip_ico_y = L.grip_y+2;

   // content area starts below header
   int cy = g_py + HEADER_H + 6;   // content top y
   L.lbl_x   = g_px + PAD;
   L.edt_w   = (int)MathMax(70, g_pw * 0.40);
   L.edt_x   = g_px + g_pw - L.edt_w - PAD;

   for(int i=0;i<4;i++)
      L.row_y[i] = cy + i*ROW_H;

   // info bar
   int infoTop = cy + 4*ROW_H + 4;
   L.info_bg_x=g_px+PAD; L.info_bg_y=infoTop;
   L.info_bg_w=g_pw-2*PAD; L.info_bg_h=INFO_H;
   L.info_txt_x=L.info_bg_x+6;
   L.info_txt_y=infoTop+(INFO_H-9)/2;

   // trade buttons
   L.btn_y = infoTop + INFO_H + 6;
   L.btn_h = BTN_H;
   int totalBtnW = g_pw - 2*PAD - 6;
   L.btn_w = totalBtnW/2;
   L.btn_buy_x  = g_px+PAD;
   L.btn_sell_x = g_px+PAD + L.btn_w + 6;

   // Risk Free button — full width, below BUY/SELL
   L.btn_rf_h = RF_BTN_H;
   L.btn_rf_w = g_pw - 2*PAD;
   L.btn_rf_x = g_px + PAD;
   L.btn_rf_y = L.btn_y + L.btn_h + 6;
}

//------------------------------------------------------------------
// CreatePanel: first-time creation of all objects
//------------------------------------------------------------------
void CreatePanel()
{
   PanelLayout L;
   ComputeLayout(L);

   // --- backgrounds
   _Rect(OBJ_BG,  L.bg_x, L.bg_y, L.bg_w, L.bg_h,  COL_BG, COL_BORDER, 0);
   _Rect(OBJ_HDR, L.hdr_x,L.hdr_y,L.hdr_w,L.hdr_h, COL_HEADER, COL_HEADER, 1);

   // --- title & close
   _Label(OBJ_TITLE, L.title_x, L.title_y, "SmartPanel EA", COL_INFO_TXT, 10, "Segoe UI Bold");
   _Button(OBJ_CLOSE, L.close_x,L.close_y,L.close_w,L.close_h, "x", COL_CLOSEBTN, 9);

   // --- resize grip (visual only – click detection done via mouse coords)
   _Rect(OBJ_GRIP, L.grip_x, L.grip_y, L.grip_w, L.grip_h, COL_GRIP, COL_BORDER, 5);
   _Label(OBJ_GRIP_ICO, L.grip_ico_x, L.grip_ico_y, "//", COL_BORDER, 7, "Courier New", 5);

   // --- rows
   string lblNames[4] = {OBJ_LBL_RISK, OBJ_LBL_RR, OBJ_LBL_CDL, OBJ_LBL_TOL};
   string lblTexts[4] = {"Risk per trade (%):", "Risk : Reward (R:R):",
                          "SL candle lookback:", "Tolerance (pips):"};
   string edtNames[4] = {OBJ_EDT_RISK, OBJ_EDT_RR, OBJ_EDT_CDL, OBJ_EDT_TOL};
   string edtDefaults[4];
   edtDefaults[0] = DoubleToString(InpRiskPercent,   1);
   edtDefaults[1] = DoubleToString(InpRR,            1);
   edtDefaults[2] = IntegerToString(InpSLCandles);
   edtDefaults[3] = DoubleToString(InpTolerancePips, 1);

   for(int i=0;i<4;i++)
   {
      _Label(lblNames[i], L.lbl_x, L.row_y[i]+5, lblTexts[i], COL_LABEL, 8);
      _Edit (edtNames[i], L.edt_x, L.row_y[i], L.edt_w, EDIT_H, edtDefaults[i]);
   }

   // --- info bar
   _Rect (OBJ_INFO_BG,  L.info_bg_x, L.info_bg_y, L.info_bg_w, L.info_bg_h,
          COL_INFO_BG, COL_INPUT_BDR, 2);
   _Label(OBJ_INFO_TXT, L.info_txt_x, L.info_txt_y,
          "Lot size will appear here", COL_INFO_TXT, 8);

   // --- trade buttons
   _Button(OBJ_BTN_BUY,  L.btn_buy_x,  L.btn_y, L.btn_w, L.btn_h, "BUY",  COL_BUY,  11);
   _Button(OBJ_BTN_SELL, L.btn_sell_x, L.btn_y, L.btn_w, L.btn_h, "SELL", COL_SELL, 11);

   // Risk Free — full-width button below BUY/SELL
   _Button(OBJ_BTN_RF, L.btn_rf_x, L.btn_rf_y, L.btn_rf_w, L.btn_rf_h,
           "RISK FREE  (move SL to breakeven)", COL_RF, 9);

   ChartRedraw(0);
}

//------------------------------------------------------------------
// RelayoutPanel: move/resize all objects to current g_px/g_py/g_pw/g_ph
// Does NOT recreate objects — preserves edit field text.
//------------------------------------------------------------------
void RelayoutPanel()
{
   PanelLayout L;
   ComputeLayout(L);

   // backgrounds
   ObjectSetInteger(0,OBJ_BG,OBJPROP_XDISTANCE,L.bg_x);
   ObjectSetInteger(0,OBJ_BG,OBJPROP_YDISTANCE,L.bg_y);
   ObjectSetInteger(0,OBJ_BG,OBJPROP_XSIZE,    L.bg_w);
   ObjectSetInteger(0,OBJ_BG,OBJPROP_YSIZE,    L.bg_h);

   ObjectSetInteger(0,OBJ_HDR,OBJPROP_XDISTANCE,L.hdr_x);
   ObjectSetInteger(0,OBJ_HDR,OBJPROP_YDISTANCE,L.hdr_y);
   ObjectSetInteger(0,OBJ_HDR,OBJPROP_XSIZE,    L.hdr_w);
   ObjectSetInteger(0,OBJ_HDR,OBJPROP_YSIZE,    L.hdr_h);

   // title & close
   ObjectSetInteger(0,OBJ_TITLE,OBJPROP_XDISTANCE,L.title_x);
   ObjectSetInteger(0,OBJ_TITLE,OBJPROP_YDISTANCE,L.title_y);

   ObjectSetInteger(0,OBJ_CLOSE,OBJPROP_XDISTANCE,L.close_x);
   ObjectSetInteger(0,OBJ_CLOSE,OBJPROP_YDISTANCE,L.close_y);

   // grip
   ObjectSetInteger(0,OBJ_GRIP,    OBJPROP_XDISTANCE,L.grip_x);
   ObjectSetInteger(0,OBJ_GRIP,    OBJPROP_YDISTANCE,L.grip_y);
   ObjectSetInteger(0,OBJ_GRIP_ICO,OBJPROP_XDISTANCE,L.grip_ico_x);
   ObjectSetInteger(0,OBJ_GRIP_ICO,OBJPROP_YDISTANCE,L.grip_ico_y);

   // rows — labels and edits
   string lblNames[4] = {OBJ_LBL_RISK,OBJ_LBL_RR,OBJ_LBL_CDL,OBJ_LBL_TOL};
   string edtNames[4] = {OBJ_EDT_RISK,OBJ_EDT_RR,OBJ_EDT_CDL,OBJ_EDT_TOL};
   for(int i=0;i<4;i++)
   {
      ObjectSetInteger(0,lblNames[i],OBJPROP_XDISTANCE,L.lbl_x);
      ObjectSetInteger(0,lblNames[i],OBJPROP_YDISTANCE,L.row_y[i]+5);
      _EditMove(edtNames[i], L.edt_x, L.row_y[i], L.edt_w, EDIT_H);
   }

   // info bar
   ObjectSetInteger(0,OBJ_INFO_BG, OBJPROP_XDISTANCE,L.info_bg_x);
   ObjectSetInteger(0,OBJ_INFO_BG, OBJPROP_YDISTANCE,L.info_bg_y);
   ObjectSetInteger(0,OBJ_INFO_BG, OBJPROP_XSIZE,    L.info_bg_w);
   ObjectSetInteger(0,OBJ_INFO_BG, OBJPROP_YSIZE,    L.info_bg_h);
   ObjectSetInteger(0,OBJ_INFO_TXT,OBJPROP_XDISTANCE,L.info_txt_x);
   ObjectSetInteger(0,OBJ_INFO_TXT,OBJPROP_YDISTANCE,L.info_txt_y);

   // trade buttons
   ObjectSetInteger(0,OBJ_BTN_BUY, OBJPROP_XDISTANCE,L.btn_buy_x);
   ObjectSetInteger(0,OBJ_BTN_BUY, OBJPROP_YDISTANCE,L.btn_y);
   ObjectSetInteger(0,OBJ_BTN_BUY, OBJPROP_XSIZE,    L.btn_w);
   ObjectSetInteger(0,OBJ_BTN_BUY, OBJPROP_YSIZE,    L.btn_h);

   ObjectSetInteger(0,OBJ_BTN_SELL,OBJPROP_XDISTANCE,L.btn_sell_x);
   ObjectSetInteger(0,OBJ_BTN_SELL,OBJPROP_YDISTANCE,L.btn_y);
   ObjectSetInteger(0,OBJ_BTN_SELL,OBJPROP_XSIZE,    L.btn_w);
   ObjectSetInteger(0,OBJ_BTN_SELL,OBJPROP_YSIZE,    L.btn_h);

   ObjectSetInteger(0,OBJ_BTN_RF,OBJPROP_XDISTANCE,L.btn_rf_x);
   ObjectSetInteger(0,OBJ_BTN_RF,OBJPROP_YDISTANCE,L.btn_rf_y);
   ObjectSetInteger(0,OBJ_BTN_RF,OBJPROP_XSIZE,    L.btn_rf_w);
   ObjectSetInteger(0,OBJ_BTN_RF,OBJPROP_YSIZE,    L.btn_rf_h);

   ChartRedraw(0);
}

//------------------------------------------------------------------
// DestroyPanel
//------------------------------------------------------------------
void DestroyPanel()
{
   string all[] = {
      OBJ_BG, OBJ_HDR, OBJ_TITLE, OBJ_CLOSE,
      OBJ_GRIP, OBJ_GRIP_ICO,
      OBJ_LBL_RISK, OBJ_LBL_RR, OBJ_LBL_CDL, OBJ_LBL_TOL,
      OBJ_EDT_RISK, OBJ_EDT_RR, OBJ_EDT_CDL, OBJ_EDT_TOL,
      OBJ_INFO_BG, OBJ_INFO_TXT,
      OBJ_BTN_BUY, OBJ_BTN_SELL, OBJ_BTN_RF
   };
   for(int i=0;i<ArraySize(all);i++)
      ObjectDelete(0,all[i]);
   ChartRedraw(0);
   g_visible = false;
}

//═══════════════════════════════════════════════════════════════════
//  HIT-TESTING HELPERS
//═══════════════════════════════════════════════════════════════════

bool HitHeader(int mx, int my)
{
   // Header zone, excluding the close button area
   return (mx >= g_px && mx <= g_px+g_pw-30 &&
           my >= g_py && my <= g_py+HEADER_H);
}

bool HitGrip(int mx, int my)
{
   int gx = g_px+g_pw-GRIP_SIZE;
   int gy = g_py+g_ph-GRIP_SIZE;
   return (mx >= gx && mx <= gx+GRIP_SIZE &&
           my >= gy && my <= gy+GRIP_SIZE);
}

bool HitCloseBtn(int mx, int my)
{
   int cx = g_px+g_pw-28;
   int cy = g_py+4;
   return (mx >= cx && mx <= cx+24 && my >= cy && my <= cy+24);
}

bool InsidePanel(int mx, int my)
{
   return (mx>=g_px && mx<=g_px+g_pw && my>=g_py && my<=g_py+g_ph);
}

//═══════════════════════════════════════════════════════════════════
//  CLAMP PANEL TO CHART BOUNDARIES
//═══════════════════════════════════════════════════════════════════

void ClampToChart()
{
   int cw = (int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
   int ch = (int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   if(g_px < 0) g_px = 0;
   if(g_py < 0) g_py = 0;
   if(g_px+g_pw > cw) g_px = cw-g_pw;
   if(g_py+g_ph > ch) g_py = ch-g_ph;
   if(g_pw > cw) g_pw = cw;
   if(g_ph > ch) g_ph = ch;
}

//═══════════════════════════════════════════════════════════════════
//  TRADE LOGIC
//═══════════════════════════════════════════════════════════════════

bool ReadInputs(double &riskPct, double &rr, int &candles, double &tolPips)
{
   riskPct = StringToDouble(ObjectGetString(0,OBJ_EDT_RISK,OBJPROP_TEXT));
   rr       = StringToDouble(ObjectGetString(0,OBJ_EDT_RR,  OBJPROP_TEXT));
   candles  = (int)StringToInteger(ObjectGetString(0,OBJ_EDT_CDL,OBJPROP_TEXT));
   tolPips  = StringToDouble(ObjectGetString(0,OBJ_EDT_TOL, OBJPROP_TEXT));

   if(riskPct<=0||riskPct>100){Alert("Invalid Risk %");  return false;}
   if(rr<=0)                   {Alert("Invalid R:R");     return false;}
   if(candles<=0)              {Alert("Invalid lookback");return false;}
   if(tolPips<0)               {Alert("Invalid tolerance");return false;}
   return true;
}

double PipSize()
{
   int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   double pt=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   return (d==3||d==5)?pt*10.0:pt;
}

double CalcLotSize(double slDist, double riskPct)
{
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmt   = balance * riskPct / 100.0;
   double tickVal   = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tickSz    = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double pt        = SymbolInfoDouble(_Symbol,SYMBOL_POINT);

   if(tickSz==0||tickVal==0||pt==0) return 0;

   double valPerPt  = tickVal/tickSz*pt;
   if(valPerPt==0) return 0;

   double lots = riskAmt / (slDist/pt * valPerPt);

   double step = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   lots = MathFloor(lots/step)*step;
   return MathMax(vmin,MathMin(vmax,lots));
}

void UpdateInfoBar(bool isBuy=true)
{
   double riskPct,rr,tolPips; int candles;
   if(!ReadInputs(riskPct,rr,candles,tolPips)) return;

   double pip  = PipSize();
   double tol  = tolPips * pip;
   int    digs = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);

   double slDist;
   if(isBuy)
   {
      double lo = iLow(_Symbol,PERIOD_CURRENT,candles);
      double sl = lo - tol;
      slDist = SymbolInfoDouble(_Symbol,SYMBOL_ASK) - sl;
   }
   else
   {
      double hi = iHigh(_Symbol,PERIOD_CURRENT,candles);
      double sl = hi + tol;
      slDist = sl - SymbolInfoDouble(_Symbol,SYMBOL_BID);
   }

   if(slDist<=0)
   {
      ObjectSetString(0,OBJ_INFO_TXT,OBJPROP_TEXT,"SL error — check lookback/tolerance");
      return;
   }

   double lots   = CalcLotSize(slDist,riskPct);
   double tpDist = slDist*rr;

   string txt = StringFormat("Lots: %.2f   SL: %.1f pip   TP: %.1f pip",
                             lots, slDist/pip, tpDist/pip);
   ObjectSetString(0,OBJ_INFO_TXT,OBJPROP_TEXT,txt);
}

void ExecuteTrade(bool isBuy)
{
   double riskPct,rr,tolPips; int candles;
   if(!ReadInputs(riskPct,rr,candles,tolPips)) return;

   double pip  = PipSize();
   double tol  = tolPips*pip;
   int    digs = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   double ask  = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid  = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   double entry,sl,tp,slDist;
   if(isBuy)
   {
      entry  = ask;
      sl     = NormalizeDouble(iLow (_Symbol,PERIOD_CURRENT,candles)-tol, digs);
      slDist = entry-sl;
      tp     = NormalizeDouble(entry+slDist*rr, digs);
   }
   else
   {
      entry  = bid;
      sl     = NormalizeDouble(iHigh(_Symbol,PERIOD_CURRENT,candles)+tol, digs);
      slDist = sl-entry;
      tp     = NormalizeDouble(entry-slDist*rr, digs);
   }

   if(slDist<=0){Alert("SL distance ≤ 0 — check settings."); return;}

   double lots = CalcLotSize(slDist,riskPct);
   if(lots<=0)  {Alert("Lot size = 0 — check balance/risk."); return;}

   g_trade.SetDeviationInPoints(10);
   bool ok = isBuy ? g_trade.Buy (lots,_Symbol,0,sl,tp,"SmartPanel BUY")
                   : g_trade.Sell(lots,_Symbol,0,sl,tp,"SmartPanel SELL");

   if(ok)
      PrintFormat("[SmartPanel] %s  lots=%.2f  entry=%.5f  sl=%.5f  tp=%.5f  risk=%.1f%%",
                  isBuy?"BUY":"SELL", lots, entry, sl, tp, riskPct);
   else
      Alert("Order failed: ", g_trade.ResultRetcodeDescription());
}

//═══════════════════════════════════════════════════════════════════
//  RISK FREE — move SL to breakeven for all profitable positions
//═══════════════════════════════════════════════════════════════════

void MakeRiskFree()
{
   int    digs    = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int    moved   = 0;
   int    skipped = 0;

   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      // Only act on positions for the current chart symbol
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      long   posType   = PositionGetInteger(POSITION_TYPE);

      double newSL = NormalizeDouble(openPrice, digs);

      if(posType == POSITION_TYPE_BUY)
      {
         // Only move SL if position is currently profitable
         if(bid <= openPrice)
         {
            skipped++;
            continue;
         }
         // Only move SL if it would actually improve (move it up to BE)
         if(currentSL >= newSL)
         {
            skipped++;
            continue;
         }
         if(g_trade.PositionModify(ticket, newSL, currentTP))
         {
            PrintFormat("[SmartPanel] Risk Free: BUY #%I64u  SL moved %.5f -> %.5f (breakeven)",
                        ticket, currentSL, newSL);
            moved++;
         }
         else
         {
            PrintFormat("[SmartPanel] Risk Free: Failed to modify #%I64u — %s",
                        ticket, g_trade.ResultRetcodeDescription());
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         // Only move SL if position is currently profitable
         if(ask >= openPrice)
         {
            skipped++;
            continue;
         }
         // Only move SL if it would actually improve (move it down to BE)
         if(currentSL != 0 && currentSL <= newSL)
         {
            skipped++;
            continue;
         }
         if(g_trade.PositionModify(ticket, newSL, currentTP))
         {
            PrintFormat("[SmartPanel] Risk Free: SELL #%I64u  SL moved %.5f -> %.5f (breakeven)",
                        ticket, currentSL, newSL);
            moved++;
         }
         else
         {
            PrintFormat("[SmartPanel] Risk Free: Failed to modify #%I64u — %s",
                        ticket, g_trade.ResultRetcodeDescription());
         }
      }
   }

   // User feedback via info bar
   string msg;
   if(moved == 0 && skipped == 0)
      msg = "Risk Free: no open positions on " + _Symbol;
   else if(moved == 0)
      msg = StringFormat("Risk Free: no profitable positions to protect (%d skipped)", skipped);
   else
      msg = StringFormat("Risk Free: %d position(s) moved to breakeven", moved);

   ObjectSetString(0, OBJ_INFO_TXT, OBJPROP_TEXT, msg);
   ChartRedraw(0);
}

//═══════════════════════════════════════════════════════════════════
//  EA LIFECYCLE
//═══════════════════════════════════════════════════════════════════

int OnInit()
{
   // Ask MT5 to route mouse-move events to OnChartEvent
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1);
   CreatePanel();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   DestroyPanel();
}

void OnTick()
{
   if(!g_visible) return;
   if(ObjectFind(0,OBJ_EDT_RISK)<0) return;
   UpdateInfoBar(true);
}

//═══════════════════════════════════════════════════════════════════
//  CHART EVENT — drag, resize, clicks
//═══════════════════════════════════════════════════════════════════

void OnChartEvent(const int    id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(!g_visible) return;

   //────────────────────────────────────────────────────────────────
   // MOUSE MOVE  (lparam=x, dparam=y, sparam = button flags string)
   // Button flags: "1" = left held, "2" = right held
   //────────────────────────────────────────────────────────────────
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      int mx = (int)lparam;
      int my = (int)dparam;
      bool lbDown = (StringFind(sparam,"1") >= 0);  // left mouse held

      //--- DRAG: mouse held + we were dragging
      if(g_dragging)
      {
         if(lbDown)
         {
            g_px = mx - g_drag_ox;
            g_py = my - g_drag_oy;
            ClampToChart();
            RelayoutPanel();
         }
         else
         {
            // Button released — end drag
            g_dragging = false;
            ChartSetInteger(0,CHART_MOUSE_SCROLL,true);
         }
         return;
      }

      //--- RESIZE: mouse held + we were resizing
      if(g_resizing)
      {
         if(lbDown)
         {
            int newW = g_res_pw + (mx - g_res_ox);
            int newH = g_res_ph + (my - g_res_oy);
            g_pw = (int)MathMax(MIN_W, newW);
            g_ph = (int)MathMax(MIN_H, newH);
            ClampToChart();
            RelayoutPanel();
         }
         else
         {
            g_resizing = false;
            ChartSetInteger(0,CHART_MOUSE_SCROLL,true);
         }
         return;
      }

      //--- INITIATE DRAG on left-button press in header
      if(lbDown && HitHeader(mx,my))
      {
         g_dragging = true;
         g_drag_ox  = mx - g_px;
         g_drag_oy  = my - g_py;
         ChartSetInteger(0,CHART_MOUSE_SCROLL,false); // freeze chart scroll
         return;
      }

      //--- INITIATE RESIZE on left-button press on grip
      if(lbDown && HitGrip(mx,my))
      {
         g_resizing = true;
         g_res_ox   = mx;
         g_res_oy   = my;
         g_res_pw   = g_pw;
         g_res_ph   = g_ph;
         ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
         return;
      }

      return; // nothing to do for other mouse moves
   }

   //────────────────────────────────────────────────────────────────
   // OBJECT CLICK
   //────────────────────────────────────────────────────────────────
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == OBJ_BTN_BUY)
      {
         ObjectSetInteger(0,OBJ_BTN_BUY,OBJPROP_STATE,false);
         ExecuteTrade(true);
         ChartRedraw(0);
         return;
      }
      if(sparam == OBJ_BTN_SELL)
      {
         ObjectSetInteger(0,OBJ_BTN_SELL,OBJPROP_STATE,false);
         ExecuteTrade(false);
         ChartRedraw(0);
         return;
      }
      if(sparam == OBJ_CLOSE)
      {
         ObjectSetInteger(0,OBJ_CLOSE,OBJPROP_STATE,false);
         DestroyPanel();
         return;
      }
      if(sparam == OBJ_BTN_RF)
      {
         ObjectSetInteger(0,OBJ_BTN_RF,OBJPROP_STATE,false);
         MakeRiskFree();
         return;
      }
   }

   //────────────────────────────────────────────────────────────────
   // EDIT FIELD CHANGED — refresh info bar
   //────────────────────────────────────────────────────────────────
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      if(sparam==OBJ_EDT_RISK || sparam==OBJ_EDT_RR ||
         sparam==OBJ_EDT_CDL  || sparam==OBJ_EDT_TOL)
      {
         UpdateInfoBar(true);
         ChartRedraw(0);
      }
   }
}
//+------------------------------------------------------------------+