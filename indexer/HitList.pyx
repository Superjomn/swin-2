from libc.stdlib cimport malloc,free

import sys
sys.path.append('../')
from Config import Config
config = Config()
import htmldb
from ICTCLAS50.Ictclas import Ictclas

Cimport Hit.pyx     swin2/indexer/Hit.pyx
#导入类型
Cimport Type.pyx    swin2/indexer/Type.pyx

#导入List 单个hit list 操作
Cimport List.pyx    swin2/indexer/List.pyx

Cimport ../_parser/InitThes.pyx     swin2/_parser/InitThes.pyx

DEF STEP = 20

cdef class HitList:
    '''
    hit具体的爬取操作
    '''
    cdef:
        object _lists

    def __cinit__(self):
        #init thes
        self.thes = InitThes()
        #init lists
        self._lists = []
        for i in range(STEP):
            l = List()
            self._lists.append(l)

    cdef void append(int i, Hit hit):
        self._lists[i].append(hit)




