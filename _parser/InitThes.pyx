from libc.stdio cimport fopen,fclose,fwrite,FILE,fread
from libc.stdlib cimport malloc,free

import sys
sys.path.append('../')
from Config import Config
config = Config()

Cimport HashIndex.pyx swin2/_parser/HashIndex.pyx

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
        

    def find(self, v):
        '''
        通过hashvalue查找wordID
        若存在 返回位置 
        若不存在 返回   0
        '''
        cdef:
            long l
            long fir
            long mid
            long end
            long pos
            HI cur  #范围

        #print '初始化数据ok'
        cdef long dv = hash(v)

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


