# If InpDaysH1 is 180 days, there is 100% a CHoCH in 180 days!
# So why did it return 0?
# Wait! In `GetMTFChochDetails`:
#    int copied = CopyRates(Symbol(), tf, anchor_time, current_time, rates);
#    if(copied < 2) return;
# Is `copied < 2` happening?
# If we do `CopyRates` with H1 over 180 days, is it returning less than 2?
# MT5 sometimes doesn't download HTF data immediately. If `CopyRates` asks for H1 and it's not cached, it returns 0.
# The user might be getting `copied < 2` which immediately `return`s, leaving `c_dir` at 0!
# Yes! `CopyRates` fails on first call because it's in the background!
# And since it returns immediately, `c_dir`, `c_level`, and `c_time` are all 0 because they are not modified!
