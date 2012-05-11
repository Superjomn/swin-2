from libc.stdlib cimport malloc,free,realloc

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
    float score

#单个hitlist字段
cdef struct HitList:
    Hit *_list
    ulong size
    ulong space

   
#--------------------------------------------------
#   End of ../indexer/Type.pyx
#--------------------------------------------------


DEF ADD_PER = 100
DEF INIT_SPACE = 200

cdef class List:
    cdef:
        llong space
        long size
        long addPer
        llong *_list

    def __cinit__(self):
        '''
        init
        '''
        self.size = 0
        self.initSpace()

    def __delloc__(self):
        print 'del all C space'
        free(self._list)

    def __del__(self):
        print 'del all C space'
        free(self._list)

    cdef void initSpace(self):
        self.space = INIT_SPACE
        self._list = <llong *>malloc( sizeof(long) * (self.space) )

    cdef llong* getListPos(self):
        return self._list
        
        
    cdef addSpace(self):
        self.space += ADD_PER
        self._list = <llong *>realloc( self._list, sizeof(long) * (self.space) )

    cdef insert(self, llong i, long v):
        if i < 0:
            return False

        self.size += 1
        if self.size == self.space:
            self.addSpace()
        #向后耨动
        cdef llong a = self.size-1
        while a >= i :
            self._list[a] = self._list[a-1]
            a -= 1
        self._list[i] = v

    def find(self, url):
        '''
        用法：
        li.find('./index.php')
        '''
        cdef:
            llong l, first, end, mid, hv

        hv = hash(url)
        l = self.size
        first = 0
        end = l - 1
        mid = 0
        
        if l == 0:
            self.insert(0,hv)
            return False
        
        while first < end:
            mid = (first + end)/2
            if hv > self._list[mid]:
                first = mid + 1
            elif hv < self._list[mid]:
                end = mid - 1
            else:
                break
            
        if first == end:
            if self._list[first] > hv:
                self.insert(first, hv)
                return False
            
            elif self._list[first] < hv:
                self.insert(first + 1, hv)
                return False
            
            else:
                return True
                
        elif first > end:
            self.insert(first, hv)
            return False
        else:
            return True

    def getSize(self):
        return self.size

    def show(self):
        print '-'*50
        print 'list-'*10
        for i in range(self.size):
            url = self._list[i]
            print url

    def getAll(self):
        '''
取得所有信息 便于中断操作
'''
        cdef:
            llong i

        res = []
        for i in range(self.size):
            res.append(self._list[i])
        return res
#--------------------------------------------------
#   End of List.pyx
#--------------------------------------------------

