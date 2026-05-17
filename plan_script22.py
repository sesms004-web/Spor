import re

with open("downloaded_misyoner001.mq5", "r") as f:
    orig = f.read()

# Wait, `downloaded_misyoner001.mq5` doesn't exist. Let me download it again.
