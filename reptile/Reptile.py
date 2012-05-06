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
from sourceparser.fileparser import ImageParser, TextFileParser
from sourceparser.urlparser import UrlParser
from htmldb import HtmlDB
from datalist.urlqueue import UrlQueue
from datalist.urlist import Urlist

from reptilectrl import ReptileCtrl
from controlServer import ControlServer

from debug import *
_config = Config()

class Reptile(threading.Thread):
    '''
    单个线程
    '''
    def __init__(self, name, urlQueue, urlist, Flock, homeUrls, maxPageNums, pages, imagenum, continueRun = [True]):
        '''
        pages:  记录下载的网页数目
        '''
        print '@'*50
        print '.. Reptile, get imagenum', imagenum, type(imagenum)
        print '@'*50

        self.__name = name
        threading.Thread.__init__(self, name = name )  
        #own data
        self.__homeUrls = homeUrls
        self.__urlist = urlist
        self.__urlQueue = urlQueue
        self.Flock = Flock
        self.__curSiteID = [0]#curSiteID
        self.__temSiteID = -1
        self.__homeurl = None
        self.__pageinfo = None
        self.continueRun = continueRun
        #some information to send to UserFrame ----
        #num of downloaded pages
        self.__maxPageNums = maxPageNums
        #记录下载的页面数目
        self.pages = pages
        self.imagenum = imagenum
        print '@'*50
        print 'get self.imagenum', self.imagenum, type(self.imagenum)
        print '@'*50
        #---------------------
        self.urlparser = UrlParser(homeUrls)
        self.htmlparser = HtmlParser(self.urlparser)
        self.htmldb = HtmlDB(self.htmlparser)
        self.imageparser = ImageParser(name)
        self.textfileparser = TextFileParser()
        
        

    def requestSource(self, url):
        request = urllib2.Request(url) 
        request.add_header('Accept-encoding', 'gzip')

        try:            
            page = self.opener.open(request,timeout=2) #设置超时为2s

            if page.code == 200:      
                predata = page.read()
                pdata = StringIO.StringIO(predata)
                gzipper = gzip.GzipFile(fileobj = pdata)  
                
                try:  
                    data = gzipper.read()  
                except(IOError):  
                    data = predata
                    
                if len(data)<300:
                    return False
                #begain to parse the page
                return data

            page.close()  
        except:  
            print 'time out'  

    def underPageLimit(self):
        '''
        是否 某个站点的收录页面超出限制
        '''
        _type = self.urlparser.typeDetect(self.__pathinfo.url)[0]
        #如果 type 为‘’ 表示网页  image/doc表文件
        if _type:
            #对图片等文件不作计数
            return True

        if self.pages[self.__temSiteID] >= self.__maxPageNums[self.__temSiteID] :
            return False
        return True



    def run(self):
        ''' 运行主陈需 '''

        self.opener = urllib2.build_opener()     

        while self.continueRun[0] :
            self.Flock.acquire()
            self.__pathinfo = self.__urlQueue.pop()
            self.Flock.release()
            print '.. get pathinfo', self.__pathinfo.url, self.__name
            #get (siteID, (title, path))

            if not self.__pathinfo:
                '''
                如果所有的队列均为空 则退出线程
                '''
                print '.. get pathinfo empty'
                #return None
                break

            #self.__curSiteID[0] = pathinfo[0]
            self.__temSiteID = self.__pathinfo.siteID
            self.__temHomeUrl = self.__homeUrls[self.__temSiteID]
                        
            #判断是否超过限制页数
            if not self.underPageLimit():
                continue

            #print '.. curSite', self.__curSiteID[0] 
            #print '.. homeurls', self.__homeUrls
            #print '.. get cursiteid', self.__curSiteID
            #print 'the path is ', pathinfo[1][1]
            source = self.requestSource(self.__pathinfo.url)

            if not source:
                print 'htmlsource is empty'
                continue

            filetype = self.urlparser.typeDetect(self.__pathinfo.url)
            _type = filetype[0]
            print '.. get file type', filetype, self.__name

            if not _type:
                self.dealHtml(source)
            elif _type == 'image':
                self.dealImage(source, filetype[1])
                print 'self.imagenum', self.imagenum
                self.imagenum[0] += 1
            else:
                self.dealDoc()
                self.imagenum[0] += 1

            #处理源码为xml文件 存储到数据库
            #print '.. start to save html'

        #print '.. ',self.__name, 'quit!'


    def dealHtml(self, source):
        '''
        对 html文件 从解析到存储的完整操作
        '''
        print '.. get source len', len(source)
        #过短视为无效
        if len(source) < 300:
            return
        #判断是否为html源码
        if not self.htmlparser.init(source) :
            print '.. source is not html'
            return
        #开始进行处理
        #从 urlqueue中取得的url 已经为 绝对地址
        self.pages[self.__temSiteID] += 1
        #取得links srcs列表
        urlist = self.htmlparser.getLinks()
        urlist += self.htmlparser.getSrcs()
        #save html
        self.Flock.acquire()
        docID = self.htmldb.saveHtml(self.__pathinfo.siteID, self.__pathinfo.title, self.__pathinfo.url, source)
        self.Flock.release()

        self.addNewInQueue(docID, self.__pathinfo.url, urlist)



    def dealImage(self, source, extention):
        '''
        对 image文件 从解析到存储的完整操作
        '''
        self.imageparser.deal(source, extention, self.__pathinfo.url, self.__pathinfo.toDocID)

    
    def dealDoc(self):
        '''
        对 doc文件 从解析到存储的完整操作
        '''
        self.textfileparser.deal(
            self.__pathinfo.title, 
            self.__pathinfo.url, 
            self.__pathinfo.toDocID)


    def addNewInQueue(self, docID, pageStdUrl, urlist):
        '''
        直接从html source中提取出path列表
        直接添加到各自的inqueue
        docID:  以及存储的page id
        urlist: html 及 文件地址混合列表
        '''
        #连同图片进行处理
        #图片也需要进行绝对化和判断是否重复等操作
        #print 'get urlist'
        #for url in urlist:
            #print url[0], url[1]
        for urlInfor in urlist:
            #[title, path]
            #print 'pageStdUrl', pageStdUrl
            stdUrl = self.urlparser.transToStdUrl(pageStdUrl, urlInfor[1])
            #print '.. get STDURL', stdUrl
            siteID = self.urlparser.judgeUrl(pageStdUrl, urlInfor[1])
            _type = self.urlparser.typeDetect(stdUrl)[0]
            #print '.. get SITEID', siteID
            #path = self.urlparser.transPathByStd(stdUrl)
            #print '.. get PATH', path
            
            if siteID != -1 :
                '''
                加入队列中
                '''
                #if not _type:
                    #正常网页
                if not self.__urlist.find(stdUrl) :
                    '''
                    urlist 中不重复
                    '''
                    print '.. Add in Queue', stdUrl, _type

                    if not _type:
                        #网页
                        self.Flock.acquire()
                        #siteID toDocID urlinfo
                        self.__urlQueue.append(siteID, -1, (urlInfor[0], stdUrl))
                        self.Flock.release()
                    else:
                        #图片 及 其他文件
                        self.Flock.acquire()
                        #siteID toDocID urlinfo
                        self.__urlQueue.append(siteID, docID,  (urlInfor[0], stdUrl))
                        self.Flock.release()

                '''
                else:
                    #image / doc 等文件 需要注册toSiteID
                    self.Flock.acquire()
                    #siteID toDocID urlinfo
                    self.__urlQueue.append(siteID, -1, (urlInfor[0], stdUrl))
                    self.Flock.release()
                '''
                        




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
        self.continueRun = [False]
        #控制reptilelib 主程序及服务器是否运行 是否完全关闭
        self.reptileLibRun = [True]

        #urlQueue and init in lib
        self.urlQueue = UrlQueue()
        
        self.urlist = Urlist()
        #为了列表的共享性 初始的数据初始化[] 之后不能随意改变
        self.homeUrls = []
        self.pages = []
        self.imagenum  = []
        self.imagenum.append(0)
        print '-'*50
        print '.. init self.imagenum', self.imagenum, type(self.imagenum)
        print '-'*50
        self.maxPages = []
        
        self.reptilectrl = ReptileCtrl(
            homeUrls = self.homeUrls,
            continueRun = self.continueRun,
            urlist = self.urlist,
            urlQueue = self.urlQueue,
            maxPages = self.maxPages,
            pages = self.pages,
            imagenum = self.imagenum,
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
                if not self.continueRun[0]:
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
        #self.urlist.init(len(self.homeUrls))

        #存储 homeUrls
        self.htmldb.saveHomeUrls(homeUrls, maxPages, self.pages)


    def initThreads(self):
        self.thlist = []
        #default: from site 0
        print '$'*50
        print 'init thread imagenum', self.imagenum, type(self.imagenum)
        print '$'*50

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
                imagenum = self.imagenum,
                continueRun = self.continueRun
            )
            self.thlist.append(th)  


    def threadsRun(self):
        for th in self.thlist:
            th.start()

if __name__ == '__main__':
    reptilelib = ReptileLib()
    

