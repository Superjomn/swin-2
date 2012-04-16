# -*- coding: utf-8 -*-
from reptile._reptile import ReptileLib
from django.http import HttpResponse

class ReptileCtrl:
    '''
    爬虫控制程序 人机界面后台程序
    '''
    def __init__(self):
        self.reptilectrl = ReptileLib
    
    def sendInit(self, request):
        pass
    
    def sendResume(self):
        pass
    
    def sendStop(self):
        pass
    
    def sendHalt(self):
        pass