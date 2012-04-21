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

from _reptile import Reptile

def debug_reptile():
    homeUrls = [
        ['CAU', 'http://www.cau.edu.cn'],
    ]
    maxPages = [
        30,
    ]
    urlQueue = UrlQueue()
    urlQueue.init(homeUrls)
    urlist = Urlist()
    urlist.init( len(homeUrls))

    r = Reptile(
       name = 'reptile 1',
       urlQueue = urlQueue,
       urlist = urlist,
       Flock = None,
       homeUrls = homeUrls,
       maxPageNums = maxPages,
       pages = [0],
       curSiteID = [0],
       continueRun = [True]
    )
    r.conn()
    #urlQueue.initFrontPage()
    urlQueue.append(0, ['CAU',''])
    r.start()

    
    




debug_reptile()

