import sys
sys.path.append('../')
from Config import Config
config = Config()
from debug import *
#导入类型
Cimport Type.pyx            swin2/indexer/Type.pyx
Cimport hitlist.pyx         swin2/indexer/hitlist.pyx
Cimport doclist.pyx         swin2/indexer/doclist.pyx
Cimport common.pyx          swin2/indexer/common.pyx
Cimport wordwidthlist.pyx   swin2/indexer/wordwidthlist.pyx
Cimport idxlist.pyx         swin2/indexer/idxlist.pyx

import math
from datetime import date

DEF STEP = 20


cdef class Indexer:
    '''
    对已经生存的hits 进行加工
    计算出每个词汇的 score
    '''

    cdef:
        object          htmldb
        InitHitlist     hitlist
        InitDocList     doclist
        InitWordWidthList wordwidthlist
        IdxList         idxlist
        Idx             temidx      #合并同wordID docID的记录判断
        uint            docnum
        uint            pos
        long            curWordID
        object          statusPath

    '''
    计算每个hit的私有score
    log(D/Di) * F(Wi)
    '''
    def __cinit__(self):
        conheader('Indexer') 
        self.hitlist = InitHitlist()
        self.doclist = InitDocList()
        self.idxlist = IdxList()
        self.htmldb = HtmlDB()
        self.__initDocnum()
        print 'init OK'
        self.statusPath = config.getpath('indexer', 'status_path')

    def run(self):
        '''
        完全运行主程序
        从0 - 20 
        '''
        console('run')
        hits_num = ""
        idxs_num = ""

        for i in range(STEP):
            print i
            self.init(i)
            self.cal()
            print '.. end cal'
            hits_num += str(self.hitlist.size) + ' '
            idxs_num += str(self.idxlist.size) + ' '

        print 'hits_num', hits_num
        print 'idxs_num', idxs_num

        #save idxs_num
        path = config.getpath('indexer', 'idxs_num_path')
        f = open(path, 'w')
        f.write(hits_num)
        f.close()

    cdef init(self, pos):
        console('init')
        self.pos = pos
        self.hitlist.init(pos)
        self.idxlist.init(pos)

    cdef cal(self):
        '''
        确定pos后 运行将此list处理完毕
        '''
        cdef:
            unsigned int i 
            #外部 doc score
            #外部 doc决定的score
            float  doc_score
            #内部词决定的score
            uint private_score
            object path
            Idx idx
            Hit hit
            char *ph
            Hit cur
            unsigned int temid

        console('cal')

        cur = self.hitlist.get(0)
        self.temidx.wordID  =   cur.wordID
        self.temidx.docID   =   cur.docID

        for i in range(self.hitlist.size):
            print i
            hit = self.hitlist.get(i)
            idx.wordID = hit.wordID
            idx.docID = hit.docID
            print 'private_score'
            private_score = self.calPrivateScore(i)
            print 'end private_score'
            #doc_score = self.doclist.get(hit.docID)
            idx.score = private_score #* doc_score
            print 'score cal ok'

            #合并记录值
            if not ( cur.wordID == self.temidx.wordID and cur.docID == self.temidx.wordID ):
                print 'in if'
                print i
                print 'start to append'
                self.idxlist.append(idx)
                print 'after append'
                self.temidx = idx
                temid = i
            print '合并ok'
            self.saveStatus(i+1)

        if self.hitlist.size-1 != temid:
            print self.hitlist.size - 1
            self.idxlist.append(idx)

        path = config.getpath('indexer', 'idxs_path')
        path += str(self.pos) + '.idx'
        ph = path
        self.idxlist.save(ph)

    cdef void saveStatus(self, curNum):
        cdef:
            object res

        res = 'indexer' + ' ' + str(STEP) + ' '+ str(curNum)
        radio = curNum + 0.0
        radio = radio/STEP * 100
        res += ' '+str( int(radio) )
        f = open(self.statusPath, 'w')
        f.write(res)
        f.close()



    cdef uint calPrivateScore(self, unsigned long i):
        '''
        i is a hit's index
        确定好pos后， 外界传入hit的序号，本程序计算出hit的private score
        '''
        cdef:
            Hit cur

        console('calPrivateScore')

        cur = self.hitlist.get(i)
        print 'return format docscore'
        return self.calFormatScore(cur.format) #* self.calHitedDocScore(cur.wordID)


    cdef float calHitedDocScore(self, unsigned long wordID):
        '''
        得到 命中同一个wordID的文档数目
        原有的hitlist 已经先根据wordID 然后 docID排序
        '''
        cdef:
            unsigned int docnum

        console('calHitedDocScore')
        docnum = self.wordwidthlist.get(wordID).docnum
        cdef float res = math.log( self.docnum / docnum )
        print 'get HitedDocScore', res
        return res


    cdef uint calFormatScore(self, ushort _format):
        '''
        _format 1 2 3 4
        '''
        console(' calFormatScore')

        cdef:
            uint res

        #cdef float res = math.log(math.e, _format)
        if _format == 1:
            res = 50
        elif _format == 2:
            res = 20

        elif _format == 3:
            res = 1
        #cdef float format = _format + 0.0
        #cdef float res = 1/format
        return res


    cdef __initDocnum(self):

        console(' __initDocnum ')

        self.docnum = self.htmldb.getHtmlNum()

