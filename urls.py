# -*- coding: utf-8 -*-
from django.conf.urls.defaults import patterns, include, url
# Uncomment the next two lines to enable the admin:
import os
from django.contrib import admin
from django.conf import settings

import reptile.views as reptile_views

reptileframe = reptile_views.ReptileFrame()
reptilectrl = reptile_views.ReptileCtrl()

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
    url(r'^hello/', reptileframe.hello),
    #界面
    #url(r'^reptile/$', reptileframe.index),
    #url(r'^reptile/infoform/$', reptileframe.infoform),
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
