# -*- coding: utf-8 -*-
from reptile._reptile import ReptileLib
from django.http import HttpResponse
from django.shortcuts import render_to_response
import Queue as Q

def hello(request):
    return HttpResponse("welcome to the page at %s"%request.path)

def index(self):
    return render_to_response('index.html', {})    

def infoform(self):
    return render_to_response('initform.html', {})    


class ReptileCtrl:
    '''
    爬虫控制程序 人机界面后台程序
    主要通过 信号 传递到爬虫核心程序
    此为信号外壳
    '''
    def __init__(self):
        #限制 一次的信号只能有一个
        self.inSignalQueue = Q.Queue(maxsize=1)
        self.outSignalQueue = Q.Queue
        self.reptilelib = ReptileLib( self.inSignalQueue ,self.outSignalQueue )
        self.reptilelib.run()
        self.homeUrls = None
        self.threadNum = None
        self.maxPages = None

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
            ['开放的中国农业大学欢迎您', 'http://www.cau.edu.cn'],
            ['百度', 'http://www.baidu.com'],
        ]
        self.threadNum = 1
        self.maxPages = 200


    def sendInit(self, request):
        '''
        after info method 
        and homeUrls data 
        '''
        #debug
        self.getInfo()
        _signal = {'type': 'resume'}
        _signal['homeUrls'] = self.homeUrls
        _signal['threadNum'] = self.threadNum
        _signal['maxPages'] = self.maxPages
        self.inSignalQueue.put(_signal)
        return HttpResponse("welcome to the page at %s"%request.path)

    def sendResume(self, request):
        _signal = {'type': 'resume'}
        self.inSignalQueue.put(_signal)
    
    def sendStop(self, request):
        _signal = {'type': 'stop'}
        self.inSignalQueue.put(_signal)
    
    def sendHalt(self, request):
        _signal = {'type': 'halt'}
        self.inSignalQueue.put(_signal)

    def sendRun(self, request):
        _signal = {'type': 'run'}
        self.inSignalQueue.put(_signal)





