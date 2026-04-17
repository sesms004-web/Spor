# Look at `ProcessBar` minor structure update:
#   if (draw_ui && (!is_history || (InpWaitRetest && is_just_closed))) { ... }
# What about MAJOR structure?
# Major structure update:
#   if(draw_ui && InpShowMaj) { DrawLine(...) }
# It looks like ProcessBar does calculate EVERYTHING even if `is_history = true` and `draw_ui = false`.
# Wait, NO NO NO!
# The user's problem ONLY occurs IN `EvaluateTradeSignal` (which is called with `t = time[i]`).
# Look at `InpTestTradeExecution` in `OnCalculate`!!
