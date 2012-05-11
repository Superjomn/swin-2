# -*- coding: utf-8 -*-
'''
做相关的信息搜集
然后，在搜索时返回
'''
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
sys.path.append('../')
from Config import Config
config = Config()

from django.core.management import setup_environ
sys.path.append('../../')
from swin2 import settings 
setup_environ(settings)

from pyquery import PyQuery as pq
from query.models import Record
from reptile.models import HtmlInfo, HtmlSource 

from htmldb import HtmlDB

class Collector:
    '''
    搜集相关的信息 然后返回
    '''
    def __init__(self):
        self.htmldb = HtmlDB()
        self.htmlnum = None

    def run(self):
        '''
        主程序
        '''
        self.clearRecords()

        self.htmlnum = self.htmldb.getHtmlNum()
        for i in range(self.htmlnum):
            htmlinfo = self.htmldb.setRecordHandle(i)
            dectitle = htmlinfo.title
            title = self.htmldb.getTitle()
            _content = self.htmldb.getContent()
            pagedec = self.transPageDec(_content)
            url = htmlinfo.url
            date = htmlinfo.date

            record = Record(
                        title = title,
                        dectitle = dectitle,
                        url = url,
                        decsource = pagedec,
                        date = date
                    )
            record.save()


    def transPageDec(self, source):
        length = config.getint('indexer', 'page_dec_length')
        return source[:length]
        

    def clearRecords(self):
        '''
        每次记录
        清空所有的旧的记录
        '''
        Record.objects.all().delete()


if __name__ == '__main__':
    c = Collector()
    c.run()


