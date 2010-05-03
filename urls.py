# -*- coding: utf-8 -*-
from django.conf.urls.defaults import patterns, include, url
# Uncomment the next two lines to enable the admin:
import os
from django.contrib import admin
from django.conf import settings

from userframe.reptileframe import ReptileFrame
from query.views import QueryFrame

#import reptile.views as reptile_views
queryframe = QueryFrame()
reptileframe = ReptileFrame()

print 'init ok reptile run'

def initReptileCtrl(request):
    global reptilectrl
    reptilectrl = reptile_views.ReptileCtrl()

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'swin2.views.home', name='home'),
    # url(r'^swin2/', include('swin2.foo.urls')),

    # Uncomment the admin/doc line below to enable admin documentation:
    # url(r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    url(r'^admin/', include(admin.site.urls)),
    #界面
    #query 
    ('^index/$', queryframe.index),
    ('^index/more_sites/$', queryframe.more_sites),
    ('^search/$', queryframe.search),
    

    #info
    url(r'^reptile/$', reptileframe.index),
    url(r'^reptile/default-info/$', reptileframe.default_info),
    url(r'^reptile/init-info/$', reptileframe.init_info),
    url(r'^reptile/init-form/', reptileframe.init_form),
    url(r'^reptile/init-form-info/', reptileframe.init_form_info),
    url(r'^reptile/resume-info/', reptileframe.resume_info),
    url(r'^reptile/halt-info/$', reptileframe.halt_info),
    url(r'^reptile/stop-info/$', reptileframe.stop_info),
    #commands
    url(r'^reptile/init/$', reptileframe.init),
    url(r'^reptile/start/$', reptileframe.start),
    url(r'^reptile/status/$', reptileframe.status),
    ##control
    #url(r'^initreptile/$', initReptileCtrl),
    #url(r'^reptile/resume', reptilectrl.sendResume),
    #url(r'^reptile/stop', reptilectrl.sendStop),
    #url(r'^reptile/init', reptilectrl.sendInit),
    #url(r'^reptile/halt', reptilectrl.sendHalt),
    #url(r'^reptile/run', reptilectrl.sendRun),

    (r'^media/(?P<path>.*)$', 'django.views.static.serve',
        {'document_root': '/home/chunwei/swin2/media/'}),


)
