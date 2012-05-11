import sys
sys.path.append('../')
from Config import Config
config = Config()

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
#   End of ../indexer/Type.pyx
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
    uint    score
    bool    able     #0 1 判定此记录是否有效

cdef struct QueryResList:
    QueryRes    *_list
    uint        size
    uint        space
    
    
#--------------------------------------------------
#   End of ../indexer/../query/Type.pyx
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
#   End of ../indexer/idxlist.pyx
#--------------------------------------------------


cdef class QueryResSorter:
    '''
    排序主算法	
    '''
    cdef QueryRes *dali
    cdef long length

    cdef void init(self,QueryRes *data, long length):
        '''
        init 
        '''
        self.dali = data
        self.length = length


    cdef uint gvalue(self, QueryRes  data):
        '''
		返回需要进行比较的值
        '''
        return data.score


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
        cdef QueryRes  v
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

#--------------------------------------------------
#   End of sorter.pyx
#--------------------------------------------------


from _parser.ICTCLAS50.Ictclas import Ictclas

cdef class ResList:
    '''
    查询结果列表的方法
    包括 docID list 的组织及排序和最终生成
    '''
    cdef:
        int AddPer
        int InitSize

        long size
        long space
        int step    #测试用
        QueryRes *_list
        QueryResSorter sorter
        #现在的轮数 以区分不同的批次
        uint curStep

    def __cinit__(self):
        self.InitSize = 1000
        self.AddPer = 100
        self.size = 0
        self.space = 0
        self.step = 0
        self.__initSpace()
        
        self.sorter = QueryResSorter()

    cdef void sort(self):
        self.sorter.init(self._list, self.size)
        self.sorter.quicksort(0, self.size-1)

    def getRes(self):
        cdef:
            uint i
            object res
        
        '''
        #print 'res:'
        for i in range(self.size):
            print self._list[i].docID, self._list[i].score, self._list[i].able
        '''
        res = []
        for i in range(self.size):
            #print self._list[i].docID
            if self._list[i].able:
                res.append( self._list[i].docID )

        return res



    cdef append(self, QueryResList reslist, uint step):
        self.saveToText(reslist, step)
        if step == 0:
            self.appendInitList(reslist)

        else:
            self.stepAppend(reslist)
        self.saveListToText()
        #print 'step append, self.size', self.size

    cdef void saveToText(self, QueryResList reslist, uint step):
        path = '/home/chunwei/swin2/data/query'+str(step)+'.txt'
        res = ''
        for i in range(reslist.size):
            res += str(reslist._list[i].docID) + ' '
            res += str(reslist._list[i].score) + ' '
            res += str(reslist._list[i].able) + ' '
            res += "\n"

        f = open(path, 'w')
        f.write(res)
        f.close()

    cdef saveListToText(self):
        path = '/home/chunwei/swin2/data/idxlist'+str(self.step)+'.txt'
        self.step += 1
        res = ''
        for i in range(self.size):
            if self._list[i].able:
                res += str(self._list[i].docID) + ' '
                res += str(self._list[i].score) + ' '
                res += "\n"

        f = open(path, 'w')
        f.write(res)
        f.close()
        



    cdef inline void stepAppend(self, QueryResList reslist):
        '''
        每次调用为新的一轮
        新一轮会在原有基础上进行叠加
        '''
        cdef:
            QueryRes *res       #reslist cur
            QueryRes *cur       #self._list cur
            QueryRes *listend
            QueryRes *lasthited
            uint i

        #新的一轮开始
        cur = self._list
        #self._list last item
        listend = self._list + self.size-1
        #print 'listend', listend.docID
        #print 'reslist size:', self.size
        lasthited = listend
        for i in range(reslist.size):
            '''
            对于每一个i都需要进行处理
            对于命中的res需要合并
            对于未命中的 将其有效值减去
            只会对 hitlist <= cur的情况
            '''
            res = reslist._list + i

            #print 'cur:', res.docID, res.score, res.able
            #print 'end cur, begin to while'
            while cur.docID < res.docID :
                if lasthited == cur:
                    pass
                else:
                    cur.able = false

                cur += 1
                if cur>listend:
                    break

            if cur.docID == res.docID :
                if cur.able:
                    cur.score += res.score
                    lasthited = cur

        #print '.. self.size',self.size
        #print '.. begin to listend'
        #print '.. listend:', listend.docID, listend.score, listend.able

        cur = lasthited + 1
        #print 'cur 0:', cur.docID, cur.score, cur.able
        #print 'begin cur<=listend'
        #print 'listend id:',int(listend - self._list)
        while cur <= listend:
            cur.able = false
            cur += 1

        #print 'end stepAppend'
        #清空内存
        self.__freeResList( reslist )


    cdef appendInitList(self, QueryResList reslist):
        '''
        最初初始化的一轮
        需要对重复的进行处理!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        '''
        cdef:
            uint i 
            QueryRes tem

        tem = reslist._list[0]
        tem.score = 0

        self.__dealloc()
        self.__initSpace()

        for i in range(reslist.size):
            '''
            对每个记录进行处理
            '''
            if reslist._list[i].docID == tem.docID:
                tem.score += reslist._list[i].score
            else:
                self.__append(tem)
                tem = reslist._list[i]
        #清空reslist参数 内存
        if self._list[self.size-1].docID != tem.docID:
            self.__append(tem)
        
        #print '.. +++ show initappend +++'
        '''
        for i in range(self.size):
            print ' docID, score', self._list[i].docID, self._list[i].score
        '''


        self.__freeResList(reslist)

    cdef inline void __append(self, QueryRes res):
        self.size += 1
        if self.size == self.space:
            self.__addSpace()
        self._list[self.size - 1] = res
        


    cdef __freeResList(self, QueryResList reslist):
        '''
        清空 QueryRes *list 的内存
        '''
        print 'delete reslist space'
        if reslist.size > 0:
            free(reslist._list)



    cdef short __addSpace(self):
        '''
        if need to add space
        add space
        '''
        self.space += self.AddPer
        cdef QueryRes *base 
        base = <QueryRes *>realloc(self._list, sizeof(QueryRes)*self.space) 
        if not base:
            return False
        self._list = base
        return True

    cdef __initSpace(self):
        print '.. reslist init space'
        self._list = <QueryRes *>malloc(sizeof(QueryRes) * self.InitSize)
        self.space = self.InitSize
        self.size = 0


    def __dealloc__(self):
        print 'delete all C space'
        free(self._list)

    def __dealloc(self):
        print 'delete reslist C space'
        if self.space > 0:
            free(self._list)
            self.size = 0
            self.space = 0








cdef class Query:
    '''
    查询主程序
    输入查询语句 输出docIDs
    '''
    cdef:
        object      ict
        InitThes    thes
        ResList     reslist
        InitIdxList idxlist
        object      words

    def __cinit__(self):
        self.ict = Ictclas( config.getpath('parser', 'ict_configure_path') )
        self.thes = InitThes()
        self.reslist = ResList()
        self.idxlist = InitIdxList()
        self.words = None

    def query(self, strr):
        '''
        strr: 查询语句
        '''
        cdef:
            uint pos
            long wordID
            QueryResList _reslist
            ushort step

        #分配空间
        _reslit = <QueryResList *>malloc(sizeof(QueryResList))

        self.words = self.ict.split(str(strr)).split()
        wordhashs = [hash(word) for word in self.words]
        wordgroups = self.__splitGroup(wordhashs)
        #将词通过pos分组
        #self.__splitGroup(words)
        #开始逐组查询
        step = 0
        for group in wordgroups:
            '''
            wordgroups:
                [
                    [pos, [wordID, ..]],
                ]
            '''
            self.idxlist.init( group[0] )

            for wordID in group[1]:
                _reslist = self.idxlist.find(wordID)
                self.reslist.append(_reslist, step)
                step += 1
            
        #对结果根据score进行排序
        self.reslist.sort()
        #返回查询结果!!!!!!!!!!!!!!!!!!
        #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!后续结果
        return self.reslist.getRes()

        

    cdef inline object __splitGroup(self, object wordhashs):
        '''
        将词汇进行分组
        每组有同一pos
        '''
        cdef:
            uint i
            object res

        poses = [ [self.thes.pos(wordhash), self.thes.findByHash(wordhash)] for wordhash in wordhashs]
        poses.sort()
        res = []

        for pos in poses:
            if not res:
                res.append([ pos[0], [pos[1]] ])
            elif pos[0] == res[-1][0]:
                res[-1][1].append(pos[1])
            else:
                res.append([ pos[0], [pos[1]] ])
        return res

            

        


#--------------------------------------------------
#   End of query.pyx
#--------------------------------------------------

