# -*- coding: utf-8 -*-
import chardet
from pyquery import PyQuery as pq
import re
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
import xml.dom.minidom as dom

#sys.path.append('../../')
#from debug import *

class HtmlParser:
    def __init__(self, urlparser):
        self.d = None
        self.urlparser = urlparser

    def init(self, source):
        source = self.transcode(source)
        self.d = pq(source)

        if not len(self.d('body')):
            print 'not html'
            return False

        self.initRemoveNodes()
        return True

    def initRemoveNodes(self):
        '''
        初始化时删除一些无用的标签
        '''
        self.d('script').remove()
        self.d('SCRIPT').remove()

    def transcode(self, source):
        '''
        转码 自动转化为utf8
        '''
        try:
            res = chardet.detect(source)
        except:
            return False
        confidence = res['confidence']
        encoding = res['encoding']
        p = re.compile("&#(\S+);")
        source = p.sub("",source)
        if encoding == 'utf-8':
            return source
        if confidence < 0.6:
            return False
        else:
            return unicode(source, encoding, 'ignore')

    def getLinks(self):
        '''
        取得链接地址
        [ [title, href] ]
        '''
        a=self.d('a')
        aa = []
        for i in range(len(a)):
            aindex=a.eq(i)
            href = aindex.attr('href')
            #print '.. html link:', href
            aa.append( [aindex.text(), href])
        return aa

    def getSrcs(self):
        '''
        取得图片地址列表
        [ ['', src] ]
        '''
        src = self.d('img')
        ads = []
        for i in range(len(src)):
            srcidx = src.eq(i)
            ads.append(['',srcidx.attr('src')])
        return ads

    def getTextNodes(self, tagname):
        '''
        取得普通标签的列表
        '''
        nodes = self.d(tagname)
        nodelist = []
        for i in range(len(nodes)):
            node = nodes.eq(i)
            nodelist.append(node.text())
        return nodelist

    def transXML(self, pageStdUrl):
        '''
        trans html source to xml
        '''
        def clearOtherNodes():
            '''
            删除特殊标签
            '''
            self.d('head').remove()
            self.d('h1').remove()
            self.d('h2').remove()
            self.d('h3').remove()
            self.d('b').remove()
            self.d('a').remove()

        def xmlAppendNodes(xmlnode, tagname):
            '''
            append text nodes to xmlnode
            '''
            html_node_text_list = self.d(tagname)
            childnode = self.dd.createElement(tagname)
            for i in range(len(html_node_text_list)):
                '''
                为每个元素添加一个item
                '''
                text_node = self.dd.createElement('item')
                text_node.setAttribute('text', html_node_text_list.eq(i).text())
                childnode.appendChild(text_node)
            xmlnode.appendChild(childnode)

        self.dd = dom.parseString('<html></html>')
        html = self.dd.firstChild
        html.setAttribute('url', pageStdUrl)
        titlenode = self.dd.createElement('title')
        titlenode.setAttribute('text', self.d('title').text())
        html.appendChild(titlenode)

        nodenames = ["h1", "h2", "h3", "h4", "b"]

        for tagname in nodenames:
            xmlAppendNodes(html, tagname)
        #links
        aa = self.getLinks()
        a=self.dd.createElement('a')
        for link in aa:
            aindex=self.dd.createElement('item')
            aindex.setAttribute('title',link[0])
            aindex.setAttribute('href',self.urlparser.transToStdUrl(pageStdUrl, link[1]))
            a.appendChild(aindex)
        html.appendChild(a)
        #content
        clearOtherNodes()
        contentNode =self.dd.createElement('content')
        content = self.d.text()
        ctext=self.dd.createTextNode(content)
        contentNode.appendChild(ctext)
        html.appendChild(contentNode)
        return html.toxml()



if __name__ == '__main__':
    f = open('~/1.html')
    c = f.read()
    f.close()
    print c


