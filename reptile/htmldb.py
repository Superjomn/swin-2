# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
from datetime import date

#使用django的模型
from django.core.management import setup_environ
sys.path.append('../../')
import swin2.settings as settings
setup_environ(settings)
sys.path.append('../')
from reptile.models import HtmlInfo, HtmlSource, HomeUrl, Urlist, UrlQueue

#sys.path.append('../../')
#from debug import *

class HtmlDB:
    '''
    Html处理及存储层
    '''
    def __init__(self, htmlparser):
        #此处urlparser 和 htmlparser都已经在外界更新过
        self.htmlparser = htmlparser

    def saveHomeUrls(self, homeUrls, maxPages, pages):
        for i,homeurl in enumerate(homeUrls) :
            homeurl = HomeUrl(
                title = homeurl[0],
                url = homeurl[1],
                maxpages = maxPages[i],
                pages = pages[i]
            )
            homeurl.save()
            
    def saveHtml(self, _title, stdUrl, _source):
        _source = self.htmlparser.transcode(_source)
        today = date.today()
        #_date = today.strftime("%y-%m-%d")
        #存储网页信息
        print '.. save htmlinfo'
        htmlinfo = HtmlInfo(title=_title, url=stdUrl, date=today)
        htmlinfo.save()
        xmltext = self.htmlparser.transXML(stdUrl)
        #print '.. save htmlsource'
        htmlsource = HtmlSource(parsed_source=xmltext, info=htmlinfo)
        htmlsource.save()

    def saveList(self, urlist):
        '''
        save  urlist
        urlist = [ [] [] ]
        '''
        for i,_list in enumerate(urlist):
            for path in _list:
                u = Urlist(i, path)
                u.save()

    def saveQueue(self, urlqueue):
        '''
        urlqueue = [Queue, Queue]
        '''
        for i,queue in enumerate(urlqueue):
            size = queue.qsize()

            for j in range(size):
                u = UrlQueue( i, queue.get() )
                u.save()

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

    def getHomeUrls(self):
        '''
        get homeurls
        '''
        return HomeUrl.objects.all()

    def getList(self):
        '''
        get urlist
        '''
        homeurls = self.getHomeUrls()
        _list = []

        for homeurl in homeurls:

            _list.append(homeurl.urlist_set())

        return _list
            
    def getPages(self):
        homeurls = self.getHomeUrls()
        pages = []

        for homeurl in homeurls:
            pages.append( homeurl['pages'] )
        return pages

    def getQueue(self):
        '''
        get urlqueue
        '''
        homeurls = self.getHomeUrls()
        _queue = []

        for homeurl in homeurls:
            _queue.append(homeurl.urlqueue_set())

    def getStatus(self):
        status = {}
        status['homeurls'] = self.getHomeUrls()
        status['list'] = self.getList()
        status['queue'] = self.getQueue()
        status['pages'] = self.getPages()
        return status

    
if __name__ == '__main__':
    htmlinfo = HtmlInfo(title="try:中国农业大学", url="http://www.cau.edu.cn", date="2012-4-17")
    print "html source save"
    htmlinfo.save()

    xmlsource = "<html></html>"
    htmlsource = HtmlSource(parsed_source = xmlsource, info=htmlinfo)
    print "htmlsource save"
    htmlsource.save()


        


