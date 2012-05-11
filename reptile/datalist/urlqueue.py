# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
import Queue as Q
import thread

sys.path.append('../')
from debug import *
from htmldb import HtmlDB
#from sourceparser.htmlparser import HtmlParser
#from sourceparser.urlparser import UrlParser


TIMEOUT = 3
class UrlQueue:
    '''
    url队列
    '''
    def __init__(self):
        self.__siteNum = None
        self.sizes = []
        self.size = 0

    def init(self, homeUrls):
        '''
        homeUrls is a [title, url]
        '''
        self.homeUrls = homeUrls
        self.htmldb = HtmlDB(None)      #self.htmlparser)
        self.clear()
        self.__siteNum = len(self.homeUrls)
        for i in range(self.__siteNum):
            self.sizes.append(0)

    def clear(self):
        '''
        在一次全新项目时 清空整个urlqueue
        '''
        self.htmldb.clearUrlQueue()

    def append(self, siteID, toDocID, stdUrlInfo):
        '''
        stdUrlInfo = [title, url]
        toSiteID: 附属于的网页编号 -1:正常网页 >0 文件
        输入时 url 必须为绝对地址
        '''
        self.htmldb.saveUrlQueue( stdUrlInfo, siteID, toDocID)
        self.size += 1
        self.sizes[siteID] += 1
        
    def initFrontPage(self):
        '''
        put homeUrl as front page to queue
        and start to run
        default: reptile get homeurl as first page to download
        '''

        for i,url in enumerate(self.homeUrls):
            self.append( i, -1, url)
        '''
        #为蛋站但设计
        for i in range(8):
            self.append(0, -1, ['信电学院',"http://www.ciee.cn/ciee/"])
        homeurls = [
            ['今日新闻', 'http://news.cau.edu.cn/list.php?mid=1'],
            ['媒体农大','http://news.cau.edu.cn/list.php?mid=4'],
            ['推荐新闻', 'http://news.cau.edu.cn/list.php?mid=3'],
            ['农大科技', 'http://news.cau.edu.cn/list.php?lid=3'],
        ]
        '''


    def pop(self):
        '''
        如果需要的list为空
        则循环返回其他list的path
        '''
        if not self.size:
            #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            #need to sleep for a moment
            #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            #模仿queue的功能 睡眠3秒
            thread.sleep(10000)

        if self.size > 0:
            url = self.htmldb.getCacheUrl()
            #print 'siteID', url.siteID
            self.sizes[url.siteID] -= 1
            return url
        else:
            return None


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

if __name__ == '__main__':
    urlqueue = UrlQueue()
    urlqueue.initFrontPage()


        
