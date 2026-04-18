import re

with open('smaecv1.mq5', 'r', encoding='utf-8') as f:
    code = f.read()

dup_block = """              int r_total_t = ArraySize(time);
              if (state.t1_i >= 0 && state.t1_i < r_total_t &&
                  state.d1_i >= 0 && state.d1_i < r_total_t &&
                  state.t2_i >= 0 && state.t2_i < r_total_t &&
                  i >= 0 && i < r_total_t) {

              int r_total_t = ArraySize(time);
              if (state.t1_i >= 0 && state.t1_i < r_total_t &&
                  state.d1_i >= 0 && state.d1_i < r_total_t &&
                  state.t2_i >= 0 && state.t2_i < r_total_t &&
                  i >= 0 && i < r_total_t) {"""

clean_block = """              int r_total_t = ArraySize(time);
              if (state.t1_i >= 0 && state.t1_i < r_total_t &&
                  state.d1_i >= 0 && state.d1_i < r_total_t &&
                  state.t2_i >= 0 && state.t2_i < r_total_t &&
                  i >= 0 && i < r_total_t) {"""

code = code.replace(dup_block, clean_block)

dup_end = """              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_l, time[i] + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);
              }

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_l, time[i] + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);
              }"""

clean_end = """              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_l, time[i] + PeriodSeconds() * 5, state.d1_l, sig_color, 3, STYLE_SOLID, false);
              }"""

code = code.replace(dup_end, clean_end)

dup_end_h = """              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_h, time[i] + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);
              }

              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_h, time[i] + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);
              }"""

clean_end_h = """              // 2. Draw the short, thick signal marker at breakout level
              string choch_name = GetUniqueName(prefix + "CHoCH_Signal_");
              DrawLine(choch_name, time[i], state.d1_h, time[i] + PeriodSeconds() * 5, state.d1_h, sig_color, 3, STYLE_SOLID, false);
              }"""

code = code.replace(dup_end_h, clean_end_h)

with open('smaecv1.mq5', 'w', encoding='utf-8') as f:
    f.write(code)
