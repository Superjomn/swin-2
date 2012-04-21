# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
import time
sys.path.append('../')
from Config import Config
from sourceparser.urlparser import UrlParser
from htmldb import HtmlDB
from sourceparser.htmlparser import HtmlParser

config = Config()
halt_wait_time = config.getint('reptilelib', 'halt_wait_time')

class ReptileCtrl:
    '''
    Reptile 控制程序
    将以一个控制线程的方式运行
    接受 人机界面的控制
    '''
    def __init__(self, homeUrls, continueRun, urlist, urlQueue, maxPages, pages, outSignalQueue):
        '''
        需要掌握的数据:
            homeUrls
            urlist
            urlqueue
            pages
            maxpages 
        '''
        self.homeUrls = homeUrls
        #continue weather reptils continue run
        self.continueRun = continueRun
        self.urlist = urlist
        self.urlQueue = urlQueue
        self.pages = pages
        self.maxPages = maxPages
        #向控制端陈需传递消息
        self.outSignalQueue = outSignalQueue

        self.urlparser = UrlParser(homeUrls)
        self.htmlparser = HtmlParser(self.urlparser)
        self.htmldb = HtmlDB(self.htmlparser)

    def stop(self):
        '''
        直接停止运行
        '''
        print '.. stop ..'
        self.continueRun[0] = False

    def halt(self):
        '''
        中断
        保存:
            urlist
            urlqueue
            pages
            maxpages
        '''
        print '.. halt ..'
        
        self.continueRun[0] = False
        #should use timer to sleep for some seconds 
        time.sleep(halt_wait_time)

        self.htmldb.saveHomeUrls(self.homeUrls, self.maxPages, self.pages)
        #开始保存
        urlist = self.urlist.getAll()
        #save it 
        self.htmldb.saveList(urlist)

        urlqueue = self.urlQueue.getAll()
        #保存
        self.htmldb.saveQueue(urlqueue)

    def resume(self):
        '''
        resume from database
        init urlqueue and urlist
        '''
        def clearList(_List):
            _size = len(_List)
            for i in range(_size):
                _List.pop()

        def resumeHomeurl(homeurls):
            '''
            homeurls=
                [
                    [title, url],
                ]
            '''
            #clear [] to empty
            clearList(self.homeUrls)
            for u in homeurls:
                self.homeUrls.append(u)

        def resumePages(localpages, pages):
            '''
            resume pages or maxpages
            maxpages = [
                1,2,3,
            ]
            '''
            clearList(localpages)
            for i in pages:
                localpages.append(i)

        status = self.htmldb.getStatus()
        _homeurls = status['homeurls']
        resumeHomeurl(_homeurls)
        #resume maxpages
        resumePages(self.maxPages, status['maxpages'])
        #resume pages
        resumePages(self.pages, status['pages'])
        #resume urlist
        self.urlist.resume(status['urlist'])
        #resume urlqueue
        self.urlQueue.resume(status['homeurls'], status['urlqueue'])
        
               
    def status(self):
        '''
        return status
        '''
        _queue_num = []

        signal = {
            'type': 'status',
            'pages': self.pages,
            'queue_num': self.urlQueue.getNums(),
            'list_num': self.urlist.getNums(),
         }
        print signal
        #self.outSignalQueue.append( signal )
            
