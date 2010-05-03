# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
sys.path.append('../')
from datetime import date

#使用django的模型
from django.core.management import setup_environ
sys.path.append('../../')
from swin2 import settings 
setup_environ(settings)
from reptile.models import HtmlInfo, HtmlSource, HomeUrl, Urlist, UrlQueue
from debug import *

class HtmlDB:
    '''
    Html处理及存储层
    '''
    def __init__(self, htmlparser=None):
        #此处urlparser 和 htmlparser都已经在外界更新过
        self.htmlparser = htmlparser

    #---------------------------------------------------------------------
    #   缓存操作
    #---------------------------------------------------------------------
    

    def saveUrlQueue(self, url, siteID):

        '''
        内存中的url存储到数据库中
        '''
        u = UrlQueue(
            siteID = siteID,
            title = url[0],
            path = url[1]
        )
        u.save()
        return u.id

    def getCacheUrl(self, _id):
        '''
        取回urlqueue
        并且删除记录
        '''
        u = UrlQueue.objects.filter(id=_id)[0]
        res = []
        res.append( u.title )
        res.append( u.path )
        #删除记录
        u.delete()
        return res

    #---------------------------------------------------------------------
    #   resume 操作
    #---------------------------------------------------------------------

    @dec
    def saveHomeUrls(self, homeUrls, maxPages, pages):
        print '.. homeUrl', homeUrls
        print '.. maxPages', maxPages
        print '.. pages', pages
        print '.. clear all homeurls from database'
        HomeUrl.objects.all().delete()

        for i,homeurl in enumerate(homeUrls) :
            homeurl = HomeUrl(
                title = homeurl[0],
                url = homeurl[1],
                maxpages = maxPages[i],
                pages = pages[i]
            )
            homeurl.save()
            
    def saveHtml(self, siteID, _title, stdUrl, _source):
        _source = self.htmlparser.transcode(_source)
        today = date.today()
        #_date = today.strftime("%y-%m-%d")
        #存储网页信息
        print '.. save htmlinfo'
        htmlinfo = HtmlInfo(siteID = siteID, title=_title, url=stdUrl, date=today)
        htmlinfo.save()
        xmltext = self.htmlparser.transXML(stdUrl)
        #print '.. save htmlsource'
        htmlsource = HtmlSource(parsed_source=xmltext, info=htmlinfo)
        htmlsource.save()

    @dec
    def saveList(self, urlist):
        '''
        resume操作 将内存中的记录存储到数据库中
        save  urlist
        urlist = [ [] [] ]
        '''
        #print 'len of urlist', len(urlist)
        #print '.. clear former lists'
        Urlist.objects.all().delete()

        for i,_list in enumerate(urlist.getAll()):
            '''
            [ [] ]
            '''
            #print 'i',i
            site = HomeUrl.objects.all()[i]
            for hv in _list:
                u = Urlist(site=site, hashvalue=hv)
                u.save()

    @dec
    def saveQueue(self, urlqueue):
        '''
        urlqueue = [Queue, Queue]
        resume操作 将内存中的记录存储到数据库中
        '''
        #print 'urlqueue', urlqueue
        #print '.. clear former urlqueues'
        UrlQueue.objects.all().delete()
        for i,queue in enumerate(urlqueue):
            size = queue.qsize()
            print 'size',size
            site = HomeUrl.objects.all()[i]

            for j in range(size):
                urlid = queue.get()
                print url
                u = UrlQueue(
                    site=site, 
                    urlid=urlid
                )
                u.save()
    @dec
    def saveStatus(self, urlist, urlqueue, pages):
        '''
        save:
            urlist
            urlqueue
            pages
        '''
        self.saveList(urlist)
        self.saveQueue(urlqueue)
        self.savePages(pages)

    @dec
    def getStatus(self):
        '''
        get homeurls
        '''
        homeurls = HomeUrl.objects.all()
        res = {}
        #homeurls
        _homeurls = []
        _maxpages = []
        _pages = []
        for u in homeurls:
            item = [ u.title, u.url ]
            _homeurls.append(item)
            _maxpages.append( u.maxpages )
            _pages.append( u.pages )

        res['homeurls'] = _homeurls
        res['maxpages'] = _maxpages
        res['pages'] = _pages
        res['urlist'] = self.getList()
        print res['urlist']
        res['urlqueue'] = self.getQueue()

        return res


    @dec
    def getList(self):
        '''
        get urlist
        '''
        homeurls = HomeUrl.objects.all()
        lists = []

        for homeurl in homeurls:
            _list = homeurl.urlist_set.all()
            _res = []
            for l in _list:
                _res.append(l.path)
            lists.append(_res)

        return lists
            

    def getQueue(self):
        '''
        get urlqueue
        '''
        homeurls = HomeUrl.objects.all()
        queues = []

        for homeurl in homeurls:
            _queue = homeurl.urlqueue_set.all()
            _res = []
            for q in _queue:
                _res.append( [q.title, q.path] )
            queues.append(_res)

        return queues

    
if __name__ == '__main__':
    htmldb = HtmlDB(None)
    url = ['cau','./index.php']
    id = htmldb.saveUrlQueue(url, 3)
    print 'id',id


