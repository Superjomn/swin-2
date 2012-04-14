# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
sys.path.append('../')
from datetime import date
#使用django的模型
from django.core.management import setup_environ
sys.path.append('../../../')
import swin2.settings as settings
setup_environ(settings)

from swin2.reptile.models import HtmlInfo, HtmlSource

sys.path.append('../../')
from debug import *

class HtmlDB:
    '''
    Html处理及存储层
    '''
    def __init__(self, htmlparser):
        #此处urlparser 和 htmlparser都已经在外界更新过
        self.htmlparser = htmlparser

    def saveHtml(self, _title, stdUrl, _source):
        _source = self.htmlparser.transcode(_source)
        today = date.today()
        #_date = today.strftime("%y-%m-%d")
        #存储网页信息
        print '.. save htmlinfo'
        htmlinfo = HtmlInfo(title=_title, url=stdUrl, date=today)
        htmlinfo.save()
        xmltext = self.htmlparser.transXML(stdUrl)
        #print '.. save htmlsource'
        htmlsource = HtmlSource(parsed_source=xmltext, info=htmlinfo)
        htmlsource.save()

    
if __name__ == '__main__':
    htmlinfo = HtmlInfo(title="try:中国农业大学", url="http://www.cau.edu.cn", date="2012-4-17")
    print "html source save"
    htmlinfo.save()

    xmlsource = "<html></html>"
    htmlsource = HtmlSource(parsed_source = xmlsource, info=htmlinfo)
    print "htmlsource save"
    htmlsource.save()


        


