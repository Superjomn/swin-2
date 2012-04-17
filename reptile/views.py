# -*- coding: utf-8 -*-
from reptile._reptile import ReptileLib
from django.http import HttpResponse
from django.shortcuts import render_to_response
import Queue as Q


def hello(request):
    return HttpResponse("welcome to the page at %s"%request.path)

def index(self):
    return render_to_response('index.html', {})    

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
        self.homeUrls = None
        self.threadNum = None
        self.maxPages = None

    def getInfo(self, request):
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
        _signal = {'type': 'resume'}
        _signal['homeUrls'] = self.homeUrls
        _signal['threadNum'] = self.threadNum
        _signal['maxPages'] = self.maxPages

        self.signalQueue.put(_signal)

    def sendResume(self, request):
        _signal = {'type': 'resume'}
        self.signalQueue.put(_signal)
    
    def sendStop(self, request):
        _signal = {'type': 'stop'}
        self.signalQueue.put(_signal)
    
    def sendHalt(self, request):
        _signal = {'type': 'halt'}
        self.signalQueue.put(_signal)

    def sendRun(self, request):
        _signal = {'type': 'run'}
        self.signalQueue.put(_signal)





