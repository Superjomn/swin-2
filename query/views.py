# -*- coding: utf-8 -*-
from django.template.loader import get_template
from django.template import Context
from django.http import HttpResponse
from Queryer import Queryer
from htmldb import HtmlDB


queryer = Queryer()

class QueryFrame:
    def __init__(self):
        self.htmldb = HtmlDB()

    def index(self, request):
        Get = request.GET
        t = get_template('query/index.html')

        #搜索模式选择
        hi = ['', '', '']
        if 'type' in Get:
            _type = Get['type']
            if Get['type'] == 'file':
                hi[2] = 'hi'
            elif Get['type'] == 'image':
                hi[1] = 'hi'
            else:
                hi[0] = 'hi'
        else:
            hi[0] = 'hi'
            _type = 'web'

        #加入站点信息
        if 'site' in request.GET:
            '''
            此处site 为 0 1 2 3
            0 为 index
            1 为 siteID=0
            '''
            site = int( request.GET['site'])

            if site == 0:
                title = "内网"
            else:
                title = self.htmldb.get_title(site)

        else:
            #默认值应该为总搜索
            site = 0
            title = '内网全文'

        titles = self.htmldb.get_titles()

        html = t.render(Context({'site':site,'title':title,'titles':titles, 'type':_type, 'hi':hi}))

        return HttpResponse(html)



    def more_sites(self, request):
        '''
        展示更多站点
        '''
        t = get_template('query/more.html')
        titles = self.htmldb.get_titles()

        html = t.render(Context({'titles':titles}))
        return HttpResponse(html)



    def search(self, request):
        '''
        查询主程序
        '''
        Get = request.GET

        if 'query_text' in request.GET:
            text = request.GET['query_text']
            print '.. search text', text

        if 'page' in request.GET:
            page = int(request.GET['page'])
        else:
            #from 1
            page = 1

        #print '.. page', page

        if 'siteID' in request.GET:
            siteID = int(request.GET['siteID'])
        else:
            siteID = 0

        #print '.. siteID', siteID
        if 'type' in Get:
            if Get['type'] == 'image':
                #文本查询
                #print 'search: text, page, siteID ',text, page, siteID
                t = get_template('query/search_image.html')
                res = queryer.searchImages(text, siteID, page)
                print res
            elif Get['type'] == 'file':
                t = get_template('query/search_file.html')
                res = queryer.searchFiles(text, siteID, page)
            else:
                t = get_template('query/search.html')
                res = queryer.searchText(text, siteID, page)
        else:
            t = get_template('query/search.html')
            res = queryer.searchText(text, siteID, page)


        #print '.. res', res 

        html = t.render( Context( res))

        return HttpResponse(html)

    
