import re

with open('smcv1.mq5', 'r') as f:
    content = f.read()

text_bear_search = """                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t1_i), state.t1_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T1");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.d1_i), state.d1_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "D1");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t2_i), state.t2_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T2");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.d2_i), state.d2_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "D2");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t3_i), state.t3_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T3");"""

text_bear_replace = """                  string t1_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, t1_name, OBJ_TEXT, 0, GetTimeSafe(time, state.t1_i), state.t1_h);
                  ObjectSetString(0, t1_name, OBJPROP_TEXT, "T1");
                  ObjectSetInteger(0, t1_name, OBJPROP_COLOR, clrWhite);

                  string d1_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, d1_name, OBJ_TEXT, 0, GetTimeSafe(time, state.d1_i), state.d1_l);
                  ObjectSetString(0, d1_name, OBJPROP_TEXT, "D1");
                  ObjectSetInteger(0, d1_name, OBJPROP_COLOR, clrWhite);

                  string t2_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, t2_name, OBJ_TEXT, 0, GetTimeSafe(time, state.t2_i), state.t2_h);
                  ObjectSetString(0, t2_name, OBJPROP_TEXT, "T2");
                  ObjectSetInteger(0, t2_name, OBJPROP_COLOR, clrWhite);

                  string d2_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, d2_name, OBJ_TEXT, 0, GetTimeSafe(time, state.d2_i), state.d2_l);
                  ObjectSetString(0, d2_name, OBJPROP_TEXT, "D2");
                  ObjectSetInteger(0, d2_name, OBJPROP_COLOR, clrWhite);

                  string t3_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, t3_name, OBJ_TEXT, 0, GetTimeSafe(time, state.t3_i), state.t3_h);
                  ObjectSetString(0, t3_name, OBJPROP_TEXT, "T3");
                  ObjectSetInteger(0, t3_name, OBJPROP_COLOR, clrWhite);"""

content = content.replace(text_bear_search, text_bear_replace)


text_bull_search = """                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t1_i), state.t1_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T1");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.d1_i), state.d1_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "D1");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t2_i), state.t2_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T2");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.d2_i), state.d2_h);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "D2");
                  ObjectCreate(0, GetUniqueName(prefix + "CHoCH_Text_"), OBJ_TEXT, 0, GetTimeSafe(time, state.t3_i), state.t3_l);
                  ObjectSetString(0, prefix + "CHoCH_Text_" + IntegerToString(g_counter), OBJPROP_TEXT, "T3");"""


text_bull_replace = """                  string t1_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, t1_name, OBJ_TEXT, 0, GetTimeSafe(time, state.t1_i), state.t1_l);
                  ObjectSetString(0, t1_name, OBJPROP_TEXT, "T1");
                  ObjectSetInteger(0, t1_name, OBJPROP_COLOR, clrWhite);

                  string d1_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, d1_name, OBJ_TEXT, 0, GetTimeSafe(time, state.d1_i), state.d1_h);
                  ObjectSetString(0, d1_name, OBJPROP_TEXT, "D1");
                  ObjectSetInteger(0, d1_name, OBJPROP_COLOR, clrWhite);

                  string t2_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, t2_name, OBJ_TEXT, 0, GetTimeSafe(time, state.t2_i), state.t2_l);
                  ObjectSetString(0, t2_name, OBJPROP_TEXT, "T2");
                  ObjectSetInteger(0, t2_name, OBJPROP_COLOR, clrWhite);

                  string d2_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, d2_name, OBJ_TEXT, 0, GetTimeSafe(time, state.d2_i), state.d2_h);
                  ObjectSetString(0, d2_name, OBJPROP_TEXT, "D2");
                  ObjectSetInteger(0, d2_name, OBJPROP_COLOR, clrWhite);

                  string t3_name = GetUniqueName(prefix + "CHoCH_Text_");
                  ObjectCreate(0, t3_name, OBJ_TEXT, 0, GetTimeSafe(time, state.t3_i), state.t3_l);
                  ObjectSetString(0, t3_name, OBJPROP_TEXT, "T3");
                  ObjectSetInteger(0, t3_name, OBJPROP_COLOR, clrWhite);"""

content = content.replace(text_bull_search, text_bull_replace)

with open('smcv1.mq5', 'w') as f:
    f.write(content)
