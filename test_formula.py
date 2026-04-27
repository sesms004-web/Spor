# Let's verify the pullback logic.
# Bearish setup: We are in a down wave (maj_h to maj_l).
# The pullback comes UP from maj_l towards maj_h.
# It reaches state.t2_h.
# The pullback distance is (state.t2_h - state.maj_l).
# The total wave is (state.maj_h - state.maj_l).
# So t2_pct = (t2_h - maj_l) / range * 100
# If the t2_pct < 40%, it means the pullback up was too weak.
# BUT wait.
# The minor structure sequences (1 -> 2 -> 3) happen WITHIN the same major wave?
# If a 2nd trade sweeps the 1st trade, it means it makes a HIGHER high.
# So state.t2_h will be higher than the 1st trade's t2_h.
# The problem is that once the first CHoCH happens, `state.choch_dir` is reset to 0!
