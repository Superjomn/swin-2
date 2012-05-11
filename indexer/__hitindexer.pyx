from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
import sys
sys.path.append('../')
from Config import Config
import htmldb
from _parser.ICTCLAS50.Ictclas import Ictclas
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

from libc.stdio cimport fopen,fclose,fwrite,FILE,fread
from libc.stdlib cimport malloc,free

import sys
sys.path.append('../')
from Config import Config
config = Config()

from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
from libc.stdlib cimport malloc,free
import os
import sys
sys.path.append('../')
from Config import Config
config = Config()

DEF STEP = 20

cdef struct HI:
    long left #左侧范围
    long right #右侧范围

cdef class CreateHashIndex:
    '''
建立一级hash参考表
使用较复杂的中分法 单独作为一类
传入 划分数目： step
结果将会把完整hash划分为step步
'''
    cdef:
        long* wlist
        long size
        long long left #左侧最小hash
        long long right #右侧最大hash
        long step


    def __cinit__(self, left, right):
        '''
init
li : 词库list '''
        self.left = left
        self.right = right
        print '.. create hash index'
        print 'left : right', self.left, self.right
        self.step = long( (self.right - self.left) / STEP ) + 1
        print '.. right - left', self.right - self.left
        print '.. self.step', self.step

    cdef void initList(self, long* li, long size):
        self.wlist = li
        self.size = size

    cdef createHash(self):
        '''
产生hash index
'''
        cdef:
            HI hashIndex[STEP]
            int i
            int cur_step
            long minidx
        
        cur_step=0
        minidx = self.left
        print '.. size:', self.size
        print '.. max', self.right

        for i in range(STEP):
            #寻找边界
            minidx += self.step
            print i,'minidx',minidx
            hashIndex[i].left = cur_step
            hashIndex[i].right = self.find(minidx)-1
            cur_step = hashIndex[i].right
            print i,'left,right', hashIndex[i].left, hashIndex[i].right

        self.__saveHash(hashIndex)
        self.__saveWidth()


    cdef __saveHash(self, HI *hi):
        '''
将hash参考表用二进制文件方式进行保存
'''
        print '.. begin to save hash'
        cdef object path = config.getpath('parser', 'hash_index_path')
        cdef char* ph = path
        cdef FILE *fp = <FILE *>fopen(ph,"wb")
        fwrite(hi, sizeof(HI), STEP, fp)
        fclose(fp)
        print '.. succeed save hash'


    cdef __saveWidth(self):
        '''
save left right
'''
        print '.. save width'
        path = config.getpath('parser', 'hash_index_width')
        f = open(path, 'w')
        content = str(self.left) + ' ' + str(self.right)
        f.write(content)
        f.close()
        

    cdef long v(self, long data):
        '''
将元素比较的属性取出
'''
        return data

    def show(self):
        
        for i in range(self.size):
            print self.wlist[i]

    cdef int find(self,long data):

        '''
具体查取值
'''

        #使用更加常规的方式
        cdef:
            int i

        for i in range(self.size):
            if self.wlist[i] > data:
                return i-1
        #最后一个词汇
        print 'last data'
        return self.size


cdef class InitHashIndex:
    '''
init he hash index
'''
    #define the hash index
    cdef HI hi[STEP]
    cdef long *li

    def __cinit__(self):
        '''
init
'''
        print 'init hashindex'
        cdef object path = config.getpath("parser", "hash_index_path")
        cdef char *ph = path
        print 'path', path
        cdef FILE *fp = <FILE *>fopen(ph, "rb")
        fread(self.hi, sizeof(HI), STEP, fp)
        fclose(fp)
        print 'hashindex init ok'

    cdef initList(self, long* wordlist):
        self.li = wordlist
        
    def show(self):
        print '.. show hashindex'
        for i in range(STEP):
            print self.hi[i].left, self.hi[i].right

    def pos(self, long hashvalue):
        '''
pos the word by hashvalue
if the word is beyond hash return -1
else return the pos
'''
        cdef int cur = -1
        
        if hashvalue> self.li[self.hi[0].left] :
            cur += 1
        else:
            return 0

        while hashvalue > self.li[self.hi[cur].left] :
            cur+=1
            if cur==STEP:
                return STEP-1
        return cur-1
#--------------------------------------------------
#   End of ../_parser/HashIndex.pyx
#--------------------------------------------------


cdef class InitThes:
    '''
初始化词库
'''
    cdef:
        long *__list
        long size
        InitHashIndex hashIndex


    def __cinit__(self):
        print '.. cinit'
        self.hashIndex = InitHashIndex()
        self.hashIndex.show()
        self.__initList()

    def __dealloc__(self):
        '''
释放c内存空间
'''
        print 'delete all C space'
        free(self.__list)

    def __del__(self):
        '''
释放c内存空间
'''
        print 'delete all C space'
        free(self.__list)
    
    
    cdef __initList(self):
        '''
将二进制文件载入内存
'''
        print '__initList'
        #get thes size
        cdef object size
        size_ph = config.getpath('parser', 'thes_size_path')
        f = open(size_ph)
        c = f.read()
        f.close()
        size = int(c)
        print '.. thes size:', size
        self.size = size
        #malloc space
        print '.. malloc space'
        self.__list = <long *>malloc(sizeof(long) * self.size)
        #read thes file
        cdef object path
        path = config.getpath('parser', 'thes_path')
        cdef char*ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"rb")
        fread(self.__list, sizeof(long), self.size ,fp)
        fclose(fp)
        self.hashIndex.initList(self.__list)

    def pos(self, dv):
        '''
返回hashindex对应块
'''
        return self.hashIndex.pos(dv)


    def find(self, v):
        '''
通过hashvalue查找wordID
若存在 返回位置
若不存在 返回 0
'''
        #print '初始化数据ok'
        cdef long dv = hash(v)
        return self.findByHash(dv)

    cdef findByHash(self, long dv):
        cdef:
            long l
            long fir
            long mid
            long end
            long pos
            HI cur #范围


        pos=self.hashIndex.pos( dv )
        print 'hash pos', pos

        if pos!=-1 and pos<STEP:
            cur = self.hashIndex.hi[pos]
        else:
            print "the word is not in wordbar or pos wrong"
            return False
        
        #取得 hash 的一级推荐范围
        fir=cur.left
        end=cur.right
        print 'hash left right hashvalue', self.__list[fir], self.__list[end], dv
        mid=fir
        '''
fir = 0
end = self.size-1
mid = fir
'''
        if dv > self.__list[end]:
            return 0

        #print '词库: fir,end,mid',fir,end,mid

        while fir<end:

            mid=(fir+ end)/2

            if ( dv > self.__list[mid] ):
                fir = mid + 1
                #print '1 if fir',fir

            elif dv < self.__list[mid] :
                end = mid - 1
                #print '1 elif end',end

            else:
                break

        if fir == end:

            if self.__list[fir] > dv:
                return 0

            elif self.__list[fir] < dv:
                return 0

            else:
                return end#需要测试
                
        elif fir>end:
            return 0

        else:
            return mid#需要测试



#--------------------------------------------------
#   End of ../_parser/InitThes.pyx
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


#导入类型

cdef class Sorter:
    '''
    排序主算法	
    '''
    cdef Hit *dali
    cdef long length

    cdef void init(self, Hit *data, long length):
        '''
        init 
        '''
        self.dali = data
        self.length = length


    cdef void saveToText(self):
        res = ""
        for i in range(self.length):
            res += str(self.dali[i].wordID) + " "
            res += str(self.dali[i].docID) + " "
            res += "\n"

        f = open('../data/wid_sorted_hits.txt', 'w')
        f.write(res)
        f.close()


    cdef long gvalue(self, Hit data):
        '''
		返回需要进行比较的值
        '''
        return data.wordID


    cdef void quicksort(self,long p,int q):
        cdef long j
        a=self.dali
        st=[]

        while True:
            while p<q:
                j=self.partition(p,q)

                if (j-p)<(q-j):
                    st.append(j+1)
                    st.append(q)
                    q=j-1

                else:
                    st.append(p)
                    st.append(j-1)
                    p=j+1

            if(len(st)==0):
                return

            q=st.pop()
            p=st.pop()


    cdef long partition(self,int low,int high):
        cdef Hit v
        v=self.dali[low]

        while low<high:

            while low<high and self.gvalue( self.dali[high] ) >= self.gvalue( v ):
                high-=1
            self.dali[low]=self.dali[high]

            while low<high and self.gvalue( self.dali[low] )<=self.gvalue( v ):
                low+=1
            self.dali[high]=self.dali[low]

        self.dali[low]=v

        return low

#------------------------ Sorter end --------------------------------------

cdef class WidSort(Sorter):
    '''
    根据 wid 进行排序
    不包括最后 根据 docid 进行排序
    '''
    #词库
    cdef object wordbar

    '''
    cdef void init1(self,Hit *data, long length):
        #初始化 父亲 Sorter
        Sorter.init(self, data,length)
    '''

    cdef long gvalue(self, Hit data):
        '''
        重载 Sorter 方法
		返回需要进行比较的值
        '''
        cdef long wid = data.wordID
        #返回 hit 对应 word 的 hashvalue
        return wid



cdef class DidSort(Sorter):
    '''
    根据 did 进行排序
    不包括 在 耽搁 did 文件中 根据 wid 进行排序
    '''
    '''
    cdef void init1(self,Hit *data,long length):
        #初始化 父亲 Sorter
        Sorter.init(self,data,length)
    '''
    cdef long gvalue(self, Hit data):
        '''
        返回排序字段
        '''
        return data.docID



   

cdef class HitSort:
    '''
    排序主程序
    单独为每一个pos内的index排序
    先依照wordID排序
    然后在相同wordID内进行docID的排序
    同时记录wordID的范围表
    '''
    cdef:
        Hit *_list
        int hitid
        long size #hitlist的长度
        #long width[List_num]
        WordWidthList widthlist
        WidSort widsort
        DidSort didsort

    def __cinit__(self):
        self.widthlist = WordWidthList()
        self.widsort = WidSort()
        self.didsort = DidSort()
    
    cdef init(self, int hitid,  Hit *list, long size):
        '''
        hitid:  hit 的文件编号
        需要传入一个pos内的index 然后进行处理
        index 为 一期索引
        '''
        self._list = list
        self.hitid = hitid
        self.size = size
        self.widsort.init(list, size)
        self.didsort.init(list, size)

    def run(self):
        '''
        运行主程序 一系列动作
        '''
        cdef HitList temhitlist
        self.wordidsort()
        #此处为临时产生width
        print 'end wordidsort'
        #trans type
        temhitlist.size = self.size
        temhitlist._list = self._list

        self.widthlist.transWidth(temhitlist, 0)
        self.docidsort()
        self.widthlist.saveToText()


    cdef void wordidsort(self):
        '''
        先对wordID进行排序
        然后在同wordID内对docID进行排序
        '''
        print 'begin to sort wid'
        self.widsort.quicksort(0, self.size-1)
        self.widsort.saveToText()
        print 'end wordidsort'


    cdef void docidsort(self):
        '''
        在同一个wordID范围内进行docID的排序
        '''
        cdef:
            ulong _size
            long i
            WordWidth width

        _size = self.widthlist.getSize()

        for i in range(_size):
            width = self.widthlist.get(i)
            print '-'*50
            print 'width: ',i, 'left:right', width.left, width.right
            print 'words:'
            for i in range(width.left, width.right):
                print self._list[i].wordID, self._list[i].docID
            print '-'*50
                
            if width.right - width.left > 1:
                self.didsort.quicksort(width.left, width.right-1)

    cdef void save(self):
        #self.__saveWidth()
        self.__saveIndex()
    
    '''
    cdef  void __saveWidth(self):
        print 'save word width'
        path = config.getpath('indexer', 'hits_path')
        cdef object fn
        fn = path + str(self.hitid) + '.width'
        cdef char *fname =  fn
        cdef FILE *fp=<FILE *>fopen(fname,"wb")
        fwrite(self.widthlist.getList(), sizeof(WordWidth), self.widthlist.getSize(), fp)
        fclose(fp)
    '''


    cdef void __saveIndex(self):
        print 'save index'
        path = config.getpath('indexer', 'hits_path')
        cdef object fn
        fn = path + str(self.hitid) + '.hit'
        cdef char *fname =  fn
        cdef FILE *fp=<FILE *>fopen(fname,"wb")
        fwrite(self._list, sizeof(Hit), self.size, fp)
        fclose(fp)

#--------------------------------------------------
#   End of sorter.pyx
#--------------------------------------------------

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

#导入HitList 单个hit list 操作
#Cimport hitlist.pyx                 swin2/indexer/hitlist.pyx

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

        self.saveToText()
    
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


        
#--------------------------------------------------
#   End of hitlists.pyx
#--------------------------------------------------


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



#--------------------------------------------------
#   End of hitindexer.pyx
#--------------------------------------------------

