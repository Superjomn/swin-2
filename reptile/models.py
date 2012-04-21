from django.db import models
from django.contrib import admin

class HomeUrl(models.Model):
    title = models.CharField(max_length=100)
    url = models.URLField(max_length=150)
    maxpages = models.IntegerField()
    pages = models.IntegerField()


class HtmlInfo(models.Model):
    title = models.CharField(max_length=100)
    url = models.URLField(max_length=150)
    date = models.DateField()


class HtmlSource(models.Model):
    #source = models.TextField()
    parsed_source = models.TextField()
    info = models.ForeignKey(HtmlInfo)


class Urlist(models.Model):
    '''
    save urlist
    '''
    site = models.ForeignKey(HomeUrl)
    path = models.CharField(max_length=120)


class UrlQueue(models.Model):
    '''
    save urlqueue
    '''
    site = models.ForeignKey(HomeUrl)
    title = models.CharField(max_length=100)
    path = models.CharField(max_length=120)


#admin.site.register(HtmlInfo)
#admin.site.register(HtmlSource)
