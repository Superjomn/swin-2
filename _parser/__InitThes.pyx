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
    long left    #左侧范围
    long right   #右侧范围

cdef class CreateHashIndex:
    '''
    建立一级hash参考表
    使用较复杂的中分法 单独作为一类
    传入 划分数目：  step
    结果将会把完整hash划分为step步
    '''
    cdef: 
        long* wlist
        long size
        double left     #左侧最小hash
        double right    #右侧最大hash
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
        print '.. step', self.step

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
            double minidx
        
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
        

    cdef double v(self, double data):
        '''
        将元素比较的属性取出
        '''
        return data

    def show(self):
        
        for i in range(self.size):
            print self.wlist[i]

    cdef int find(self,double data):

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

    def pos(self, double hashvalue):
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
#   End of HashIndex.pyx
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
        若不存在 返回   0
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
            HI cur  #范围


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

            elif  dv < self.__list[mid] :
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
#   End of InitThes.pyx
#--------------------------------------------------

