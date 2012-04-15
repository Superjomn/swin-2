# -*- coding: utf-8 -*-
import sys
sys.path.append('../../')
from debug import *

from urlparser import UrlParser

class debug_UrlParser:
    def __init__(self):
        ''' ok '''
        self.homeUrls = [
            'http://www.cau.edu.cn',
            'http://www.google.com.hk',
            'http://www.baidu.com',
        ]
        self.urlparser = UrlParser(self.homeUrls)

    @dec
    def transToStdUrl(self):
        ''' ok '''
        homeurl = 'http://www.google.com/hello/world'
        print 'homeurl',homeurl
        url = [
            '../index.html',
            './world/trying/tofind/right.html',
        ]
        for u in url:
            print 'url',u
            print 'stdurl',self.urlparser.transToStdUrl(homeurl, u)
            print '-'*20

    @dec
    def transSiteID(self):
        ''' ok '''
        url = [
            'http://www.cau.edu.cn/index.php',
            'http://www.google.com.hk/helllo/werod',
        ]
        for u in url:
            print u, '\r',self.urlparser.transSiteID(u), '\r'

    @dec
    def transPath(self):
        ''' ok '''
        pageurl = "http://www.cau.edu.cn/hello/index.html"
        url = "../index"
        print 'pageurl', pageurl
        print 'url', url
        print 'path', self.urlparser.transPath(pageurl, url)

    @dec
    def transNetloc(self):
        ''' ok '''
        pageurl = "http://www.cau.edu.cn/hello/index.html"
        print self.urlparser.transNetloc(pageurl)

    @dec
    def judgeUrl(self):
        ''' ok '''
        pageurl = "http://www.cau.edu.cn/hello/index.html"
        newurl = "./world.php?hdjfsa=dslkfjsaf&lkfjewoif=seklfhehw"
        print self.urlparser.judgeUrl(pageurl, newurl)

if __name__ == '__main__':
        urlparser = debug_UrlParser()
        urlparser.transToStdUrl()
        urlparser.transSiteID()
        urlparser.transPath()
        urlparser.transNetloc()
        urlparser.judgeUrl()
        


        


