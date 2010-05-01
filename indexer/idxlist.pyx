import sys
from debug import *
sys.path.append('../')
from Config import Config
config = Config()

from libc.stdlib cimport malloc,free,realloc
from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread

Cimport Type.pyx            swin2/indexer/Type.pyx
Cimport ../query/Type.pyx   swin2/query/Type.pyx

cdef class IdxList:
    '''
    最终倒排索引的list管理
    '''
    cdef:
        Idx *_list
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

    def __dealloc__(self):
        console('__dealloc__')
        print 'delete all C space!'
        free(self._list)

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
        console('__initSpace')
        print '.. init space'
        self._list = <Idx *>malloc(sizeof(Idx) * self.InitSize)
        self.space = self.InitSize



cdef class InitIdxList:
    '''
    初始化单个idxlist
    '''
    cdef: 
        uint pos
        ulong size
        Idx *_list
        #scope
        uint left
        uint right
        ulong curWid

    def __cinit__(self):
        conheader('InitIdxList')
        pass

    cdef void init(self, unsigned int pos):
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

    
    cdef QueryResList find(self, wordID):
        '''
        查找 并返回 ResList结果
        '''
        console('find')
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
        reslist._list = <QueryRes *>malloc(sizeof(QueryRes)*size)
        reslist.size = size
        reslist.space = size
        

        #QueryResList index
        j=0
        for i in range(self.left, self.right+1):
            '''
            开始赋值 QueryResList._list
            '''
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
        self.left = 0 
        self.right = 0

        cdef:
            int fir
            int mid
            int end

        fir = 0
        mid = 0
        end = self.size - 1
        
        console('__posWidMid')

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

        console('__posWidScope')
        i = self.__posWidMid()

        while i>=0:
            if self._list[i].wordID == self.curWid:
                i -= 1
            else:
                break

        self.left = i+1
        
        while i <= self.size - 1:
            if self._list[i].wordID == self.curWid:
                i += 1
            else:
                break

        self.right = i-1


        
    
    def __dealloc__(self):
        print 'delete all C space'
        free(self._list)

    cdef void __dealloc(self):
        '''
        明确进行内存整理
        '''
        console('__dealloc')
        print 'delete C Idx list space!'
        if self._list:
            free(self._list)

    cdef void __setPos(self, unsigned int pos):
        console('__setPos')
        self.pos = pos


    cdef void __initList(self):
        console('__initList')
        path = str(self.pos)+'.idx'
        path = config.getpath('indexer', 'idxs_path') + path
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"rb")
        fread(self._list, sizeof(Idx), self.size ,fp)
        fclose(fp)
    

    cdef void __initSize(self):
        console('__initSize')
        path = config.getpath('indexer', 'idxs_num_path ')
        f = open(path)
        c = f.read()
        f.close()
        _split = c.split()
        self.size = int(_split[self.pos])
        
    cdef void __initSpace(self):
        console('__initSpace')
        self._list = <Idx *>malloc(sizeof(Idx)*self.size)
 
 


