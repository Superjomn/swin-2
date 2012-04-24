# -*- coding: utf-8 -*-
from reptile._reptile import ReptileLib
from django.http import HttpResponse
from django.shortcuts import render_to_response
from pyquery import PyQuery as pq
import xml.dom.minidom as dom
import socket


class ReptileFrame:
    def hello(self, request):
        return HttpResponse("welcome to the page at %s"%request.path)

    def index(self, request):
        return render_to_response('index.html', {})    

    def init(self, request):
        return render_to_response('init.html', {})    

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



