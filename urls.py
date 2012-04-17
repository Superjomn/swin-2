from django.conf.urls.defaults import patterns, include, url
# Uncomment the next two lines to enable the admin:

import os
from django.contrib import admin
from django.conf import settings

from reptile.views import hello
import reptile.views as reptile_views


urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'swin2.views.home', name='home'),
    # url(r'^swin2/', include('swin2.foo.urls')),

    # Uncomment the admin/doc line below to enable admin documentation:
    # url(r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    url(r'^reptile/', reptile_views.index),
    url(r'^admin/', include(admin.site.urls)),
    url(r'^hello/', reptile_views.hello),
    #reptile 控制 核心程序 将来是人机界面进行控制
    url(r'^reptile/resume', reptile_views.ReptileCtrl.sendResume),
    url(r'^reptile/stop', reptile_views.ReptileCtrl.sendStop),
    url(r'^reptile/init', reptile_views.ReptileCtrl.sendInit),
    url(r'^reptile/halt', reptile_views.ReptileCtrl.sendHalt),
    url(r'^reptile/run', reptile_views.ReptileCtrl.sendRun),


)
