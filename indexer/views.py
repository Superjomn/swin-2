# -*- coding: utf-8 -*-
from django.template.loader import get_template
from django.template import Context
from django.http import HttpResponse

import sys
sys.path.append('../')
from Config import Config
config = Config()


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
        #标志现在工作状态
        self.cur_type = ''
        #progress 
        self.status = {}
        self.indexerCtrl = IndexerCtrl()
        self.satusPath = config.getpath('indexer', 'status_path')

    
    def initStatus(self):
        _types = ['arrange', 'hitindexer', 'doclist', 'indexer']
        for _type in types:
            status = [0,0,0]    #htmlNum #curNum #radio
            self.status[_type] = status

    def index(self, request):
        t = get_template('indexer/index.html')
        html = t.render(Context({}))
        return HttpResponse(html)


    def init_info(self, request):
        t = get_template('indexer/init-info.html')
        html = t.render(Context({}))
        return HttpResponse(html)


    def start(self, request):
        self.indexerCtrl.run()

    def status(self, request):
        '''
        返回相应标志
        '''
        t = get_template('indexer/status.html')

        f = open(self.statusPath)
        c = f.read()
        f.close()

        words = c.split()
        
        self.status[words[0]] = [ int(word) for word in words[1:]]

        html = t.render(Context({'status': self.status }))
        return HttpResponse(html)







if __name__ == '__main__':
    indexerctrl = IndexerCtrl()
    indexerctrl.run()

        
        
