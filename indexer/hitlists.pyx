from libc.stdlib cimport malloc,free,realloc
from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread

import sys
sys.path.append('../')
from Config import Config
config = Config()

import htmldb
from debug import *
from _parser.ICTCLAS50.Ictclas import Ictclas

#导入类型
Cimport Type.pyx    swin2/indexer/Type.pyx

#导入HitList 单个hit list 操作
#Cimport hitlist.pyx                 swin2/indexer/hitlist.pyx
Cimport ../_parser/InitThes.pyx     swin2/_parser/InitThes.pyx
Cimport wordwidthlist.pyx           swin2/indexer/wordwidthlist.pyx

DEF STEP = 20


cdef class HitLists:
    '''
    hit具体的爬取操作
    '''
    cdef:
        int             AddPer
        int             InitSize
        HitList         hitlists[STEP]
        object          _lists
        WordWidthList   wordwidthlist


    def __cinit__(self):
        conheader("HitLists")

        self.AddPer = 50
        self.InitSize = 100
        self.wordwidthlist = WordWidthList()
        #init list
        self.__initSpace()


    def __dealloc__(self):
        cdef:
            uint pos

        console("HitLists :: __dealloc__")

        print 'delete all C space'
        for pos in range(STEP):
            free(self.hitlists[pos]._list)
        

    cdef void __initSpace(self):
        cdef:
            uint i
            HitList cur

        console("__initSpace")

        for i in range(STEP):
            self.hitlists[i]
            self.hitlists[i]._list = <Hit *>malloc(sizeof(Hit) * self.InitSize)
            self.hitlists[i].space = self.InitSize
            self.hitlists[i].size = 0


    cdef void __addSpace(self, uint pos):
        cdef:
            uint i
            HitList *cur

        console("__addSpace")
        cur = self.hitlists+pos
        cur.space += self.AddPer
        cur._list = <Hit *>realloc(cur._list, sizeof(Hit) * cur.space)


    cdef void append(self, uint pos, Hit hit):
        cdef:
            HitList *cur

        console("append")
        cur = self.hitlists+pos
        cur.size += 1

        if cur.size == cur.space:
            print 'need to add space'
            self.__addSpace(pos)

        cur._list[cur.size-1] = hit
        #= hit
        print 'append ok'


    cdef Hit *getList(self, uint pos):
        '''
        取得单个段地址
        '''
        console("getList")
        return self.hitlists[pos]._list

    cdef ulong getSize(self, uint pos):
        console("getList")
        return self.hitlists[pos].size

    cdef void save(self):

        cdef:
            uint pos
            object path
            object ph
            char *fname

        console("save")

        print 'begin to save hits'
        #save hit num

        numstr = ''
        for pos in range(STEP):
            numstr += str(self.hitlists[pos].size)+' '
        print '.. begin wordwidthlist save'

        path = config.getpath('indexer', 'hits_num_path')
        f = open(path, 'w')
        f.write(numstr)
        f.close()

        #save hits
        path = config.getpath('indexer', 'hits_path')

        for pos in range(STEP):
            self.wordwidthlist.transWidth(self.hitlists[pos], pos)
            ph = path + str(pos)+'.hit'
            fname = ph
            fp = <FILE *>fopen(fname,"wb")
            fwrite( self.hitlists[pos]._list , sizeof(Hit), self.hitlists[pos].size, fp)
            fclose(fp)

        #self.saveToText()
    
    cdef void saveToText(self):
        path = config.getpath('indexer', 'hits_path')

        for pos in range(STEP):
            ph = path + str(pos)+'.txt'
            res = ""
            f = open(ph, 'w')
            for  i in range(self.hitlists[pos].size):
                res += str(self.hitlists[pos]._list[i].wordID) + ' '
                res += str(self.hitlists[pos]._list[i].docID) + ' '
                res += str(self.hitlists[pos]._list[i].format) + ' '
                res += "\n"
            f.write(res)


        
