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

    def infoform(self, request):
        return render_to_response('initform.html', {})    



class ReptileCtrl:
    '''
    爬虫控制程序 人机界面后台程序
    主要通过 TCP XML 信号 传递到爬虫核心程序
    此为信号外壳
    '''
    def __init__(self):
        #限制 一次的信号只能有一个
        #self.inSignalQueue = Q.Queue(maxsize=1)
        #self.outSignalQueue = Q.Queue
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        #self.reptilelib = ReptileLib( self.inSignalQueue ,self.outSignalQueue )
        #self.reptilelib.run()
        self.homeUrls = None
        self.threadNum = None
        self.maxPages = None

    def sendMessage(self, signal):
        '''
        base
        '''
        self.sock.connect("", 8881)
        print "..Connected to server .."
        self.sock.sendall(signal)
        print ".. Succeed send signal .."
        self.sock.close()
        

    def initInfo(self, request):
        '''
        利用info初始化信息
        通过 infoForm 网页返回的信息初始化数据
        '''
        print request

    def getInfo(self):
        '''
        初始化信息
        '''
        self.homeUrls = [
            {'title':'开放的中国农业大学欢迎您', 'url':'http://www.cau.edu.cn','maxpage':2000},
        ]
        self.threadNum = 1
        self.maxPages = 200


    def sendInit(self, request):
        '''
        after info method 
        and homeUrls data 
        '''
        self.getInfo()
        dd = dom.parseString('<signal></signal>')
        signal = dd.firstChild
        signal.setAttribute('type', 'init')
        homeurl = dd.createElement('homeurl')
        signal.appendChild(homeurl)
        for _homeurl in self.homeUrls:
            item = dd.createElement('item')
            item.setAttribute('title', _homeurl['title'])
            item.setAttribute('url', _homeurl['url'])
            item.setAttribute('maxpage', _homeurl['maxpage'])
            homeurl.appendChild(item)
        self.sendMessage(signal.toxml())
        
        return HttpResponse("welcome to the page at %s"%request.path)

    def sendResume(self, request):
        signal = "<signal type='resume'/>"
        self.sendMessage(signal)
        return HttpResponse("Successfully send resume signal")
    
    def sendStop(self, request):
        signal = "<signal type='stop'/>"
        self.sendMessage(signal)
        return HttpResponse("Successfully send stop signal")
    
    def sendHalt(self, request):
        signal = "<signal type='halt'/>"
        self.sendMessage(signal)
        return HttpResponse("Successfully send halt signal")

    def sendRun(self, request):
        signal = "<signal type='run'/>"
        self.sendMessage(signal)
        return HttpResponse("Successfully send run signal")





