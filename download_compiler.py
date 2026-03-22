import urllib.request
import os

url = 'https://raw.githubusercontent.com/mq1n/mql5-compiler/master/mql64'
try:
    urllib.request.urlretrieve(url, 'mql64')
    os.system('chmod +x mql64')
    print("Downloaded")
except Exception as e:
    print(e)
