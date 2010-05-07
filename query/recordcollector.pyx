import sys
from django.core.management import setup_environ
sys.path.append('../../')
from swin2 import settings
#import settings 
setup_environ(settings)
sys.path.append('../')
from query.models import Record

cdef class RecordCollector:
    cdef:
        object words


    def __cinit__(self):
        self.words = None

    
    cdef object getRecord(self, object docIDs, words):
        '''
        返回形式
            [
                {
                    url:xxx,
                    title:xxx
                }
            ]
        '''
        cdef:
            unsigned int docID
            object record
            object res

        
        self.words = words
        res = []
        for docID in docIDs:
            record = Record.objects.filter(id = docID)[0]
            res.append(
                [
                    self.addHighLightt(record.dectitle),
                    record.url,
                    record.date,
                    self.addHighLightt(record.decsource) ,
                ]
            )

        return res


    cdef inline object addHighLightt(self, text):
        '''
        添加高亮
        '''
        for w in self.words:
            print w
        print 'end Hightlight-----------------------------------'

        for word in self.words:
            text = text.replace(word, '<span class="hi">'+word+'</span>')
            print 'replacing .................'
            print text
        return text



    cdef object transImagesRes(self, object values):
        cdef:
            object res

        res = {
            'url':value.url,
            'path':value.path,
            'width':value.width,
            'height':value.height
        }
        return res


    cdef object getImages(self, object images):
        '''
        返回形式
            [
                {
                    url:    xxx,
                    path:   xxx,
                    width:  w,
                    height: h
                }
            }
        '''
        cdef:
            object res
            uint i

        res = []
        for image in images:
            print 'image', image
            res.append(self.transImageRes(image))

        print 'final res', res

        return res


    cdef object transFileRes(self, values):
        cdef:
            object res

        res = {
            'title' : value.title, 
            'url'   : value.url,
        }

        return res



    cdef object getFiles(self, object files):
        '''
        返回形式
            [
                {
                    title:  xxx,
                    url:    xxx,
                }
            ]
        '''
        cdef:
            object res

        return [self.transFileRes(res) for res in files]



        
