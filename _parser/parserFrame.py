# -*- coding: utf-8 -*-
import sys
sys.path.append('../')
from Config import Config
config = Config()
from django.template.loader import get_template
from django.template import Context
from django.http import HttpResponse

class ParserFrame:
    '''
    parser库人机界面
    '''
    def __init__(self):
        self.statusPath = config.getpath('parser', 'status_path')

    def index(self, request):
        t = get_template('parser/index.html')
        html = t.render(Context({}))
        return HttpResponse(html)
        

    def getStatus(self):
        '''
        返回列表
        [htmlnum , curNum, radio(100) ]
        '''
        f = open(self.statusPath)
        c = f.read()
        f.close()
        return [int(w) for w in c.split()]

    def status(self, request):
        t = get_template('parser/status.html')
        html = t.render(Context({'status': self.getStatus() }))
        return HttpResponse(html)


    def init_info(self, request):
        t = get_template('parser/init-info.html')
        html = t.render(Context({ }))
        return HttpResponse(html)
        

