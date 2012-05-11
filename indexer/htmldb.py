# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
sys.path.append('../')
from Config import Config
config = Config()

#使用django的模型
from django.core.management import setup_environ
sys.path.append('../../')
from swin2 import settings 
setup_environ(settings)

from pyquery import PyQuery as pq

from reptile.models import HtmlInfo, HtmlSource, HomeUrl, Urlist, UrlQueue

import indexer.models as models

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
        #filetitle
        self.filetitle = _htmlinfo.filetitle

        record = (HtmlSource.objects.filter(info=_htmlinfo)[0])
        xmlcontent = record.parsed_source
        self.docID = record.id
        self.xmlhtml = xmlcontent
        self.dd = pq(self.xmlhtml)
        return _htmlinfo


    def getContentByIndex(self, _id):
        '''
        取得内容
        '''
        _htmlinfo = HtmlInfo.objects.all()[_id]
        title = _htmlinfo.title
        xmlcontent = HtmlSource.objects.filter(info=_htmlinfo)[0]
        _xmlroot = pq(xmlcontent.parsed_source)
        _xmlcontent = _xmlroot.text()
        return _xmlcontent+title


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

    def getUrl(self):
        html = self.dd('html')
        return html.attr('url')

    def getDocID(self):
        return self.docID




class ArrangePageDB:
    '''
    整理页面顺序
    将同一个站点的页面在一起
    '''
    def __init__(self):
        self.sitenum = None
        self.sites = []
        self.statusPath = config.getpath('indexer', 'status_path')

    def getSiteNum(self):
        self.sitenum = len(HomeUrl.objects.all())

    def clearOldDB(self):
        '''
        清空原有记录
        '''
        print 'delete old records'
        HtmlInfo.objects.all().delete()
        
    def clearNewDB(self):
        '''
        清空原有记录
        '''
        print 'delete new records'
        models.HtmlInfo.objects.all().delete()


    def run(self):
        '''
        !!!!!!!!!!!!!!!!!!!!
        必须在之前将 homeUrls信息记录下来
        '''
        print 'running'
        self.getSiteNum()

        #self.moveNewRecord()

        self.reverseRecord()
        print self.sites
        self.save()
        self.saveStatus(100)


    def saveStatus(self, value):
        res = 'arrange' + ' ' + str(0) + ' ' + str(0) + ' ' + str(value)
        f = open(self.statusPath, 'w')
        f.write(res)
        f.close()


    def save(self):
        print 'begin to save size'
        path = config.getpath('indexer', 'sites_num_path')
        res = ''
        for num in self.sites:
            res += str(num) + ' '
        print 'size', res

        f = open(path, 'w')
        f.write(res)
        f.close()
        


    def moveNewRecord(self):
        self.getSiteNum()
        print '.. moveNewRecord'
        '''
        将 reptile 记录进行排序 
        传入新的数据表中
        '''
        for i in range(self.sitenum):
            htmlinfos = HtmlInfo.objects.filter(siteID = i)
            #记录数目
            self.sites.append(len(htmlinfos))
            '''
            for htmlinfo in htmlinfos:
                self.saveRecord(htmlinfo)
            '''

        #HtmlInfo.objects.all().delete()
        #HtmlSource.objects.all().delete()


    def reverseRecord(self):
        '''
        排序后 将新记录返回
        重新传输到 reptile 中
        should clear all records in old database
        '''
        print '.. reverseRecord'
        htmlinfos = models.HtmlInfo.objects.all()
        for htmlinfo in htmlinfos:
            _htmlinfo = HtmlInfo(
                    siteID = htmlinfo.siteID,
                    title = htmlinfo.title,
                    url = htmlinfo.url,
                    date = htmlinfo.date
                )
            _htmlinfo.save()

            '''
            htmlsource = htmlinfo.htmlsource_set.all()[0]
            _htmlsource = HtmlSource(
                    parsed_source = htmlsource.parsed_source,
                    info = _htmlinfo
                )
            _htmlsource.save()
            '''

        #self.clearNewDB()



            

    def saveRecord(self, htmlinfo):
        '''
        导入 htmlinfo 自动进行各种记录的排序
        '''
        _htmlinfo = models.HtmlInfo(
                       siteID = htmlinfo.siteID,
                       title = htmlinfo.title,
                       url = htmlinfo.url,
                       date = htmlinfo.date
                    )
        _htmlinfo.save()

        htmlsource = htmlinfo.htmlsource_set.all()[0]
        _htmlsource = models.HtmlSource(
                        parsed_source = htmlsource.parsed_source,
                        info = _htmlinfo
                    )
        _htmlsource.save()
        

    
    

    def save(self):
        res = ''
        for i in self.sites:
            res += str(i) + ' '
        path = config.getpath('indexer', 'sites_num_path')
        f = open(path, 'w')
        f.write(res)
        f.close()








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
