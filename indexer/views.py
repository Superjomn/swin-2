# -*- coding: utf-8 -*-
from django.template.loader import get_template
from django.template import Context
from django.http import HttpResponse


class IndexerCtrl:
    '''
    Indexer 控制系统
    返回相应标志
    '''
    def __init__(self):
        pass

    def arrangePageDB(self):
        from htmldb import ArrangePageDB
        arrange_page_db = ArrangePageDB()
        arrange_page_db.run()

    def hitIndexer(self):
        from  hitindexer import HitIndexer
        hitindexer = HitIndexer()
        hitindexer.run()

    def transDocList(self):
        from doclist import DocList
        doclist = DocList()
        doclist.run()

    def indexDoc(self):
        from _indexer import Indexer
        indexer = Indexer()
        indexer.run()

    def run(self):
        self.arrangePageDB()
        self.hitIndexer()
        self.transDocList()
        self.indexDoc()



class IndexerFrame:
    '''
    Indexframe 控制程序
    '''
    def __init__(self):
        indexerCtrl = IndexerCtrl()


    def index(self, request):
        return render_to_response('indexer/index.html', {})    

    def start(self, request):
        self.indexerCtrl.run()

    def status(self):
        '''
        返回相应标志
        '''
        pass

if __name__ == '__main__':
    indexerctrl = IndexerCtrl()
    indexerctrl.run()

        
        
