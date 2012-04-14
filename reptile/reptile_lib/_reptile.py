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
sys.path.append('../')
from sourceparser.htmlparser import HtmlParser
from sourceparser.urlparser import UrlParser
from datalayer.htmldb import HtmlDB
from datalist.urlqueue import UrlQueue
from datalist.urlist import Urlist

from reptile import Reptile, ReptileLib

class debug_Reptile:
    def __init__(self):
        self.homeUrls = [
            'http://www.cau.edu.cn',
            'http://www.google.com.hk',
        ]
        self.urlist = Urlist(len(self.homeUrls))
        self.urlQueue = UrlQueue(len(self.homeUrls))
        self.curSiteID = [0]
        self.continueRun = [True]
        self.maxPageNums = [100, 100]
        self.reptile = Reptile(
            name = 'reptile1', 
            urlQueue = self.urlQueue,
            urlist = self.urlist,
            Flock = None,
            homeUrls = self.homeUrls,
            maxPageNums = self.maxPageNums
        )

    def getPage(self):
        
        for path in [
                '/home/dingceng/meiti.htm',
                '/home/dingceng/xiaoyou.htm',
                '/home/dingceng/jiazhang.htm',
                '/xiaonei/out/today.php',
            ]:
            #print path,
            source = self.reptile.getPage(path)
            #print len(source)

    def run(self):
        self.urlQueue.append(0,('中国农业大学',''))
        self.urlQueue.show()
        self.reptile.run()


class debug_ReptileLib:
    def __init__(self):
        self.reptilelib = ReptileLib()
        self.homeurls = [
            #'http://www.cau.edu.cn',
            'http://jwc.cau.edu.cn',
            ]

    def init(self):
        self.reptilelib.init(self.homeurls, 10)
        self.reptilelib.urlQueue.append(0,('中国农业大学教务处','/administration_office/'))

    def initThreads(self):
        self.reptilelib.initThreads()

    def threadsRun(self):
        self.reptilelib.threadsRun()

        

if __name__ == '__main__':
    debug_reptilelib = debug_ReptileLib()
    debug_reptilelib.init()
    debug_reptilelib.initThreads()
    debug_reptilelib.threadsRun()

    '''
    debug_reptile = debug_Reptile()
    debug_reptile.run()
    '''


