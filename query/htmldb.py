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
    def __init__(self):
        self.title = None
        self.xmlhtml = None
        self.dd = None
        self.docID = None

    def getHtmlNum(self):
        _len = len(HtmlInfo.objects.all())
        return _len

    def setRecordHandle(self, _id):
        _htmlinfo = HtmlInfo.objects.all()[_id]
        self.title = _htmlinfo.title
        record = (HtmlSource.objects.filter(info=_htmlinfo)[0])
        xmlcontent = record.parsed_source
        self.docID = record.id
        self.xmlhtml = xmlcontent
        self.dd = pq(self.xmlhtml)
        return _htmlinfo


    #----------content-------------------
    def getUrlDec(self):
        return self.title

    def getContent(self):
        return self.dd('content').text()

    def getTitle(self):
        return self.dd('title').attr('text')

    def getItemsText(self, tagname):
        node = self.dd(tagname)
        items = node('item')
        res = ""
        for i in range(len(items)):
            res += items.eq(i).attr('text')
        return res


    def getUrl(self):
        html = self.dd('html')
        return html.attr('url')


    def getDocID(self):
        return self.docID

    #----------end content-------------------

if __name__ == '__main__':
    htmldb = HtmlDB()
    print 'get html num', htmldb.getHtmlNum()
    print 'set handle 8',  htmldb.setRecordHandle(8)
    format1 = htmldb.getTitle() + htmldb.getUrlDec() 
    #print 'format1', format1
    format2 = htmldb.getB() + htmldb.getHOne()
    #print 'format2', format2
    format3 = htmldb.getContent() + htmldb.getHTwo()
    #print 'format3', format3
    f = open('../data/d1.txt', 'w')
    f.write(str(format1+format2+format3))
    f.close()
