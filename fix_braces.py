with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# I clearly removed the closing brace for `if (val_c < state.d1_l && in_pullback_zone) {` when stripping alerts earlier.
# The code is currently:
#       state.choch_dir = 0; // Reset after trigger
#   }
# } else if ...
# It should be:
#       state.choch_dir = 0; // Reset after trigger
#      }
#   } else if ...

text = text.replace("""          state.choch_dir = 0; // Reset after trigger
      }
   } else if""",
"""          state.choch_dir = 0; // Reset after trigger
      }
      }
   } else if""")

text = text.replace("""          state.choch_dir = 0; // Reset after trigger
      }
   }
   // MAJOR STRUCTURE""",
"""          state.choch_dir = 0; // Reset after trigger
      }
      }
   }
   // MAJOR STRUCTURE""")

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
