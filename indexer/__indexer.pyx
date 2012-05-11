import sys
sys.path.append('../')
from Config import Config
config = Config()
from debug import *
#导入类型
ctypedef unsigned int   uint
ctypedef unsigned long  ulong
ctypedef unsigned short ushort
ctypedef long long llong


ctypedef unsigned int   docid
ctypedef unsigned long  wordid

cdef struct Hit:
    ulong wordID
    uint docID
    ushort format

#记录单个wordid对应的笨pos内的范围
cdef struct WordWidth:
    ulong left   #左范围
    ulong right  #右范围
    #本wordID命中的不重复的文档数目
    uint docnum
    int pos     #记录数组号
 
#倒排索引
cdef struct Idx:
    uint  wordID
    uint    docID
    uint score

#单个hitlist字段
cdef struct HitList:
    Hit *_list
    ulong size
    ulong space

   
#--------------------------------------------------
#   End of Type.pyx
#--------------------------------------------------

import sys
sys.path.append('../')
from Config import Config
config = Config()

from libc.stdlib cimport malloc,free,realloc
from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread

#导入类型

cdef class Hitlist:
    '''
    单个范围内的Hits管理
    '''
    cdef:
        int AddPer
        int InitSize

        long size
        long space
        Hit *_list


    def __cinit__(self):
        self.InitSize = 1000
        self.AddPer = 100
        self.size = 0
        self.space = 0
        self.__initSpace()

    cdef Hit get(self, unsigned long i):
        return self._list[i]

    cdef Hit *getList(self):
        return self._list

    cdef long getSize(self):
        return self.size

    cdef append(self, Hit li):
        self.size += 1
        if self.size == self.space:
            self.__addSpace()
        self._list[self.size - 1] = li

    cdef save(self, path):
        cdef:
            object ph
            char *fname
        ph = path
        fname = ph
        fp = <FILE *>fopen(fname,"wb")
        fwrite( self._list , sizeof(Hit), self.size, fp)
        fclose(fp)



    def __dealloc__(self):
        print "delete C space"
        free(self._list)

    cdef short __addSpace(self):
        '''
        if need to add space
        add space
        '''
        self.space += self.AddPer
        cdef Hit *base 
        base = <Hit *>realloc(self._list, sizeof(Hit)*self.space) 
        if not base:
            return False
        self._list = base
        return True

    cdef __initSpace(self):
        print '.. init space'
        self._list = <Hit *>malloc(sizeof(Hit) * self.InitSize)
        self.space = self.InitSize





cdef class InitHitlist:
    '''
    初始化 HitList
    每次仅仅初始化一个hitlist
    '''
    cdef: 
        unsigned int pos
        unsigned long size
        Hit *_list

    def __cinit__(self):
        pass

    cdef void init(self, unsigned int pos):
        self.__setPos(pos)
        self.__initSize()
        self.__initSpace()
        self.__initList()

    cdef Hit get(self, i):
        return self._list[i]
        
    
    def __dealloc__(self):
        print 'delete all C space'
        free(self._list)
    
    cdef void __dealloc(self):
        if self.size > 0:
            print 'delete all C space'
            free(self._list)

    cdef void __setPos(self, unsigned int pos):
        self.pos = pos
        self.__dealloc()


    cdef void __initList(self):
        path = str(self.pos)+'.hit'
        path = config.getpath('indexer', 'hits_path') + path
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"rb")
        fread(self._list, sizeof(Hit), self.size ,fp)
        fclose(fp)
    

    cdef void __initSize(self):
        path = config.getpath('indexer', 'hits_num_path')
        f = open(path)
        c = f.read()
        f.close()
        _split = c.split()
        self.size = int(_split[self.pos])
        print 'self.size', self.size
        
    cdef void __initSpace(self):
        self._list = <Hit *>malloc(sizeof(Hit)*self.size)
        
#--------------------------------------------------
#   End of hitlist.pyx
#--------------------------------------------------

import sys
sys.path.append('../')

from Config import Config
from htmldb import HtmlDB
import math
from _parser.ICTCLAS50.Ictclas import Ictclas
from datetime import date

from libc.stdlib cimport malloc,free,realloc
from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread

config = Config()


cdef class DocList:
    '''
    记录每个doc的值
    生成一个list
    '''
    cdef:
        float *_list
        int size
        int docID
        object date
        object url
        object htmldb
        object ict
        #status
        object statusPath
        uint    curHtmlNum
        uint    refreshFrequency

    def __cinit__(self):
        self.ict = Ictclas( config.getpath('parser', 'ict_configure_path') )
        self.htmldb = HtmlDB()
        self.__initSpace()
        #status
        self.statusPath = config.getpath('indexer', 'status_path')
        self.refreshFrequency = config.getint('indexer', 'refresh_frequency')

    def __dealloc__(self):
        print 'delete all C space!'
        free(self._list)


    def run(self):
        '''
        DocList运行主程序
        可以自行运行
        '''
        cdef int i
        for i in range(self.size):
            self.setRecordHandle(i)
            self.calScore()
            #status
            self.curHtmlNum = i+1
            self.saveStatus()
        self.save()


    def saveStatus(self):
        '''
        人机界面刷新
        '''
        cdef:
            object res
            float radio
        
        if self.curHtmlNum%self.refreshFrequency == 0 or self.curHtmlNum==self.size:
            radio = self.curHtmlNum + 0.0
            radio = radio/self.size * 100

            res = 'doclist' + ' ' + str(self.size) + ' ' + str(self.curHtmlNum) + ' ' + str( int(radio) )
            f = open(self.statusPath, 'w')
            f.write(res)
            f.close()




    cdef void calScore(self):
        #默认不启用 timespan
        #_score = self.getLevel() * self.getTW() / self.getWordCount()
        cdef:
            unsigned int size
            float _score

        size = max(1, self.getWordCount())
        _score = self.getLevel() / size
        self.setValue(_score)


    cdef void save(self):
        print 'begin to save doclist'
        path = config.getpath('indexer', 'doc_score_path')
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"wb")
        fwrite( self._list, sizeof(float), self.size, fp)
        fclose(fp)
        #save record num
        path = config.getpath('indexer', 'doc_score_num_path')
        f = open(path, 'w')
        f.write(str(self.size))
        f.close()
        self.saveToText()
        
    cdef void saveToText(self):
        #测试使用
        path = '/home/chunwei/swin2/data/doclist.txt'
        res = ''
        for  i in range(self.size):
            res += str(i) + ' ' + str(self._list[i])
            res += '\n'
        f=open(path, 'w')
        f.write(res)
        f.close()
        


    cdef __initSpace(self):
        '''
        取得dod数量 初始化空间
        '''
        #get doc num
        self.size = self.htmldb.getHtmlNum()
        #分配空间
        self._list = <float *>malloc(sizeof(float) * self.size)

    cdef void setValue(self, float value):
        self._list[ self.docID ] = value
        

    cdef void setRecordHandle(self, int docID):
        htmlinfo = self.htmldb.setRecordHandle(docID)
        self.date = htmlinfo.date
        self.url = htmlinfo.url
        self.docID = docID

    cdef float getLevel(self):
        '''
        计算页面level值
        '''
        cdef:
            float _level
            unsigned int size
            
        size = self.url.count('/')

        if self.url[-1] == '/':
            _level = size  - 3
        else:
            _level = size - 2

        _level += 1.1


        return 1/_level


    cdef float getTW(self):
        '''
        计算时间值
        '''
        cdef:
            int days

        days = (date.today() - self.date).days
        return math.log(math.e, days)

    cdef int getWordCount(self):
        '''
        计算词汇数目
        '''
        _content = self.htmldb.getContentByIndex(self.docID)
        word_split = self.ict.split(str(_content)).split()
        return len(word_split)



cdef class InitDocList:
    '''
    通过doclist文件初始化doclist
    '''
    cdef:
        float *_list
        int size
        object htmldb

    def __cinit__(self):
        '''
        init float space 
        '''
        #init values
        self.size = 0
        self.htmldb = HtmlDB()
        #具体的初始化工作
        self.__init()

    def __init(self):
        self.__initSize()
        self.__initSpace()
        self.__initList()

    def get(self, int docID):
        return self._list[docID]

    cdef __initSize(self):
        #init list
        path = config.getpath('indexer', 'doc_score_num_path')
        f = open(path)
        c = f.read()
        f.close()
        self.size = int(c)
        
        
    cdef __initList(self):
        path = config.getpath('indexer', 'doc_score_path')
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph, "rb")
        fread(self._list, sizeof(float), self.size ,fp)
        fclose(fp)


    cdef __initSpace(self):
        '''
        取得dod数量 初始化空间
        '''
        #分配空间
        self._list = <float *>malloc(sizeof(float) * self.size)
        
    def __dealloc__(self):
        print 'delete all C space!'
        free(self._list)

#--------------------------------------------------
#   End of doclist.pyx
#--------------------------------------------------

cdef getNumFromFile(path):
    '''
    如果文件中只包含一个num 则直接返回
    如果文件中包含多个num 则返回列表
    '''
    f = open(path)
    c = f.read()
    f.close()
    return int(c)

cdef getNumsFromFile(path):
    f = open(path)
    c = f.read()
    f.close()
    _res = []
    _split = c.split()
    for word in _split:
        _res.append(int(word))
    return _res
#--------------------------------------------------
#   End of common.pyx
#--------------------------------------------------

from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
from libc.stdlib cimport malloc,free, realloc
import sys
sys.path.append('../')
from debug import *
from Config import Config
config = Config()


cdef class WordWidthList:
    '''
    在HitList内存中生成后执行
    记录每个wordID对应的hit宽度
    此处与HitList合作 记录HitList中每个wordID对应的width
    note:
        width为每个List[i]数组对应的宽度 
    '''
    cdef:
        int AddPer
        int InitSize

        long size
        long space
        WordWidth *_list


    def __cinit__(self):
        conheader('WordWidthList')
        self.InitSize = 1000
        self.AddPer = 100
        self.size = 0
        self.space = 0
        self.__initSpace()


    def __dealloc__(self):
        console('__dealloc__')
        print "delete C space"
        free(self._list)

    def __dealloc(self):
        '''
        日常的内存清扫
        '''
        if self.size > 0:
            print '清扫下内存'
            free(self._list)
            self.size = 0
            self.space = 0
            print '重新 init'
            self.__initSpace()



    cdef short transWidth(self, HitList hitlist, uint pos):
        '''
        运行主程序
        每次处理一个段 
        处理的hitlist必须已经根据wordid及docid进行排序
        range(left, right)
        '''
        cdef: 
            long i, j
            long wordID
            long left
            WordWidth wordwidth
            WordWidth *curwidth
            unsigned int docID
            unsigned int docnum
            Hit *_hits

            
        self.__dealloc()
        console('transWidth')
        
        _size = hitlist.size
        _hits = hitlist._list
            
        print '.. _size', _size
        wordID = _hits[0].wordID
        left = 0

        for i in range(_size):
            '''
            对于每一个 List
            '''
            if _hits[i].wordID != wordID:
                wordwidth.left =  left
                wordwidth.right = i
                left = i
                wordwidth.pos = pos
                self.append(wordwidth)
                wordID = _hits[i].wordID

        #the last one
        wordwidth.left = left
        wordwidth.right = _size
        self.append(wordwidth)
        
        #生成docnum
        curwidth = self._list+0
        for i in range(self.size):
            curwidth = self._list + i
            docID = _hits[ curwidth.left ].docID
            docnum = 1
            curwidth.docnum = docnum

            for j in range(curwidth.left, curwidth.right):
                if docID != _hits[j].docID:
                    docnum += 1
                    docID = _hits[j].docID
                    curwidth.docnum = docnum
        #the last one
       

    cdef void __save(self):
        console('__save')
        print 'begin to save doclist'
        #save num
        path = config.getpath('indexer', 'word_width_num_path')
        f = open(path, 'w')
        f.write(str(self.size))
        f.close()
        #save data
        path = config.getpath('indexer', 'word_width_path')
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"wb")
        fwrite( self._list, sizeof(WordWidth), self.size, fp)
        fclose(fp)

        self.__saveToText()

    cdef void saveToText(self):
        print '-'*5000
        path = config.getpath('indexer', 'word_width_path')
        path += '.txt'
        res = ""

        for i in range(self.size):
            res += str(self._list[i].left) + ' '
            res += str(self._list[i].right) + ' '
            res += str(self._list[i].docnum) + ' '
            res += str(self._list[i].pos) + ' '
            res += "\n"

        f = open(path, 'w')
        f.write(res)
        f.close()
            
        


    cdef __initSpace(self):
        console('__initSpace')
        print '.. init space'
        self._list = <WordWidth *>malloc(sizeof(WordWidth) * self.InitSize)
        self.space = self.InitSize


    cdef WordWidth *getList(self):
        console('getList')
        return self._list


    cdef long getSize(self):
        return self.size


    cdef short __addSpace(self):
        '''
        if need to add space
        add space
        '''
        console('__addSpace')
        self.space += self.AddPer
        cdef WordWidth *base 
        base = <WordWidth *>realloc(self._list, sizeof(WordWidth)*self.space) 
        if not base:
            return False
        self._list = base
        return True


    cdef append(self, WordWidth li):
        self.size += 1
        if self.size == self.space:
            self.__addSpace()
        self._list[self.size - 1] = li



    cdef WordWidth get(self, long i):
        console('get')
        return self._list[i]



cdef class InitWordWidthList:
    '''
    从文件中恢复wordwidthlist
    '''
    cdef:
        long size
        WordWidth *_list

    def __cinit__(self):
        self.initSize()
        self.initList()
    
    def __dealloc__(self):
        print 'delete all C space'
        free(self._list)

    cdef get(self, long wordID):
        '''
        取得wordID对应的hits记录范围及位置
        '''
        return self._list[wordID]
        

    cdef initSize(self):
        cdef object path
        path = config.getpath('indexer', 'word_width_num_path')
        f = open(path)
        c = f.read()
        f.close()
        self.size = int(c)
        

    cdef initList(self):
        path = config.getpath('indexer', 'word_width_path')
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"rb")
        fread(self._list, sizeof(WordWidth), self.size ,fp)
        fclose(fp)
        
#--------------------------------------------------
#   End of wordwidthlist.pyx
#--------------------------------------------------

import sys
from debug import *
sys.path.append('../')
from Config import Config
config = Config()

from libc.stdlib cimport malloc,free,realloc
from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread


cdef enum bool:
    false   =   0
    true    =   1

cdef struct QueryRes:
    uint    docID
    float  score
    bool    able     #0 1 判定此记录是否有效

cdef struct QueryResList:
    QueryRes    *_list
    uint        size
    uint        space
    
    
#--------------------------------------------------
#   End of ../query/Type.pyx
#--------------------------------------------------


cdef class IdxList:
    '''
    最终倒排索引的list管理
    '''
    cdef:
        Idx *_list
        ushort pos
        ulong size
        ulong space
        ulong InitSize
        ulong AddPer

    def __cinit__(self):
        conheader('IdxList')

        self.InitSize = 200
        self.AddPer = 50
        self.__initSpace()
        self.size = 0

    def init(self, ushort pos):
        '''
        负责内存刷新
        '''
        self.setPos(pos)
        #内存准备
        self.__initSpace()

    

    cdef void setPos(self, ushort pos):
        '''
        清空老的内存
        '''
        self.pos = pos
        self.__dealloc()
        self.space = 0
        self.size = 0

        

    cdef void append(self, Idx idx):
        console('append')

        self.size += 1
        if self.size == self.space:
            self.__addSpace()
        self._list[self.size - 1] = idx

    cdef save(self, char *path):
        console('save')
        cdef FILE *fp=<FILE *>fopen(path,"wb")
        fwrite( self._list, sizeof(Idx), self.size, fp)
        fclose(fp)
        #self.saveToText(path)

    cdef saveToText(self, path):
        path += '.txt'
        res = ""
        for i in range(self.size):
            res += str(self._list[i].wordID) + ' '
            res += str(self._list[i].docID) + ' '
            res += str(self._list[i].score) + ' '
            res += "\n"

        f = open(path, 'w')
        f.write(res)
        f.close()

    def __dealloc__(self):
        console('__dealloc__')
        print 'delete all C space!'
        free(self._list)


    cdef void __dealloc(self):
        if self.size > 0:
            free(self._list)
        self.size = 0


    cdef short __addSpace(self):
        '''
        if need to add space
        add space
        '''
        console('__addSpace')
        self.space += self.AddPer
        cdef Idx *base = <Idx *>realloc(self._list, sizeof(Idx)*self.space) 
        if not base:
            return False
        self._list = base
        return True

    cdef __initSpace(self):
        console('IdxList __initSpace')
        print '.. IdxList init space'
        self._list = <Idx *>malloc(sizeof(Idx) * self.InitSize)
        self.space = self.InitSize








cdef class InitIdxList:
    '''
    初始化单个idxlist
    '''
    cdef: 
        uint pos
        long size
        Idx *_list
        #scope
        uint left
        uint right
        long curWid

    def __cinit__(self):
        conheader('InitIdxList')
        self.pos = 0
        self.size = 0
        self.left = 0
        self.right = 0
        self.curWid = 0


    cdef void init(self, uint pos):
        '''
        只载入一个段的idxlist
        '''
        console('init')
        #先清空之前的内存
        self.__dealloc()
        #开启新的空间 继续init
        self.__setPos(pos)
        self.__initSize()
        self.__initSpace()
        self.__initList()


    cdef Idx get(self, i):
        console('get')
        return self._list[i]

    
    cdef QueryResList find(self, long wordID):
        '''
        查找 并返回 ResList结果
        '''
        console('find')
        #print 'find wordID:', wordID
        self.curWid = wordID
        #产生对应的范围 (self.left, self.right)
        self.__posWidScope()
        return self.__transResList()


    cdef inline QueryResList __transResList(self):
        '''
        将(self.left , self.right)范围内的idx
        转化为 QueryResList返回
        '''
        cdef:
            QueryResList reslist
            uint i, j
            uint size
            Idx *curIdx
            QueryRes *curRes

        console('__transResList')
        size = self.right - self.left + 1
        #初始化空间
        print 'malloc reslist size:',size
        reslist._list = <QueryRes *>malloc(sizeof(QueryRes)*size)
        print 'end malloc'
        reslist.size = size
        reslist.space = size

        #QueryResList index
        j=0
        for i in range(self.left, self.right+1):
            '''
            开始赋值 QueryResList._list
            '''
            #print i
            curIdx = self._list+i
            curRes = reslist._list + j
            #开始赋值
            curRes.docID = curIdx.docID
            curRes.score = curIdx.score
            curRes.able = true

            j+=1

        return reslist




        

    cdef inline uint __posWidMid(self):

        '''
        利用二分发确定wid的大概位置
        '''
        cdef:
            uint fir
            uint mid
            uint end

        self.left = 0 
        self.right = 0

        fir = 0
        mid = 0
        end = self.size - 1
        
        console('__posWidMid')
        '''
        print 'self.curWid:', self.curWid
        print 'self.size', self.size
        print 'fir, mid, end:', fir,mid,end
        print 'left.wordID, right:', self._list[0].wordID, self._list[self.size-1].wordID
        '''

        while fir<end:
            mid = (fir+end)/2
            if self.curWid > self._list[mid].wordID:
                fir = mid+1

            elif self.curWid < self._list[mid].wordID:
                end = mid-1

            else:
                break

        if fir == end:
            if self._list[fir].wordID != self.curWid:
                #wid在文件中不存在
                return 0

            else:
                return mid

        elif fir>end:
            return 0

        else:
            return mid


    cdef inline void __posWidScope(self):

        '''
        确定wid在hit列表中范围
        需要另外的wid的hash表支持
        '''
        cdef:

            int i
            uint mid

        console('__posWidScope')
        mid = self.__posWidMid()

        i = mid
        #print 'pos mid:', i
        #print 'mid wordID', self._list[i].wordID

        while i-1>=0:
            if self._list[i-1].wordID == self.curWid:
                i -= 1
            else:
                break

        self.left = i
        
        i = mid
        while i+1 <= self.size - 1:
            if self._list[i+1].wordID == self.curWid:
                i += 1
            else:
                break

        self.right = i

        #print 'scope: left,right', self.left, self.right
        #print 'scope wordID: left,right', self._list[self.left].wordID, self._list[self.right].wordID


        
    
    def __dealloc__(self):
        print 'delete all C space'
        free(self._list)

    cdef void __dealloc(self):
        '''
        明确进行内存整理
        '''
        console('__dealloc')
        print 'delete C Idx list space!'
        if self.size > 0:
            free(self._list)

        self.size = 0

    cdef void __setPos(self, unsigned int pos):
        console('__setPos')
        #print 'setPos:',pos
        self.pos = pos
        self.__dealloc()


    cdef void __initList(self):
        console('__initList')
        path = str(self.pos)+'.idx'
        path = config.getpath('indexer', 'idxs_path') + path
        #print 'init path', path
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"rb")
        fread(self._list, sizeof(Idx), self.size, fp)
        fclose(fp)
    

    cdef void __initSize(self):
        console('__initSize')
        path = config.getpath('indexer', 'idxs_num_path')
        f = open(path)
        c = f.read()
        f.close()
        _split = c.split()
        self.size = int(_split[self.pos])
        #print 'size', self.size
        
    cdef void __initSpace(self):
        console('InitIdxList __initSpace')
        #清扫内存
        print 'begin to malloc'
        self._list = <Idx *>malloc(sizeof(Idx)*self.size)
        print 'end malloc'
 
 


#--------------------------------------------------
#   End of idxlist.pyx
#--------------------------------------------------


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
            res = 10
        elif _format == 2:
            res = 4

        elif _format == 3:
            res = 1
        #cdef float format = _format + 0.0
        #cdef float res = 1/format
        return res


    cdef __initDocnum(self):

        console(' __initDocnum ')

        self.docnum = self.htmldb.getHtmlNum()

#--------------------------------------------------
#   End of indexer.pyx
#--------------------------------------------------

