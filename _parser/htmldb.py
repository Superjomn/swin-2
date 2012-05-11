# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
sys.path.append('../')

#使用django的模型
from django.core.management import setup_environ
sys.path.append('../../')
from swin2 import settings 
setup_environ(settings)

from pyquery import PyQuery as pq

from reptile.models import HtmlInfo, HtmlSource, HomeUrl, Urlist, UrlQueue
from debug import *

class HtmlDB:
    def getHtmlNum(self):
        _len = len(HtmlInfo.objects.all())
        return _len


    def getContentByIndex(self, _id):
        self.setRecordHandle(_id)
        format1 = self.getTitle() + self.getUrlDec() 
        format2 = self.getB() + self.getHOne()
        format3 = self.getContent() + self.getHTwo()

        '''
        res = ""
        res += self.getTitle()
        res += self.getUrlDec()
        for tag in ['b','h1','h2','h3','h4']:
            res += self.getItemsText(tag)
        res += self.getContent()
        '''
        
        return format1 + format2 + format3

    def setRecordHandle(self, _id):
        _htmlinfo = HtmlInfo.objects.all()[_id]
        self.title = _htmlinfo.title
        record = (HtmlSource.objects.filter(info=_htmlinfo)[0])
        xmlcontent = record.parsed_source
        self.docID = record.id
        self.xmlhtml = xmlcontent
        self.dd = pq(self.xmlhtml)
        self.filetitle = _htmlinfo.filetitle
        return _htmlinfo

    def getItemsText(self, tagname):
        node = self.dd(tagname)
        items = node('item')
        res = ""
        for i in range(len(items)):
            res += items.eq(i).attr('text')

        return res

    def getB(self):
        '''
        取得B标签内容
        '''
        return self.getItemsText('b')


    def getHOne(self):
        t1 = self.getItemsText('h1')
        t2 = self.getItemsText('h2')
        return t1+t2+self.filetitle



    def getHTwo(self):
        t3 = self.getItemsText('h3')
        t4 = self.getItemsText('h4')
        return t3+t4




    def getTitle(self):
        return self.dd('title').attr('text')

    def getUrlDec(self):
        return self.title

    def getContent(self):
        return self.dd('content').text()


if __name__ == '__main__':
    htmldb = HtmlDB()
    for i in range(100):
        content = htmldb.getContentByIndex(8)
        print content
    '''
    f = open('../data/d2.txt', 'w')
    f.write(content)
    f.close()
    '''

        
    
