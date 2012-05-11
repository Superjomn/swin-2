from django.db import models

class HtmlInfo(models.Model):
    siteID = models.IntegerField()
    title = models.CharField(max_length=100)
    url = models.URLField(max_length=150)
    date = models.DateField()
    filetitle = models.URLField(max_length=150) 


class HtmlSource(models.Model):
    #source = models.TextField()
    parsed_source = models.TextField()
    info = models.ForeignKey(HtmlInfo)


