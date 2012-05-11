# -*- coding: utf-8 -*-
import sys
sys.path.append('../../')
from swin2 import settings 
setup_environ(settings)
from reptile.models import  ImageFile, TextFile, HtmlInfo, HtmlSource
# -*- coding: utf-8 -*-
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
        print '.. toDocID', toDocID
        htmlinfo = HtmlInfo.objects.filter(id = toDocID)[0]
        htmlsource = HtmlSource.objects.filter(info=htmlinfo)[0]

        doc = TextFile(
                title = title,
                url = url,
                todocid = toDocID
            )
        #将文件记录添加到原来的html中
        #将title插入到原来的xml内容中 并h1的
        xmlsource = htmlsource.parsed_source
        htmlsource.parsed_source = self.addToXMLContent(title, xmlsource )



if __name__ == '__main__':
    filetext = TextFileParser()
    filetext.save('报名表', 'http://www.cau.edu.cn/index.doc', 0)

    
