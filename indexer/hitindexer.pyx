from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
import sys
sys.path.append('../')
from Config import Config
import htmldb
from _parser.ICTCLAS50.Ictclas import Ictclas
config = Config()
from debug import *

#导入类型
Cimport Type.pyx                    swin2/indexer/Type.pyx
Cimport ../_parser/InitThes.pyx     swin2/_parser/InitThes.pyx
Cimport sorter.pyx                  swin2/indexer/sorter.pyx
Cimport hitlists.pyx                swin2/indexer/hitlists.pyx

DEF STEP = 20


cdef class HitIndexer:
    '''
    生成hits
    '''
    cdef:
        #词库
        InitThes thes
        HitLists hitlists
        HitSort hitsort
        object htmldb
        object htmlnum
        object ict
        #status
        object statusPath
        uint    curHtmlNum
        uint    refreshFrequency

    def __cinit__(self):
        #database
        conheader("HitIndexer")

        self.thes = InitThes()
        self.htmldb = htmldb.HtmlDB()
        self.htmlnum = self.htmldb.getHtmlNum()
        self.ict = Ictclas( config.getpath('parser', 'ict_configure_path') )
        self.hitsort = HitSort()
        self.hitlists = HitLists()
        #status
        self.statusPath = config.getpath('indexer', 'status_path')
        self.refreshFrequency = config.getint('indexer', 'refresh_frequency')


    def run(self):
        cdef:
            uint i

        console("run")
        '''
        循环运行主程序
        '''
        for i in range(self.htmlnum):
            '''
            将所有的网页进行处理
            '''
            #print 'index %d' % i
            self.htmldb.setRecordHandle(i)
            #level 1
            format1 = self.htmldb.getUrlDec() 
            #level 2 string
            format2 =self.htmldb.getTitle()+ self.htmldb.getB() + self.htmldb.getHOne()
            #level 3 string
            format3 = self.htmldb.getContent() + self.htmldb.getHTwo()

            #开始分词及作处理
            self.indexStr(format1, 1)
            self.indexStr(format2, 2)
            self.indexStr(format3, 3)
            #status
            self.curHtmlNum = i+1
            self.saveStatus('')
            print 'begin i',i
        #进行存储
        #存储hits 和 hit_num
        self.saveStatus('sort')
        self.hitlists.save()
        self.sort()
        self.saveStatus('save')
        self.hitlists.save()


    def saveStatus(self, _type=''):
        '''
        人机界面刷新
        '''
        cdef:
            object res
            float radio

        if not _type: 
            if self.curHtmlNum%self.refreshFrequency == 0 or self.curHtmlNum==self.htmlnum:
                radio = self.curHtmlNum + 0.0
                radio = radio/self.htmlnum * 70
                res = 'hitindex' +' ' + str(self.htmlnum) + ' ' + str(self.curHtmlNum) + ' ' + str( int(radio) ) +' '+'处理中...'

                f = open(self.statusPath, 'w')
                f.write(res)
                f.close()

        elif _type == 'sort':
            res = 'hitindex' +' ' + str(self.htmlnum) + ' ' + str(self.curHtmlNum) + ' ' + str( 70 ) + ' ' +'排序中...'
            f = open(self.statusPath, 'w')
            f.write(res)
            f.close()

        elif _type == 'save':
            res = 'hitindex' +' ' + str(self.htmlnum) + ' ' + str(self.curHtmlNum) + ' ' + str( 95 ) + ' ' +'存储中...'
            f = open(self.statusPath, 'w')
            f.write(res)
            f.close()



    cdef void indexStr(self, strr, _format):
        '''
        word:词汇
        _format: 1 2 3 4
        '''
        cdef Hit hit
        console("indexStr")

        words = self.ict.split(str(strr)).split()

        for word in words:
            wordID = self.thes.find(word)
            pos = self.thes.pos(hash(word))
            docID = self.htmldb.getDocID()
            #print 'word, wordID, pos, docID', word, wordID,pos,docID

            hit.wordID = wordID
            hit.docID = docID
            hit.format = _format
            self.hitlists.append(pos, hit)

    cdef void sort(self):
        console("sort")
        '''
        排序主程序
        单独为每一个pos内的index排序
        先依照wordID排序
        然后在相同wordID内进行docID的排序
        同时记录wordID的范围表
        '''
        cdef:
            unsigned int i

        for i in range(STEP):
            self.hitsort.init(i, self.hitlists.getList(i), self.hitlists.getSize(i))
            self.hitsort.run()



