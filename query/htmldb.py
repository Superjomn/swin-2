# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
sys.path.append('../')

#使用django的模型
from django.core.management import setup_environ
sys.path.append('../../')
from swin2 import settings 
setup_environ(settings)

from pyquery import PyQuery as pq
from reptile.models import HtmlInfo, HtmlSource, HomeUrl, Urlist, UrlQueue, ImageFile, TextFile
from query.models import Record


class HtmlDB:
    def __init__(self):
        self.title = None
        self.xmlhtml = None
        self.dd = None
        self.docID = None

    def getHtmlNum(self):
        _len = len(HtmlInfo.objects.all())
        return _len

    def setRecordHandle(self, _id):
        _htmlinfo = HtmlInfo.objects.all()[_id]
        self.title = _htmlinfo.title
        record = (HtmlSource.objects.filter(info=_htmlinfo)[0])
        xmlcontent = record.parsed_source
        self.docID = record.id
        self.xmlhtml = xmlcontent
        self.dd = pq(self.xmlhtml)
        return _htmlinfo

    #----------content-------------------
    def getUrlDec(self):
        return self.title

    def getContent(self):
        return self.dd('content').text()

    def getTitle(self):
        return self.dd('title').attr('text')

    def getItemsText(self, tagname):
        node = self.dd(tagname)
        items = node('item')
        res = ""
        for i in range(len(items)):
            res += items.eq(i).attr('text')
        return res


    def getUrl(self):
        html = self.dd('html')
        return html.attr('url')


    def getDocID(self):
        return self.docID

    #---------query index -------------
    def get_title(self, siteID):
        '''
        '''
        assert(siteID>0)
        siteID -= 1
        homeurl = HomeUrl.objects.all()[siteID]
        return homeurl.title

    def get_titles(self):
        '''
        取得首页站点的导航
        '''
        homeurls = HomeUrl.objects.all()[:4]
        return [homeurl.title for homeurl in homeurls]


    #---------image-------------------
    def get_image_num(self, _list):
        images = ImageFile.objects.filter(todocid__in = _list)
        return len(images)


    def get_images(self, _list, left, right):
        '''
        _list 需要先进行筛选
        '''
        images = ImageFile.objects.filter(todocid__in = _list)
        return images[left:right]


    #---------file-------------------
    def get_file_num(self, _list):
        files = TextFile.objects.filter(todocid__in = _list)
        return len(files)


    def get_files(self, _list, left, right):
        '''
        _list 需要先进行筛选
        '''
        files = TextFile.objects.filter(todocid__in = _list)
        return files[left:right]


