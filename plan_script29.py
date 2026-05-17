import re
with open("misyoner001.mq5", "r") as f:
    code = f.read()

# Let's inspect `DoDrawBox` again.
# "string nm=GetUniqueName(pfx+"Box_");
# DrawRect(nm,GetTimeSafe(time,left_i),top,D'2099.12.31 00:00',bot,clr);
# BxAdd(nm,top,bot,clr,time,left_i);"
# If a box doesn't get trimmed, why?
# Because `g_bx_state[k]` does not reach 1, or `g_bx_touch_state[k]` stays 1.
# Or `g_bx_cnt` maxes out? `if(g_bx_cnt>=BOX_MAX)return;`
# Wait... in `BxAdd`, `g_bx_state[g_bx_cnt]=2;`.
# If `ProcessBar` calls `BxAdvanceTrim(t)`, then `g_bx_state[k]` becomes 1.
# But `BxAdvanceTrim` is only called when a major structure pivots.
# If `ProcessBar` stops pivoting, boxes stay infinite.
# Why would `ProcessBar` stop pivoting?
# Because I removed `if(!is_history) EvaluateTradeSignal...` ? No, `EvaluateTradeSignal` is just a function call.
# Could `EvaluateTradeSignal` be crashing or returning early and skipping the rest of `ProcessBar`?
# In MQL5, `return` inside `EvaluateTradeSignal` returns from `EvaluateTradeSignal`, not `ProcessBar`.
# Let's check `EvaluateTradeSignal`.

match = re.search(r"bool EvaluateTradeSignal.*?\}", code, re.DOTALL)
if match:
    # print(match.group(0))
    pass
