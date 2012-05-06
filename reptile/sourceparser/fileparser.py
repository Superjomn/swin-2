# -*- coding: utf-8 -*-
from __feature__ import division
import os
import sys
sys.path.append('../../')
reload(sys)
sys.setdefaultencoding('utf-8')
import Image
import xml.dom.minidom as dom
from Config import Config
config = Config()
import random

from reptile.models import  ImageFile, TextFile, HtmlInfo

class ImageParser:
    '''
    图片操作
    '''
    def __init__(self, reptileID):
        #jpeg jpg png gif
        self.image = None
        self.url = ''
        self.toDocID = 0
        self.path = config.getpath('reptile', 'img_path')
        self.size = config.getint('reptile', 'img_size')
        self.temPath = config.getpath('reptile', 'tem_file_path') + str(reptileID)

    def init(self, url, toDocID):
        '''
        reptileID 为temfile 定义一个不同的path
        url image的url
        '''
        self.url = url
        self.toDocID = toDocID

    def deal(self, source, url, toDocID):
        '''
        从外界接收source
        全局处理
        '''
        #save to tem file
        f = open(self.temPath, 'wb')
        f.write(source)
        f.close()
        #开始处理
        self.init(url, toDocID)
        self.compressImg()


    def compressImg(self):
        '''
        压缩图片尺寸
        '''
        #提前需要将图片文件存储到此地址
        _size = self.compressSize()
        f = Image.open(self.temPath)
        f = Image.resize(_size)
        self.save(_size)



    def compressSize(self):
        (w, h) = self.img.size
        _radio = 0

        if w>h:
            #按照w计算
            _radio = w / self.size
            w = self.size
            h = h * _radio
        else:
            _radio = h / self.size
            h = self.size
            w = w*_radio
        #height weight
        return (w, h)
        

    def save(self, size):
        path = self.getNewPath() 
        #存储到磁盘
        self.image.save(path)
        #取得 docid
        htmlinfo = HtmlInfo.objects.filter(docID = self.toDocID)
        #存储到数据库
        image = ImageFile(
            width = _size[0],
            height = _size[1],
            path = path,
            url = self.url,
            doc = htmlinfo
        )
        image.save()


    def getNewPath(self):
        '''
        综合 时间和随机数
        产生一个文件名称
        '''
        fn = time.strftime('%Y%m%d%H%M%S')  
        fn = fn + '_%d' % random.randint(0,100)  
        #格式类型在数据库中存储
        return self.path + fn





class TextFileParser:
    '''
    对图片等进行解析
    '''
    def __init__(self):
        '''
        init
        '''
        pass

    def deal(self, title, url, toDocID):
        self.save(title, url, toDocID)

    def addToXMLContent(self, title, xmlsource):
        dd = dom.parseString(xmlsource)
        html = dd.firstChild
        h1 = html.getElementsByTagName('h1').item(0)
        item = dd.createElement('item')
        item.setAttribute('text', title)
        h1.appendChild(item)
        return html.toxml()
        

    def save(self, title, url, toDocID):
        '''
        save doc file to disk
        save doc info to database
        data: binary file data
        '''
        htmlinfo = HtmlInfo.objects.filter(docID = toDocID)
        htmlsource = htmlinfo.htmlsource_set.all()[0]
        doc = TextFile(
                title = title,
                url = url,
                doc = htmlinfo
            )
        #将文件记录添加到原来的html中
        #将title插入到原来的xml内容中 并h1的
        xmlsource = htmlsource.parsed_source
        htmlsource.parsed_source = self.addToXMLContent(title, xmlsource )





