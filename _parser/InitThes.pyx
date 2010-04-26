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
        self.hi = InitHashIndex()
        self.__initList()

    def __dealloc__(self):
        '''
        释放c内存空间
        '''
        print 'delete all C space'
        free(self.__list)
    
    
    cdef __initList(self):
        '''
        将二进制文件载入内存
        '''
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

    def find(self, dv):
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

        pos=self.hashIndex.pos( dv )

        #print '开始 pos',pos

        if pos!=-1 and pos<STEP:
            #print '开始>cur=self.hashIndex.hi[pos]',pos
            cur = self.hashIndex.hi[pos]
            #print 'cur< OK ',cur.left,cur.right

        else:
            print "the word is not in wordbar or pos wrong"
            return False

        #取得 hash 的一级推荐范围
        fir=cur.left
        end=cur.right
        mid=fir
        '''
        print 'hello world'
        print 'fir ,end',fir,end
        print 'the 1th word is',self.v(self.word_list[1])
        print '-'*50

        for i in range(self.length-1):
            print i,self.v(self.word_list[i])
        '''
        #print 'length',self.length

        #print 'trying ...',

        #print self.v(self.word_list[fir])

        #print 'the fir end gv',self.v(self.word_list[fir]),self.v(self.word_list[end]),dv

        if dv > self.v(self.word_list[end]):
            return 0

        #print '词库: fir,end,mid',fir,end,mid

        while fir<end:

            #print 'in wordbar while'
            #print 'dv',dv

            mid=(fir+ end)/2
            #print 'mid',mid
            '''
            print 'self.word_list[mid]'
            print self.word_list[mid]

            print 'dv self.v(self.word_list[mid])'
            print dv,self.v(self.word_list[mid])

            print '-'*50
            '''



            if ( dv > self.v(self.word_list[mid]) ):
                fir = mid + 1
                #print '1 if fir',fir

            elif  dv < self.v(self.word_list[mid]) :
                end = mid - 1
                #print '1 elif end',end

            else:
                break

        if fir == end:
            
            #print 'fir==end'

            if self.v(self.word_list[fir]) > dv:
                return 0 

            elif self.v(self.word_list[fir]) < dv:
                return 0

            else:
                #print 'return fir,mid,end',fir,mid,end
                #print '查得 wordid',end
                return end#需要测试
                
        elif fir>end:
            return 0

        else:
            #print '1return fir,mid,end',fir,mid,end
            #print '查得 wordid',mid
            return mid#需要测试


