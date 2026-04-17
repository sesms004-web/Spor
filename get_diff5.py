# Ah!
# In `EvaluateTradeSignal`, what is `t`?
# `void EvaluateTradeSignal(int current_bar_i, datetime t, double live_price, int trigger_dir, double p_pct, bool is_strong, double minor_extreme_sl, int maj_extreme_i, bool is_test = false)`
# In `InpTestTradeExecution`:
# `EvaluateTradeSignal(rates_total-1, TimeCurrent(), ...)`
# Here `t` IS `TimeCurrent()`!
# So `GetMTFChochDetails` is called with `TimeCurrent()`.
# Which is EXACTLY the same as `GenerateMTFChochReport` which sets `t = TimeCurrent()`!
# So `GetMTFChochDetails` HAS THE EXACT SAME INPUTS!
# THEN WHY does `GenerateMTFChochReport` work and `EvaluateTradeSignal` fail (return 0)?
# Wait. They don't fail!
# "Test kısmında hepsi ne olduğu belli" = GenerateMTFChochReport prints perfectly!
# "fakat choch bildirim kismina geldiğinde hepsi bekleniyor diyor" = EvaluateTradeSignal prints "Veri Bekleniyor"!
# WHY?
# Could it be because `EvaluateTradeSignal` defines `c_dir_h1` as `int` and `GenerateMTFChochReport` defines it as `reports[i].dir` which is `int`?
# Wait! Look at `EvaluateTradeSignal`:
# `GetMTFChochDetails(PERIOD_H1, t, c_dir_h1, c_lvl_h1, c_t_h1);`
# Does `EvaluateTradeSignal` have `c_dir_h1` initialized as 0? YES.
# What if `GetMTFChochDetails` is returning immediately due to `if(copied < 2) return;`?
# Why would `CopyRates` return < 2 in `EvaluateTradeSignal`, but not in `GenerateMTFChochReport`?
# In `GenerateMTFChochReport`, it's called inside `OnCalculate` ONLY when `InpTestMTFChochReport` changes state!
# In `EvaluateTradeSignal`, it's called inside `OnCalculate` ONLY when `InpTestTradeExecution` changes state!
# They are literally identically executed!
# BUT WAIT!
# If it's a REAL LIVE TRADE...
# Does `ProcessBar` trigger `EvaluateTradeSignal` BEFORE the other timeframe charts are loaded?
# Yes!
# `ProcessBar` triggers `EvaluateTradeSignal(i, time[i], val_c, ...)`!
# At that exact moment, `time[i]` is the exact second the CHoCH happens!
# What if `CopyRates` for `PERIOD_H1` at `time[i]` (e.g. 2 days ago in a backtest) returns 0 because `anchor_time` is `time[i] - 180 days`?
# YES! If you're backtesting, MT5 might not have H1 data from 180 days BEFORE `time[i]`!
# So `copied` is < 2.
# So `GetMTFChochDetails` returns instantly!
# AND `c_dir_h1` stays 0!
# AND the message says "Veri Bekleniyor"!
# SO THIS IS EXPECTED BEHAVIOR FOR BACKTESTING/LIVE CACHE MISSES!
