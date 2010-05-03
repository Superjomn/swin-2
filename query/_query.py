# -*- coding: utf-8 -*-
from _query import Query

import sys
from debug import *
sys.path.append('../')
from Config import Config
config = Config()

query = Query()
print query.query('中国')
