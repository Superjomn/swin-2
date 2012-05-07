# -*- coding: utf-8 -*-
import urllib2  
import StringIO  
import gzip  
import string  

opener = urllib2.build_opener()     
def requestSource(url):

    request = urllib2.Request(url) 
    request.add_header('Accept-encoding', 'gzip')
    print '.. request', request

    try:            
        page = opener.open(request,timeout=2) #设置超时为2s
        print '.. page', page

        if page.code == 200:      
            predata = page.read()
            print '.. predata', predata
            pdata = StringIO.StringIO(predata)
            gzipper = gzip.GzipFile(fileobj = pdata)  
            
            try:  
                data = gzipper.read()  
            except(IOError):  
                data = predata
                
            try:  
                if len(data)<300:
                    return False
                #begain to parse the page
                return data

            except:  
                print 'not a useful page'
        page.close()  
    except:  
        print 'end error'  


print requestSource('http://www.cau.edu.cn')


