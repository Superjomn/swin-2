# -*- coding: utf-8 -*-
from django.db import models
from django.db import models

class Record(models.Model):
    '''
    单个记录:
        包括：
            dectitle
            url
            date
            dectext
    '''
    dectitle = models.CharField(max_length=100)
    url = models.URLField(max_length=150)
    decsource = models.TextField()
    date = models.DateField()



'''
admin.site.register(Record)
'''
