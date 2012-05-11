# -*- coding: utf-8 -*-
import random
import time
import math
from django.shortcuts import render_to_response

class Status:
    def __init__(self):
        self.status = {}
        self.pagenum = 9203
        self.page = 0

    def getStatus(self, request):
        self.page += random.randint(10, 30)
        time.sleep(1)
        randio = math.ceil( (self.page+0.0)/self.pagenum * 100 )
        res = [self.pagenum, self.page, randio, '解析中...']
        return render_to_response('indexer/status.html', {'status':res})    


        
