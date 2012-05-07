# -*- coding: utf-8 -*-
import threading  
import chardet
import urllib2  
import StringIO  
import gzip  
import string  

from Reptile import Reptile
from datalist.urlqueue import UrlQueue
from datalist.urlist import Urlist
from sourceparser.htmlparser import HtmlParser
from sourceparser.urlparser import UrlParser
from htmldb import HtmlDB



urlqueue = UrlQueue()
urlist = Urlist()
Flock = threading.RLock()  

homeurls = [
    ['CAU', 'www.cau.edu.cn'],
]

maxPageNums = [
    200,
]
pages = [
    0,
]

reptile = Reptile( 
    name = "reptile1", 
    urlQueue = urlqueue , 
    urlist = urlist, 
    Flock = Flock, 
    homeUrls = homeurls, 
    maxPageNums = maxPageNums, 
    pages = pages, 
    continueRun = [True])

reptile.start()
