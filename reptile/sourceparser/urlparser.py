# -*- coding: utf-8 -*-
import sys
import os
#sys.path.append('../../')
#from debug import *
import urlparse
sys.path.append('../')
from debug import *

class UrlParser:
    '''
    对url的一系列操作
    '''
    def __init__(self, homeUrls):
        '''
        [
            [title, url]
        ]
        '''
        self.__homeUrls = homeUrls

    
    def transToStdUrl(self, homeUrl, newUrl):
        ''' ok '''
        '''
        将任意一个url转化为绝对地址
        '''
        assert(type(homeUrl) != type([]))
        if not newUrl:
            return homeUrl

        if len(newUrl)>7 and newUrl[:7] == 'http://':
            '''
            测试是否已经为绝对地址
            '''
            return newUrl
        return urlparse.urljoin(homeUrl, newUrl)


    def transSiteID(self, stdUrl):
        ''' ok '''
        '''
        返回url属于的siteID
        '''
        length = 0
        for i,u in enumerate(self.__homeUrls):
            u = u[1]
            length = len(u)
            if len(stdUrl) > length and stdUrl[:length] == u:
                return  i
        return -1

    def transPathByStd(self, stdUrl):
        ''' ok '''
        '''
        直接返回绝对地址的path
        '''
        t = urlparse.urlsplit(stdUrl)

        if (not t.path) and (not t.query):
            return ''

        if t.query:
            path = t.path + '?' +t.query

        else:
            path = t.path
        
        if path.startswith('/'):
            return path
        else:
            return '/'+path

    def transPath(self, pageStdUrl, url):
        ''' ok '''
        '''
        将任意一个链接转化为 路径
        '''
        url = self.transToStdUrl(pageStdUrl, url)
        length = len(pageStdUrl)
        return url[length : ]

    def transNetloc(self, stdurl):
        ''' ok '''
        return urlparse.urlsplit(stdurl).netloc


    def judgeUrl(self, stdPageUrl, newUrl):
        ''' ok '''
        '''
        判断一个url是否在收录范围内
        如果在，则返回对应站点id
        '''
        url = self.transToStdUrl(stdPageUrl, newUrl)
        #print 'trans to stdurl >> ', url
        return self.transSiteID(url)

    def getFileExtention(self):
        '''
        得到url扩展名
        '''
        pass


    def typeDetect(self, stdUrl):
        '''
        通过url检测file的类型
        返回 文件扩展名 如： mp3  png  jpg  jpeg  gif
        doc  pdf  exl
        return image or doc or ''
        '''
        path = urlparse.urlparse(stdUrl).path
        ext = os.path.splitext(path)[1:]
        ext = ext[0][1:]
        if ext in ('png', 'jpg', 'jpeg', 'gif'):
            return ('image', ext)

        elif ext in ('doc', 'pdf', 'xls'):
            return ('doc', ext)

        elif ext in ('zip', 'tar'):
            return ('not', ext)
        #html
        return ('', '')






if __name__ == '__main__':

    u = UrlParser(None)
    '''
    pageStdUrl = "http://www.cau.edu.cn"
    url = "http://www.cau.edu.cn/index.php?name=hello&site=ttgo"
    print u.transPath(pageStdUrl, url)
    '''
    url = 'http://www.cau.edu.cn/hello/world/td.jpg'
    print url
    print u.typeDetect(url)

