# -*- coding: utf-8 -*-
from _query import Query
#from Queryer import Queryer

strr = ['落实教育规划纲要','祖国','理学院会议']
query = Query()


while True:
    strr = raw_input('>>')
    print query.query(strr)
#print query.query('理学院会议')

