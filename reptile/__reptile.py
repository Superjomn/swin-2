# -*- coding: utf-8 -*-
import threading  
import chardet
import urllib2  
import StringIO  
import gzip  
import string  


import sys
reload(sys)
sys.setdefaultencoding('utf-8')

from pyquery import PyQuery as pq
import xml.dom.minidom as dom
import socket
import Queue as Q

#self
sys.path.append('../')
from Config import Config
from sourceparser.htmlparser import HtmlParser
from sourceparser.urlparser import UrlParser
from htmldb import HtmlDB
from datalist.urlqueue import UrlQueue
from datalist.urlist import Urlist

from reptilectrl import ReptileCtrl
from control_center_server import ControlServer

from debug import *
_config = Config()

class Reptile(threading.Thread):
    '''
    单个线程
    '''
    def __init__(self, name, urlQueue, urlist, Flock, homeUrls, maxPageNums, pages, curSiteID = [0], continueRun = [True]):
        '''
        pages:  记录下载的网页数目
        '''
        self.__name = name
        threading.Thread.__init__(self, name = name )  
        #own data
        self.__pages = pages
        self.__homeUrls = homeUrls
        self.__urlist = urlist
        self.__urlQueue = urlQueue
        self.Flock = Flock
        self.__curSiteID = [0]#curSiteID
        self.__temSiteID = -1
        self.__conn = None
        self.__homeurl = None
        self.continueRun = continueRun
        #some information to send to UserFrame ----
        #num of downloaded pages
        self.__maxPageNums = maxPageNums
        #记录下载的页面数目
        self.__netloc = None
        #---------------------
        self.urlparser = UrlParser(homeUrls)
        self.htmlparser = HtmlParser(self.urlparser)
        self.htmldb = HtmlDB(self.htmlparser)
        

    def requestSource(self, url):
        request = urllib2.Request(url) 
        request.add_header('Accept-encoding', 'gzip')

        try:            
            page = opener.open(request,timeout=2) #设置超时为2s

            if page.code == 200:      
                predata = page.read()
                pdata = StringIO.StringIO(predata)
                gzipper = gzip.GzipFile(fileobj = pdata)  
                
                try:  
                    data = gzipper.read()  
                except(IOError):  
                    data = predata
                    
                try:  
                    if len(data)<300:
                        return False
                    #begain to parse the page
                    return data

                except:  
                    print 'not a useful page'
            page.close()  
        except:  
            print 'end error'  


    def getPage(self, url):

        try:
            r = self.requestSource(url)
        except:
            r = None

        return r

    def run(self):

        while True :

            if not self.continueRun[0]:
                print self.__name,"stopped!"
                return 
            #从temSiteID开始 
            print '.. temSiteID : ', self.__temSiteID

            assert(self.__curSiteID[0] != -1)

            pathinfo = self.__urlQueue.pop(self.__curSiteID[0])
            #get (siteID, (title, path))
            print '.. get pathinfo', pathinfo

            if not pathinfo:
                '''
                如果所有的队列均为空 则退出线程
                '''
                print '.. get pathinfo empty'
                #return None
                break

            self.__curSiteID[0] = pathinfo[0]
            print '.. curSite', self.__curSiteID[0] 
            print '.. homeurls', self.__homeUrls
            self.__temHomeUrl = self.__homeUrls[self.__curSiteID[0]][1]
            #print '.. get cursiteid', self.__curSiteID

            #print 'the path is ', pathinfo[1][1]
            try:
                htmlsource = self.getPage(pathinfo[1][1])
            except:
                print 'pathinfo bool'
                continue

            if not htmlsource:
                print 'htmlsource is wrong'
                continue

            print '.. get htmlsource len', len(htmlsource)
            
            #判断是否为html源码
            if not self.htmlparser.init(htmlsource) :
                print '.. source is not html'
                continue
            #添加 path 到队列中
            pageStdUrl = self.urlparser.transToStdUrl(self.__temHomeUrl, pathinfo[1][1])
            
            self.addNewInQueue(pageStdUrl)

            #处理源码为xml文件 存储到数据库
            print '.. start to save html'
            self.__pages[self.__temSiteID] += 1

            self.Flock.acquire()
            self.htmldb.saveHtml(self.__curSiteID[0], pathinfo[1][0], pageStdUrl, htmlsource)
            self.Flock.release()

            if self.__pages[self.__temSiteID] == self.__maxPageNums[self.__temSiteID] :
                '''
                达到最大数量
                '''
                return

        print '.. ',self.__name, 'quit!'

    def addNewInQueue(self, pageStdUrl):
        '''
        直接从html source中提取出path列表
        直接添加到各自的inqueue
        '''
        urlist = self.htmlparser.getLinks()
        print 'get urlist'
        for url in urlist:
            print url[0], url[1]

        for urlInfor in urlist:
            #[title, path]
            #print 'pageStdUrl', pageStdUrl
            stdUrl = self.urlparser.transToStdUrl(pageStdUrl, urlInfor[1])
            #print '.. get STDURL', stdUrl
            siteId = self.urlparser.judgeUrl(pageStdUrl, urlInfor[1])
            #print '.. get SITEID', siteId
            path = self.urlparser.transPathByStd(stdUrl)
            #print '.. get PATH', path
            
            if siteId != -1 :
                '''
                加入队列中
                '''
                if not self.__urlist.find(siteId, path) :
                    '''
                    urlist 中不重复
                    '''
                    print '.. Add in Queue', path
                    self.Flock.acquire()
                    self.__urlQueue.append(siteId, (urlInfor[0] ,path))
                    self.Flock.release()


class ReptileLib(threading.Thread):
    '''
    爬虫线程库
    '''
    def __init__(self):
        '''
        全局数据控制
        '''
        self.htmldb = HtmlDB()
        threading.Thread.__init__(self, name = "reptilelib" )  
        print "... init ReptileLib ..."
        #信号队列 由人机界面控制程序运行
        self.inSignalQueue = Q.Queue()
        self.outSignalQueue = Q.Queue()
        self.Flock = threading.RLock()  

        #控制reptile线程是否运行
        self.continueRun = [True]
        #控制reptilelib 主程序及服务器是否运行 是否完全关闭
        self.reptileLibRun = [True]

        self.curSiteID = [0]
        #urlQueue and init in lib
        self.urlQueue = UrlQueue()
        
        self.urlist = Urlist()
        #为了列表的共享性 初始的数据初始化[] 之后不能随意改变
        self.homeUrls = []
        self.pages = []
        self.maxPages = []
        self.reptilectrl = ReptileCtrl(
            homeUrls = self.homeUrls,
            continueRun = self.continueRun,
            urlist = self.urlist,
            urlQueue = self.urlQueue,
            maxPages = self.maxPages,
            pages = self.pages,
            outSignalQueue = self.outSignalQueue,
        )
        self.controlserver = ControlServer(self.inSignalQueue, self.outSignalQueue)
        #run init thread
        self.runInit()
    
    def runInit(self):
        '''
        run init thread 
        '''
        self.controlserver.start()
        self.start()

    def run(self):
        '''
        运行主程序
        signal:
        {
            type:type
        }
        '''
        print "... run while ..."

        while True:
            print '.. while ReptileLib running ..'
            signal = self.inSignalQueue.get()
            print 'get signal', signal
            _type = signal['type']
            print 'get type', _type

            if _type is 'init':
                '''
                全新运行
                '''
                print '.. init from empty project ..'
                self.init(
                    homeUrls = signal['homeurls'] ,
                    maxPages = signal['maxpages'] ,
                    threadNum = signal['reptilenum']
                    )

            elif _type is 'resume':
                print '.. resume from database ..'
                self.reptilectrl.resume()
            
            elif _type is 'stop':
                print '.. stop ..'
                self.reptilectrl.stop()
            
            elif _type is 'halt':
                print '.. halt ..'
                self.reptilectrl.halt()
            
            elif _type is 'status':
                '''
                ask for status
                '''
                print '.. status ..'
                #put status in queue
                self.reptilectrl.status()
                
            elif _type is 'start':
                '''
                run reptiles
                '''
                print '.. run reptile threads ..'
                print 'It works!'
                self.continueRun[0] = True
                self.initThreads()
                self.threadsRun()

        print 'ReptileLib core stopped!'
        print 'Reptile stopped'

    def init(self, homeUrls, maxPages, threadNum):
        '''
        完全初始化
        首次运行
        注意： 重复init时，为了list的共享数据特性
        每次需要清空[] 然后再重新赋值
        '''
        def clearList(_List):
            if not _List: return
            _size = len(_List)
            for i in range(_size):
                _List.pop()

        def initList(_List, List):
            #first clear list
            clearList(_List)
            for l in List:
                _List.append(l)

        initList(self.homeUrls ,homeUrls)
        initList(self.maxPages, maxPages)
        self.threadNum = threadNum
        self.maxPages = maxPages
        
        #self.htmldb = HtmlDB(self.htmlparser)
        #init self.pages 
        #self.pages used to calculate num of pages downloaded
        clearList(self.pages)
        for i in range(len(homeUrls)):
            self.pages.append(0)

        #init urlQueue
        self.urlQueue.init(self.homeUrls)
        self.urlQueue.initFrontPage()
        self.urlist.init(len(self.homeUrls))

        #存储 homeUrls
        self.htmldb.saveHomeUrls(homeUrls, maxPages, self.pages)


    def initThreads(self):
        self.thlist = []
        #default: from site 0
        self.curSiteID[0] = 0

        for i in range(self.threadNum):  
            #此处前缀也需要变化
            #修改  根据站点前缀命名爬虫
            th = Reptile(
                name = "reptile%d"%i, 
                urlQueue = self.urlQueue,
                urlist = self.urlist,
                Flock = self.Flock,
                homeUrls = self.homeUrls,
                maxPageNums = self.maxPages,
                pages = self.pages,
                curSiteID = self.curSiteID,
                continueRun = self.continueRun
            )
            self.thlist.append(th)  


    def threadsRun(self):
        for th in self.thlist:
            th.start()

if __name__ == '__main__':
    reptilelib = ReptileLib()
    
