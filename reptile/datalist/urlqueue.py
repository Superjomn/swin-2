# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
import Queue as Q

sys.path.append('../../')
from debug import *

TIMEOUT = 3

class UrlQueue:
    '''
    url队列
    '''
    def __init__(self, siteNum):
        self.__queue = []
        self.__siteNum = siteNum
        for i in range(siteNum):
            self.__queue.append(Q.Queue())

    def append(self, siteID, path):
        self.__queue[siteID].put(path)

    def pop(self, siteID):
        '''
        如果需要的list为空
        则循环返回其他list的path
        '''
        print "get siteID%d"%siteID
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

            
        
        
    
    
