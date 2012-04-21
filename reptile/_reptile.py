# -*- coding: utf-8 -*-
import threading  
import chardet
import httplib
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

        self.__Flock = Flock
        self.__curSiteID = curSiteID
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
        
        

    def conn(self):
        '''
        DNS缓存
        '''
        print '__curSiteID', self.__curSiteID[0]
        print '__temSiteID', self.__temSiteID

        '''
        self.__temSiteID = self.__curSiteID[0]
        self.__homeurl = 'http://www.cau.edu.cn'
        self.__netloc = self.urlparser.transNetloc(self.__homeurl)
        self.__conn = httplib.HTTPConnection(self.__netloc, 80, timeout = 10)
        '''

        if self.__curSiteID[0] != self.__temSiteID:

            try:
                self.__conn.close()
            except:
                print 'can not close conn'
            self.__temSiteID = self.__curSiteID[0]
            self.__homeurl = self.__homeUrls[self.__temSiteID][1]
            self.__netloc = self.urlparser.transNetloc(self.__homeurl)
            print '@'*50
            print '更新path'
            print 'homeurl', self.__homeurl
            print 'temSiteID', self.__temSiteID
            print 'netloc> ',self.__netloc
            self.__conn = httplib.HTTPConnection(self.__netloc, 80, timeout = 10)

        else:

            self.__conn = httplib.HTTPConnection(self.__netloc, 80, timeout = 10)

        return self.__conn

    @dec
    def requestSource(self, path):
        conn = self.conn()
        print '.. conn',conn
        conn.request("GET", path)
        r1 = conn.getresponse()
        data = r1.read()
        #需要对data的返回转台进行解析
        return data

    @dec
    def getPage(self, path):
        print '>>path to load', path

        try:
            r = self.requestSource(path)
        except:
            r = None

        return r

    @dec
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
            self.htmldb.saveHtml(pathinfo[1][0], pageStdUrl, htmlsource)
            if self.__pages[self.__temSiteID] == self.__maxPageNums[self.__temSiteID] :
                '''
                达到最大数量
                '''
                return

        print '.. ',self.__name, 'quit!'

    @dec
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
            print 'pageStdUrl', pageStdUrl
            stdUrl = self.urlparser.transToStdUrl(pageStdUrl, urlInfor[1])
            print '.. get STDURL', stdUrl
            siteId = self.urlparser.judgeUrl(pageStdUrl, urlInfor[1])
            print '.. get SITEID', siteId
            path = self.urlparser.transPathByStd(stdUrl)
            print '.. get PATH', path
            
            if siteId != -1 :
                '''
                加入队列中
                '''
                if not self.__urlist.find(siteId, path) :
                    '''
                    urlist 中不重复
                    '''
                    print '.. Add in Queue', path
                    self.__urlQueue.append(siteId, (urlInfor[0],path))


class ReptileLib(threading.Thread):
    '''
    爬虫线程库
    '''
    def __init__(self):
        '''
        全局数据控制
        '''
        threading.Thread.__init__(self, name = "reptilelib" )  
        print "... init ReptileLib ..."
        #信号队列 由人机界面控制程序运行
        self.inSignalQueue = Q.Queue()
        self.outSignalQueue = Q.Queue()
        self.continueRun = [True]
        self.curSiteID = [0]
        #urlQueue and init in lib
        self.urlQueue = UrlQueue()
        
        self.urlist = Urlist()
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
            outSignalQueue = self.outSignalQueue
        )
        self.controlserver = ControlServer(self.inSignalQueue, self.outSignalQueue)
        #run init thread
        self.runInit()
    
    @dec
    def runInit(self):
        '''
        run init thread 
        '''
        self.controlserver.start()
        self.start()

    @dec
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

    @dec
    def init(self, homeUrls, maxPages, threadNum):
        '''
        完全初始化
        首次运行
        '''
        self.homeUrls = homeUrls
        self.threadNum = threadNum
        self.maxPages = maxPages
        #pages
        self.pages = []
        
        #self.htmldb = HtmlDB(self.htmlparser)
        #init self.pages 
        #self.pages used to calculate num of pages downloaded
        for i in range(len(homeUrls)):
            self.pages.append(0)

        #init urlQueue
        self.urlQueue.init(self.homeUrls)
        self.urlQueue.initFrontPage()
        self.urlist.init(len(self.homeUrls))

    @dec
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
                Flock = None,
                homeUrls = self.homeUrls,
                maxPageNums = self.maxPages,
                pages = self.pages,
                curSiteID = self.curSiteID,
                continueRun = self.continueRun
            )
            self.thlist.append(th)  


    @dec
    def threadsRun(self):
        for th in self.thlist:
            th.start()

if __name__ == '__main__':
    reptilelib = ReptileLib()
    

