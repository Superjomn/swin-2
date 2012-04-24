# -*- coding: utf-8 -*-
from reptile._reptile import ReptileLib
from django.http import HttpResponse
from django.shortcuts import render_to_response
from pyquery import PyQuery as pq
import xml.dom.minidom as dom
import socket

from reptilectrl import ReptileCtrl

class ReptileFrame:
    '''
    i/o frame
    '''
    def __init__(self):
        self.homeurls = []
        self.maxpages = []
        self.reptilenum = None
        self.reptilectrl = ReptileCtrl()

    def hello(self, request):
        return HttpResponse("welcome to the page at %s"%request.path)

    def start(self, request):
        return render_to_response('status.html', {})    

    def index(self, request):
        return render_to_response('index.html', {})    

    def init(self, request):
        self.reptilectrl.sendInit()
        return render_to_response('init-ok.html', {})    

    def status(self, request):
        def listStr(_list):
            '''
            trans list to array str
            '''
            res = "["
            l = len(_list)
            for i,d in enumerate(_list):
                res += d
                if i != l-1:
                    res += ','
            res += "]"
            return res


        self.reptilectrl.sendStatus()
        titles = [ str(i) for i in range(len(self.pages)) ]

        vs = listStr(self.reptilectrl.downloadSpeed)
        ticks = listStr(titles)
        queues = listStr(self.reptilectrl.queue_nums)
        #pages
        pages = [ '['+str(j)+','+ticks(i)+']' for i,j in enumerate(self.reptilectrl.pages ]
        pages = listStr(pages)

        print '.. vs', vs
        print '.. ticks', ticks
        print '.. pages', pages

        res = {}
        res['vs'] = vs
        res['ticks'] = ticks
        res['pages'] = pages

        return render_to_response('status.html', res)    



    def init_info(self, request):
        return render_to_response('init-info.html', {})    

    def init_form(self, request):
        #num of sites
        if 'homeurls' in request.GET:
            num = int(request.GET['homeurls'])
            res = []
            for i in range(num):
                res.append(i)

            return render_to_response('initform.html', {'homeurls':res})    
        else:
            return render_to_response('initform.html', {})    

    def init_form_info(self, request):
        print request.GET
        titles = request.GET.getlist('titles[]')
        print '.. titles',titles
        urls = request.GET.getlist('urls[]')
        print '.. urls',urls
        maxpages = request.GET.getlist('maxpages[]')
        print '.. maxpages',maxpages
        reptilenum = request.GET['reptile_num']
        
        homeurls = []
        for i in range( len(titles) ):
            _site = {}
            _site['title'] = titles[i]
            _site['url'] = urls[i]
            _site['maxpage'] = maxpages[i]
            homeurls.append(_site)

        res = {
            'homeurls': homeurls,
            'reptilenum': reptilenum
        }
        return render_to_response('init-form-info.html', res )    

    def resume_info(self, request):
        return render_to_response('resume-info.html', {} )    
        



