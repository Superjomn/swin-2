# -*- coding: utf-8 -*-
from django.db import models
from django.contrib import admin

class HomeUrl(models.Model):
    title = models.CharField(max_length=100)
    url = models.URLField(max_length=150)
    maxpages = models.IntegerField()
    pages = models.IntegerField()


class HtmlInfo(models.Model):
    #记录siteID    
    siteID = models.IntegerField()
    title = models.CharField(max_length=100)
    url = models.URLField(max_length=150)
    date = models.DateField()
    filetitle = models.URLField(max_length=150) 


class HtmlSource(models.Model):
    #source = models.TextField()
    parsed_source = models.TextField()
    info = models.ForeignKey(HtmlInfo)


class Urlist(models.Model):
    '''
    save urlist
    urlist:  long hashvalue
    '''
    site = models.ForeignKey(HomeUrl)
    hashvalue = models.IntegerField()


class UrlQueue(models.Model):
    '''
    数据库中的url记录
    '''
    siteID = models.IntegerField()
    title = models.CharField(max_length=100)
    url = models.CharField(max_length=120)
    #type = models.CharField(max_length=5)
    #如果为 file , 则 toDocID>0
    #如果为原始态的htmlsource 直接存储
    toDocID = models.IntegerField()
    


#-------------- file --------------------------------
class ImageFile(models.Model):
    '''
    图片文件
    png jpeg jpg gif
    '''
    height = models.IntegerField()
    width = models.IntegerField()
    path = models.CharField(max_length=70)
    url = models.CharField(max_length=100)
    #doc = models.ForeignKey(HtmlInfo)
    todocid = models.IntegerField()


class TextFile(models.Model):
    '''
    文本文件
    doc xls 
    但是此处与图片不同 此为docid
    '''
    #标题逻辑
    title = models.CharField(max_length=50)
    url = models.CharField(max_length=100)
    #doc = models.ForeignKey(HtmlInfo)
    todocid = models.IntegerField()



'''
admin.site.register(HomeUrl)
admin.site.register(HtmlInfo)
admin.site.register(HtmlSource)
admin.site.register(Urlist)
admin.site.register(UrlQueue)
'''
