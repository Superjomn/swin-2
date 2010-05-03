# -*- coding: utf-8 -*-
from  hitindexer import HitIndexer
from doclist import DocList
from _indexer import Indexer
from htmldb import ArrangePageDB


#将爬取的网页进行排序
#以便于网页站点的判断
'''
arrange_page_db = ArrangePageDB()
arrange_page_db.run()
'''

hitindexer = HitIndexer()
hitindexer.run()

doclist = DocList()
doclist.run()
indexer = Indexer()
indexer.run()
