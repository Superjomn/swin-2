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

from reptile.models import HtmlInfo, HtmlSource, HomeUrl, Urlist, UrlQueue
from debug import *

class HtmlDB:
    def getHtmlNum(self):
        _len = len(HtmlInfo.objects.all())
        return _len


    def getContentByIndex(self, _id):
        _htmlinfo = HtmlInfo.objects.all()[_id]
        title = _htmlinfo.title
        xmlcontent = HtmlSource.objects.filter(info=_htmlinfo)[0]
        _xmlroot = pq(xmlcontent.parsed_source)
        _xmlcontent = _xmlroot.text()
        return _xmlcontent+title


        
    
