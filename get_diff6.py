# Wait!
# The user's message is:
# "Test kısmında hepsi ne olduğu belli fakat choch bildirim kismina geldiğinde hepsi bekleniyor diyor"
# "Test kısmı" = Generated report when you click "Test MTF CHoCH Report" button (which uses `TimeCurrent()`).
# "choch bildirim kismina geldiginde" = When a LIVE CHoCH alert triggers on the chart.
# Why does a LIVE CHoCH alert say "bekleniyor"?
# Because `t = time[i]` is passed to `GetMTFChochDetails`!
# `t = time[i]` is the exact time of the CHoCH bar.
# But `GenerateMTFChochReport` uses `TimeCurrent()`!
# If the CHoCH happened 2 hours ago, `time[i]` is 2 hours ago.
# `GetMTFChochDetails` requests `anchor_time = time[i] - 180 days` to `time[i]`.
# Is `CopyRates` failing for `time[i]`?
# IN LIVE TRADING, `time[i]` is `TimeCurrent()`! So it shouldn't fail if `TimeCurrent()` doesn't fail!
# SO WHY DOES IT FAIL?
# Wait...
# Is `time[i]` REALLY `TimeCurrent()` for a live bar?
# Yes, `time[rates_total-1]` is exactly the open time of the current bar.
# So `CopyRates` from `anchor_time` to `time[i]` is the EXACT SAME data request as `CopyRates` from `anchor_time` to `TimeCurrent()`, because `time[i]` is within the current bar!
# WAIT!
# `CopyRates` using `anchor_time` and `current_time` uses EXACT TIMESTAMPS.
# `time[i]` is the OPEN TIME of the M1 bar. (e.g. 15:31:00)
# `TimeCurrent()` is the EXACT SECOND of the tick! (e.g. 15:31:45)
# MT5 `CopyRates(..., start_time, stop_time, rates)` INCLUDES the `stop_time`.
# DOES `CopyRates` return `< 2` for `time[i]` but `> 2` for `TimeCurrent()`?
# NO, they are basically identical.
