# -*- coding: utf-8 -*-

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

class ReptileCtrl:
    '''
    Reptile 控制程序
    将以一个控制线程的方式运行
    接受 人机界面的控制
    '''
    def __init__(self, homeUrls, urlist, urlQueue, maxPages, pages):
        '''
        需要掌握的数据:
            homeUrls
            urlist
            urlqueue
            pages
            maxpages 
        '''
        self.homeUrls = homeUrls
        self.urlist = urlist
        self.urlQueue = urlQueue
        self.pages = pages
        self.maxPages = maxPages
        self.signalQueue = signalQueue

    def stop(self):
        '''
        直接停止运行
        '''
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
        self.continueRun[0] = False
        #开始保存
        urlist = self.urlist.getAll()
        #save it 
        self.htmldb.saveList(urlist)

        urlqueue = self.urlQueue.getAll()
        #保存
        self.htmldb.saveQueue(urlqueue)

        self.htmldb.savePages(self.pages)

    def resume(self):
        '''
        resume from database
        init urlqueue and urlist
        '''
        status = self.htmldb.getStatus()
        _homeurls = status['homeurls']

        for homeurl in _homeurls:


            

        



 
