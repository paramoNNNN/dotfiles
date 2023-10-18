#!/usr/bin/env python3

import sys
import requests

btc_price = requests.get(f'https://api.coindesk.com/v1/bpi/currentprice.json').json()['bpi']['USD']['rate']
sys.stdout.write(f'$ {btc_price}')


