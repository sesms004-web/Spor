//+------------------------------------------------------------------+
//|                                              Core_Structure.mqh  |
//|                    Major and Minor Structure Core Logic Only     |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| CStack: Array wrapper used for holding swing points              |
//+------------------------------------------------------------------+
class CStack
  {
private:
   double            m_vals[];
   int               m_idxs[];

public:
   void              Push(double v, int i)
     {
      int s = ArraySize(m_vals);
      ArrayResize(m_vals, s + 1);
      ArrayResize(m_idxs, s + 1);
      m_vals[s] = v;
      m_idxs[s] = i;
     }

   void              Pop()
     {
      int s = ArraySize(m_vals);
      if(s > 0)
        {
         ArrayResize(m_vals, s - 1);
         ArrayResize(m_idxs, s - 1);
        }
     }

   void              Clear()
     {
      ArrayResize(m_vals, 0);
      ArrayResize(m_idxs, 0);
     }

   int               Size() const { return ArraySize(m_vals); }

   double            GetVal(int idx) const
     {
      if(idx >= 0 && idx < ArraySize(m_vals)) return m_vals[idx];
      return EMPTY_VALUE;
     }

   int               GetIdx(int idx) const
     {
      if(idx >= 0 && idx < ArraySize(m_idxs)) return m_idxs[idx];
      return -1;
     }

   void              CopyFrom(const CStack &other)
     {
      ArrayCopy(m_vals, other.m_vals);
      ArrayCopy(m_idxs, other.m_idxs);
     }
  };

//+------------------------------------------------------------------+
//| SState: Core state variables for Structure Tracking              |
//+------------------------------------------------------------------+
struct SState
  {
   // Minor Structure
   int               min_tr;     // 1: Uptrend, -1: Downtrend
   double            min_h;      // Minor High
   int               min_h_i;    // Minor High Index
   double            min_l;      // Minor Low
   int               min_l_i;    // Minor Low Index
   double            trig_h;     // Trigger High (Opposite side of Minor Low)
   double            trig_l;     // Trigger Low (Opposite side of Minor High)
   int               lp_i;       // Last minor point index
   double            lp_p;       // Last minor point price

   // Major Structure
   int               maj_tr;     // 1: Uptrend, -1: Downtrend
   int               maj_st;     // 0: Impulsive/Trend, 1: Pullback

   double            maj_h;      // Confirmed Major High
   int               maj_h_i;    // Major High Index
   double            maj_l;      // Confirmed Major Low
   int               maj_l_i;    // Major Low Index

   double            tmp_h;      // Temporary/Unconfirmed High
   int               tmp_h_i;
   double            tmp_l;      // Temporary/Unconfirmed Low
   int               tmp_l_i;

   int               anc_i;      // Anchor index for major structure line
   double            anc_v;      // Anchor price
   int               bos_i;      // Break of Structure index

   // Swing Arrays
   CStack            st_h;       // Stack of minor highs
   CStack            st_l;       // Stack of minor lows

   // Mother Bar Tracking (for Inside Bar logic)
   double            mb_h;
   double            mb_l;
   int               mb_i;

   // Initialization
   void Init()
     {
      min_tr = 0; maj_tr = 0; maj_st = 0;
      min_h = 0; min_h_i = 0; min_l = 0; min_l_i = 0;
      trig_h = 0; trig_l = 0; lp_i = 0; lp_p = 0;
      maj_h = 0; maj_h_i = 0; maj_l = 0; maj_l_i = 0;
      tmp_h = 0; tmp_h_i = 0; tmp_l = 0; tmp_l_i = 0;
      anc_i = 0; anc_v = 0; bos_i = 0;
      mb_h = 0; mb_l = 0; mb_i = 0;
      st_h.Clear(); st_l.Clear();
     }

   void CopyFrom(const SState &other)
     {
      min_tr = other.min_tr; maj_tr = other.maj_tr; maj_st = other.maj_st;
      min_h = other.min_h; min_h_i = other.min_h_i; min_l = other.min_l; min_l_i = other.min_l_i;
      trig_h = other.trig_h; trig_l = other.trig_l; lp_i = other.lp_i; lp_p = other.lp_p;
      maj_h = other.maj_h; maj_h_i = other.maj_h_i; maj_l = other.maj_l; maj_l_i = other.maj_l_i;
      tmp_h = other.tmp_h; tmp_h_i = other.tmp_h_i; tmp_l = other.tmp_l; tmp_l_i = other.tmp_l_i;
      anc_i = other.anc_i; anc_v = other.anc_v; bos_i = other.bos_i;
      mb_h = other.mb_h; mb_l = other.mb_l; mb_i = other.mb_i;
      st_h.CopyFrom(other.st_h);
      st_l.CopyFrom(other.st_l);
     }
  };

//+------------------------------------------------------------------+
//| Core Function: Processes each bar to update Structure state      |
//+------------------------------------------------------------------+
void ProcessStructureBar(int i, const double &high[], const double &low[], const double &close[], SState &state)
  {
   double val_h = high[i];
   double val_l = low[i];
   double val_c = close[i];

   // --- MOTHER BAR & INSIDE BAR LOGIC ---
   // If min_tr is 0, we are initializing
   if(state.min_tr == 0)
     {
      state.min_tr = 1;
      state.min_h = val_h; state.min_h_i = i;
      state.min_l = val_l; state.min_l_i = i;
      state.trig_h = val_h; state.trig_l = val_l;
      state.mb_h = val_h; state.mb_l = val_l; state.mb_i = i;
     }
   else
     {
      // Check if current bar is an inside bar relative to the mother bar
      bool is_inside = (val_h <= state.mb_h && val_l >= state.mb_l);

      if(is_inside)
        {
         // Skip structural processing for inside bars
         return;
        }
      else
        {
         // Break out of inside bar, this bar becomes the new mother bar
         state.mb_h = val_h;
         state.mb_l = val_l;
         state.mb_i = i;
        }
     }

   // --- MINOR STRUCTURE LOGIC ---
   if(state.min_tr == 1) // Minor Uptrend
     {
      double old_trig = state.trig_l;
      // Making a new higher high
      if(val_h > state.min_h)
        {
         state.min_h = val_h;
         state.min_h_i = i;
         state.trig_l = val_l; // Trigger for reversal is the low of the highest bar
        }

      // Reversal: Price breaks below the trigger low
      if(val_l < old_trig)
        {
         state.st_h.Push(state.min_h, state.min_h_i); // Save the confirmed minor high

         // If Major structure was making an impulsive move up, check if this minor pullback invalidates a minor low
         if(state.maj_tr == 1 && state.maj_st == 0 && state.min_h < state.tmp_h && state.st_l.Size() > 0)
           {
            if(state.st_l.GetIdx(state.st_l.Size() - 1) > state.bos_i)
              {
               state.st_l.Pop();
              }
           }

         // Switch minor trend to down
         state.min_tr = -1;
         state.lp_i = state.min_h_i;
         state.lp_p = state.min_h;
         state.min_l = val_l;
         state.min_l_i = i;
         state.trig_h = val_h;
        }
     }
   else // Minor Downtrend (state.min_tr == -1)
     {
      double old_trig = state.trig_h;
      // Making a new lower low
      if(val_l < state.min_l)
        {
         state.min_l = val_l;
         state.min_l_i = i;
         state.trig_h = val_h; // Trigger for reversal is the high of the lowest bar
        }

      // Reversal: Price breaks above the trigger high
      if(val_h > old_trig)
        {
         state.st_l.Push(state.min_l, state.min_l_i); // Save the confirmed minor low

         // If Major structure was making an impulsive move down, check if this minor pullback invalidates a minor high
         if(state.maj_tr == -1 && state.maj_st == 0 && state.min_l > state.tmp_l && state.st_h.Size() > 0)
           {
            if(state.st_h.GetIdx(state.st_h.Size() - 1) > state.bos_i)
              {
               state.st_h.Pop();
              }
           }

         // Switch minor trend to up
         state.min_tr = 1;
         state.lp_i = state.min_l_i;
         state.lp_p = state.min_l;
         state.min_h = val_h;
         state.min_h_i = i;
         state.trig_l = val_l;
        }
     }


   // --- MAJOR STRUCTURE LOGIC ---
   // Initialize Major Structure
   if(state.maj_tr == 0)
     {
      state.maj_tr = 1; // Default to uptrend
      state.anc_i = state.min_l_i;
      state.anc_v = state.min_l;
      state.maj_l_i = state.min_l_i;
     }

   if(state.maj_tr == 1) // Major Uptrend
     {
      // Track temporary extreme high
      if(val_h > state.tmp_h)
        {
         state.tmp_h = val_h;
         state.tmp_h_i = i;
        }

      if(state.maj_st == 0) // Impulsive Phase (Making new highs)
        {
         double act = state.st_l.Size() > 0 ? state.st_l.GetVal(state.st_l.Size() - 1) : EMPTY_VALUE;
         // If price pulls back below the last valid minor low, a Major Pullback starts
         if(act != EMPTY_VALUE && val_l < act)
           {
            state.maj_h = state.tmp_h; // Confirm the major high
            state.maj_h_i = state.tmp_h_i;

            state.st_l.Clear();
            state.st_h.Clear();
            state.maj_st = 1; // Switch to Pullback phase
            state.anc_i = state.tmp_h_i;
            state.anc_v = state.maj_h;
            state.tmp_l = val_l;
            state.tmp_l_i = i;
           }

         // Update major low if price wicks below it but closes above
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l)
           {
            state.maj_l = val_l;
           }

         // Break of Structure (BOS) / Change of Character (CHoCH) downwards
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1; // Switch to Major Downtrend
            state.maj_st = 0;  // Start impulsive phase down
            state.bos_i = i;

            state.st_l.Clear();
            state.anc_i = state.tmp_h_i;
            state.anc_v = state.tmp_h;
            state.tmp_l = val_l;
            state.tmp_l_i = i;
            state.maj_h = state.tmp_h;
            state.maj_h_i = state.tmp_h_i;
           }
        }
      else if(state.maj_st == 1) // Pullback Phase
        {
         // Track the lowest point of the pullback
         if(val_l < state.tmp_l)
           {
            state.tmp_l = val_l;
            state.tmp_l_i = i;
           }

         // Update major high if price wicks above it but closes below
         if(val_h > state.maj_h && val_c <= state.maj_h)
           {
            state.maj_h = val_h;
           }

         // Trend continuation (BOS upwards)
         if(val_c > state.maj_h)
           {
            state.bos_i = i;
            state.maj_l = state.tmp_l; // Confirm the major low
            state.maj_l_i = state.tmp_l_i;

            state.st_h.Clear();
            state.maj_st = 0; // Switch back to Impulsive phase
            state.tmp_h = val_h;
            state.tmp_h_i = i;
           }

         // Update major low if price wicks below it but closes above
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_l < state.maj_l && val_c >= state.maj_l)
           {
            state.maj_l = val_l;
           }

         // Trend Reversal (CHoCH downwards) during pullback
         if(state.maj_l != EMPTY_VALUE && state.maj_l != 0 && val_c < state.maj_l)
           {
            state.maj_tr = -1; // Switch to Major Downtrend
            state.maj_st = 0;  // Start impulsive phase down
            state.bos_i = i;

            state.st_l.Clear();
            state.tmp_l = val_l;
            state.tmp_l_i = i;
            state.maj_h = state.tmp_h;
            state.maj_h_i = state.tmp_h_i;
           }
        }
     }
   else // Major Downtrend (state.maj_tr == -1)
     {
      // Track temporary extreme low
      if(val_l < state.tmp_l)
        {
         state.tmp_l = val_l;
         state.tmp_l_i = i;
        }

      if(state.maj_st == 0) // Impulsive Phase (Making new lows)
        {
         double act = state.st_h.Size() > 0 ? state.st_h.GetVal(state.st_h.Size() - 1) : EMPTY_VALUE;
         // If price pulls back above the last valid minor high, a Major Pullback starts
         if(act != EMPTY_VALUE && val_h > act)
           {
            state.maj_l = state.tmp_l; // Confirm the major low
            state.maj_l_i = state.tmp_l_i;

            state.st_l.Clear();
            state.st_h.Clear();
            state.maj_st = 1; // Switch to Pullback phase
            state.tmp_h = val_h;
            state.tmp_h_i = i;
            state.anc_i = state.tmp_l_i;
            state.anc_v = state.maj_l;
           }

         // Update major high if price wicks above it but closes below
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h)
           {
            state.maj_h = val_h;
           }

         // Break of Structure (BOS) / Change of Character (CHoCH) upwards
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.maj_tr = 1; // Switch to Major Uptrend
            state.maj_st = 0; // Start impulsive phase up
            state.bos_i = i;

            state.st_h.Clear();
            state.anc_i = state.tmp_l_i;
            state.anc_v = state.tmp_l;
            state.tmp_h = val_h;
            state.tmp_h_i = i;
            state.maj_l = state.tmp_l;
            state.maj_l_i = state.tmp_l_i;
           }
        }
      else if(state.maj_st == 1) // Pullback Phase
        {
         // Track the highest point of the pullback
         if(val_h > state.tmp_h)
           {
            state.tmp_h = val_h;
            state.tmp_h_i = i;
           }

         // Update major low if price wicks below it but closes above
         if(val_l < state.maj_l && val_c >= state.maj_l)
           {
            state.maj_l = val_l;
           }

         // Trend continuation (BOS downwards)
         if(val_c < state.maj_l)
           {
            state.bos_i = i;
            state.maj_h = state.tmp_h; // Confirm the major high
            state.maj_h_i = state.tmp_h_i;

            state.st_l.Clear();
            state.maj_st = 0; // Switch back to Impulsive phase
            state.tmp_l = val_l;
            state.tmp_l_i = i;
           }

         // Update major high if price wicks above it but closes below
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_h > state.maj_h && val_c <= state.maj_h)
           {
            state.maj_h = val_h;
           }

         // Trend Reversal (CHoCH upwards) during pullback
         if(state.maj_h != EMPTY_VALUE && state.maj_h != 0 && val_c > state.maj_h)
           {
            state.maj_tr = 1; // Switch to Major Uptrend
            state.maj_st = 0; // Start impulsive phase up
            state.bos_i = i;

            state.st_h.Clear();
            state.tmp_h = val_h;
            state.tmp_h_i = i;
            state.maj_l = state.tmp_l;
            state.maj_l_i = state.tmp_l_i;
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Wrapper Indicator Logic for Testing Core Structure               |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0

SState g_state;

int OnInit()
  {
   g_state.Init();
   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,
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
   if(rates_total < 2)
      return 0;

   int start = (prev_calculated > 0) ? prev_calculated - 1 : 0;

   if(prev_calculated == 0)
     {
      g_state.Init();
     }

   for(int i = start; i < rates_total; i++)
     {
      ProcessStructureBar(i, high, low, close, g_state);
     }

   return rates_total;
  }
//+------------------------------------------------------------------+
