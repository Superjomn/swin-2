# -*- coding: utf-8 -*-
import sys
sys.path.append('../../')
from debug import *
from htmlparser import HtmlParser
from urlparser import UrlParser

reload(sys)
sys.setdefaultencoding('utf-8')
import chardet

class debug_HtmlParser:
    @dec
    def __init__(self):
        self.html='''
            <html>
                <head>
                    <title>hello world</title>
                </head>
                <body>
                    你好<b>世界</b>
                    <h1>h1这是</h1>
                    <a href="http://www.cau.edu.cn">link哈啊 1</a>
                    <a href="http://www.cau.edu.cn/hello">link 2</a>
                    <a href="http://www.cau.edu.cn/index">link 3</a>
                </body>
            </html>
        '''
        self.homeUrls = [
            'http://www.cau.edu.cn',
            'http://www.google.com.hk',
            'http://www.baidu.com',
        ]
        self.urlparser = UrlParser(self.homeUrls)
        self.htmlparser = HtmlParser(self.urlparser)

    @dec
    def init(self):
        self.htmlparser.init(self.html)

    @dec
    def transcode(self):
        self.htmlparser.transcode(self.html)

    @dec
    def getLinks(self):
        print self.htmlparser.getLinks()

    @dec
    def getSrcs(self):
        print self.htmlparser.getSrcs()

    def transXML(self):
        print self.htmlparser.d.text()
        strr = self.htmlparser.transXML("http://www.cau.edu.cn")
        f = open('text.txt', 'w')
        f.write(strr)
        f.close()
        print chardet.detect(strr)
        print strr
        
        
if __name__ == '__main__':
    htmlparser = debug_HtmlParser()
    htmlparser.init()
    htmlparser.transcode()
    htmlparser.getLinks()
    htmlparser.getSrcs()
    htmlparser.transXML()


        
        
