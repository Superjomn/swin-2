# -*- coding: utf-8 -*-
#from reptile._reptile import ReptileLib
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
        '''
        def hello(self, request):
            return HttpResponse("welcome to the page at %s"%request.path)
        '''

    def index(self, request):
        return render_to_response('index.html', {})    

    def start(self, request):
        self.reptilectrl.sendStart()
        return self.status(request)

    def init(self, request):
        self.reptilectrl.sendInit()
        return render_to_response('returnok-info.html', {'type':'Init'})    

    def resume(self, request):
        self.reptilectrl.sendResume()
        return render_to_response('returnok-info.html', {'type':'Resume'})    

    def stop(self, request):
        self.reptilectrl.sendStop()
        return render_to_response('returnok-info.html', {'type':'Stop'})    
        
    def status(self, request):
        def listStr(_list):
            '''
            trans list to array str
            '''
            res = "["
            l = len(_list)
            for i,d in enumerate(_list):
                res += str(d)
                if i != l-1:
                    res += ','
            res += "]"
            return res


        self.reptilectrl.sendStatus()
        #reptilestatus
        rs = self.reptilectrl.reptilestatus
        titles = [ '\'site'+str(i)+'\'' for i in range(len(rs.pages)) ]

        vs = listStr(rs.downloadSpeed)
        #vs = "[2,3,45,3,2,4]"
        #ticks = "[2,3,4,5,6,7]"
        ticks = listStr(titles)
        queues = listStr(rs.queue_nums)
        #pages
        #print '.. pagelist', rs.pages
        pages = [ '['+titles[i]+','+str(j)+']' for i,j in enumerate(rs.pages) ]
        pages = listStr(pages)
        #print 'pagelist', pages
        #pages = "[ [2,43], [34,23] ]"

        '''
        print '.. vs', vs
        print '.. ticks', ticks
        print '.. pages', pages
        '''
        res = {}
        res['vs'] = vs
        res['ticks'] = ticks
        res['queues'] = queues
        res['pages'] = pages
        res['total'] = sum(rs.pages)

        return render_to_response('status.html', res)    

    #-------------------------------------------------------------
    #   default info
    #-------------------------------------------------------------

    def default_info(self, request):
        return render_to_response('default-info.html', {})    

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

    def halt_info(self, request):
        return render_to_response('halt-info.html', {} )    

    def stop_info(self, request):
        return render_to_response('stop-info.html', {} )    
        



