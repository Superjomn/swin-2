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
    def __init__(self, homeUrls, urlist, urlQueue, maxPages, pages, outSignalQueue):
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
        #向控制端陈需传递消息
        self.outSignalQueue = outSignalQueue

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
        
        self.htmldb.saveHomeUrls(self.homeUrls, self.maxPages, self.pages)
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
        # resume homeurls, maxpages, pages
        for site in _homeurls:
            homeurl = [ site['title'], site['url'] ]
            self.homeUrls.append(homeurl)
            self.maxPages.append( site['maxpages'] )
            self.pages.append( site['pages'] )
        #resume urlqueue
        _queue = status['queue']
        
        for i,queue in enumerate(_queue):
            for q in queue:
                self.urlQueue.append(i, [ q['title'], q['path'] ] )
        #resume urlist
        _list = status['list']
        
        for i,list in enumerate(_list):
            for l in list:
                self.urlist.find(i, l['path'])
                
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
        self.outSignalQueue.append( signal )
            
            


            
