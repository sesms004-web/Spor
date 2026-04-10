with open('mukemmeliyet.mq5', 'r', encoding='utf-8') as f:
    text = f.read()

# I added an extra `}` during my attempt to fix `if (val_c < state.d1_l) {` vs `else if` mismatch.
text = text.replace("""          state.choch_dir = 0; // Reset after trigger
      }
      }
   } else if""",
"""          state.choch_dir = 0; // Reset after trigger
      }
   } else if""")

# Let's count again
open_braces = text.count('{')
close_braces = text.count('}')

if open_braces == close_braces:
    print("Match!")
else:
    print("Still mismatch")

with open('mukemmeliyet.mq5', 'w', encoding='utf-8') as f:
    f.write(text)
