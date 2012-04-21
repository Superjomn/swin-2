# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
import Queue as Q

sys.path.append('../')
from debug import *

TIMEOUT = 3

class UrlQueue:
    '''
    url队列
    '''
    def __init__(self):
        self.__queue = []
        self.__siteNum = None

    @dec
    def init(self, homeUrls):
        '''
        homeUrls is a [title, url]
        '''
        '''
        for url in homeUrls:
            self.homeUrls.append(url['title'])
        self.__siteNum = len(self.homeUrls)
        '''
        self.homeUrls = homeUrls
        self.__siteNum = len(self.homeUrls)
        self.__queue = []
        for i in range(self.__siteNum):
            self.__queue.append(Q.Queue())

    @dec 
    def initFrontPage(self):
        '''
        put homeUrl as front page to queue
        and start to run
        default: reptile get homeurl as first page to download
        '''
        for i,url in enumerate(self.homeUrls):
            print i,url
            self.__queue[i].put([url[0], ""])

    def append(self, siteID, path):
        self.__queue[siteID].put(path)

    def pop(self, siteID):
        '''
        如果需要的list为空
        则循环返回其他list的path
        '''
        #print "get siteID%d"%siteID
        assert(siteID>-1)
        assert(self.__siteNum>0)

        def getQueue(siteID):
            _i = 0
            while True:
                _i += 1

                if _i == self.__siteNum :
                    '''
                    所有的均为空
                    '''
                    return None

                siteID = (siteID+1) % self.__siteNum

                if self.__queue[siteID].qsize() == 0 :
                    pass
                else:
                    return (siteID, self.__queue[siteID].empty())

        try:
            path = self.__queue[siteID].get(timeout = TIMEOUT)
            return (siteID,  path)
        except:

            return getQueue(siteID)

    def show(self):
        for i,qu in enumerate(self.__queue) :
            print 'the %dth queue len is %d'%(i, qu.qsize() )

            for u in qu:
                print u
    
    def getNums(self):
        '''
        返回每个queue的长度
        '''
        nums = []
        for q in self.__queue:
            nums.append(q.qsize())
        return nums
            

    def getAll(self):
        return self.__queue

    def resume(self, homeurls, queues):
        '''
        queues = [
            [
                [title, path],
            ],
        ]
        '''
        _size = len(queues)
        self.init(homeurls)
        for i,queue in enumerate(queues):
            for u in queue:
                self.__queue[i].put(u)
