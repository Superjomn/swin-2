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

#self
from sourceparser.htmlparser import HtmlParser
from sourceparser.urlparser import UrlParser
from datalayer.htmldb import HtmlDB
from datalist.urlqueue import UrlQueue
from datalist.urlist import Urlist

from reptilectrl import ReptileCtrl

sys.path.append('../../')
from debug import *

class Reptile(threading.Thread):
    '''
    单个线程
    '''
    def __init__(self, name, urlQueue, urlist, Flock, homeUrls, maxPageNums, pages, curSiteID = [0], continueRun = [True]):
        '''
        pages:  记录下载的网页数目
        '''
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
        if self.__curSiteID[0] != self.__temSiteID:

            try:
                self.__conn.close()
            except:
                pass

            #print '@'*50
            #print '更新path'
            self.__temSiteID = self.__curSiteID[0]
            self.__homeurl = self.__homeUrls[self.__temSiteID]
            self.__netloc = self.urlparser.transNetloc(self.__homeurl)
            print 'netloc> ',self.__netloc
            self.__conn = httplib.HTTPConnection(self.__netloc, 80, timeout = 10)

        else:

            self.__conn = httplib.HTTPConnection(self.__netloc, 80, timeout = 10)

        return self.__conn


    def requestSource(self, path):
        conn = self.conn()
        conn.request("GET", path)
        r1 = conn.getresponse()
        data = r1.read()
        #需要对data的返回转台进行解析
        return data

    def getPage(self, path):
        print '>>path to load', path

        try:
            r = self.requestSource(path)
        except:
            r = None

        return r

    def run(self):

        while True :

            if not self.continueRun[0]:
                return 
            #从temSiteID开始 
            #print ' ..temSiteID : ', self.__temSiteID

            assert(self.__curSiteID[0] != -1)

            pathinfo = self.__urlQueue.pop(self.__curSiteID[0])
            #get (siteID, (title, path))
            #print '.. get pathinfo', pathinfo

            if not pathinfo:
                '''
                如果所有的队列均为空 则退出线程
                '''
                print '.. get pathinfo empty'
                return None

            self.__curSiteID[0] = pathinfo[0]
            self.__temHomeUrl = self.__homeUrls[self.__curSiteID[0]]
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

    def addNewInQueue(self, pageStdUrl):
        '''
        直接从html source中提取出path列表
        直接添加到各自的inqueue
        '''
        urlist = self.htmlparser.getLinks()

        for urlInfor in urlist:
            #[title, path]
            stdUrl = self.urlparser.transToStdUrl(pageStdUrl, urlInfor[1])
            siteId = self.urlparser.judgeUrl(pageStdUrl, urlInfor[1])
            path = self.urlparser.transPathByStd(stdUrl)
            
            if siteId != -1 :
                '''
                加入队列中
                '''
                if not self.__urlist.find(siteId, path) :
                    '''
                    urlist 中不重复
                    '''
                    self.__urlQueue.append(siteId, (urlInfor[0],path))


class ReptileLib(threading.Thread):
    '''
    爬虫线程库
    '''
    def __init__(self, inSignalQueue, outSignalQueue):
        '''
        全局数据控制
        '''
        #信号队列 由人机界面控制程序运行
        self.inSignalQueue = inSignalQueue
        self.outSignalQueue = outSignalQueue
        self.continueRun = [True]
        self.curSiteID = [0]
        self.urlQueue = UrlQueue()
        self.urlist = Urlist()
        self.homeUrls = []
        self.pages = []
        self.maxPages = []
        self.reptilectrl = ReptileCtrl(
            homeUrls = self.homeUrls,
            urlist = self.urlist,
            urlQueue = self.urlQueue,
            maxPages = self.maxPages,
            pages = self.pages,
        )

    def run(self):
        '''
        运行主程序
        signal:
        {
            type:type
        }
        '''
        while(True):
            signal = self.signalQueue.get()

            _type = signal['type']

            if _type is 'init':
                '''
                全新运行
                '''
                print '.. init from empty project ..'
                self.init(
                    homeUrls = signal['homeUrls'] ,
                    maxPages = signal['maxPages'] ,
                    threadNum = signal['reptileNum']
                    )

            elif _type is 'resume':
                print '.. resume from database ..'
                self.reptilectrl.resume()
            
            elif _type is 'stop':
                self.reptilectrl.stop()
            
            elif _type is 'halt':
                self.reptilectrl.halt()
            
            elif _type is 'status':
                '''
                ask for status
                '''
                self.reptilectrl.status()
                
            elif _type is 'run':
                '''
                run reptiles
                '''
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

        self.htmldb = HtmlDB(self.htmlparser)

        for i in range(len(homeUrls)):
            self.pages.append(0)

    @dec
    def initThreads(self):
        self.thlist = []

        for i in range(self.threadNum):  
            #此处前缀也需要变化
            #修改  根据站点前缀命名爬虫
            th = Reptile(
                name = "reptile%d"%i, 
                urlQueue = self.urlQueue,
                urlist = self.urlist,
                Flock = None,
                homeUrls = self.homeUrls,
                maxPageNums = [200],
                pages = self.pages,
                curSiteID = self.curSiteID,
                continueRun = self.continueRun
            )
            self.thlist.append(th)  

    @dec
    def threadsRun(self):
        for th in self.thlist:
            th.start()


