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
        t = get_template('query/index.html')
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

        html = t.render(Context({'site':site,'title':title,'titles':titles}))

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
        print 'get request', request
        if 'query_text' in request.GET:
            text = request.GET['query_text']
            print '.. search text', text

        if 'page' in request.GET:
            page = int(request.GET['page'])
        else:
            #from 1
            page = 1

        print '.. page', page

        if 'siteID' in request.GET:
            siteID = int(request.GET['siteID'])
        else:
            siteID = 0

        print '.. siteID', siteID

        res = queryer.search(text, siteID, page )

        print '.. res', res 

        t = get_template('query/search.html')
        html = t.render( Context(
            {
                'res': res,
                'page': page,
                'siteID': siteID
            })
        )

        return HttpResponse(html)

    
