from libc.stdio cimport fopen,fclose,fwrite,FILE,fread
from libc.stdlib cimport malloc,free

Cimport HashIndex.pyx


import ConfigParser
config = ConfigParser.ConfigParser()
config.read("../swin2.ini")

cdef class InitThes:
    '''
    初始化词库
    '''
    #使用动态分配内存方式  
    #分配词库内存空间
    cdef char **word_list
    #一级hash 参考表 初始化
    cdef InitHashIndex hashIndex
    #词库长度 由 delloc 调用
    cdef long length
    #words
    cdef object words
    #路径管理
    cdef object path

    def __cinit__(self):
        '''
        传入词库地址
        初始化词库
        '''
        #路径管理
        self.hashIndex = InitHashIndex()

        cdef:
            long i
            long l

        ph = config.get("parser", "thes_path")

        f=open(ph)
        self.words=f.read().split()
        f.close()

        #词的数量 
        self.length=len(self.words)
        #print 'the length of the wordbar is',self.length
        #开始分配词库内存空间
        cdef char  **li=<char **>malloc( sizeof(char *) * (self.length + 100) )

        print '初始化词库 分配了',sizeof(li)/sizeof(char *),'块内存'

        if li!=NULL:
            print 'the li is successful'
            self.word_list=li

        else:
            print 'the word li is failed'

        #开始对每个词分配内存 
        #并且分配内存

        for i in range(self.length):
            self.word_list[i]=self.words[i]


    def __dealloc__(self):
        '''
        释放c内存空间
        '''
        print 'begin to delete all the C spaces'

        #cdef char* polong
        cdef long i=0

    cdef double v(self,data):
        '''
        将元素比较的属性取出
        '''
        return hash(data)

    def show(self):
        '''
        显示
        '''
        cdef:
            long i

        print 'the length is',self.length
        for i in range(self.length):
            print i,self.word_list[i]


    def find(self, data):
        '''
        具体查取值 
        若存在 返回位置 
        若不存在 返回   0
        '''
        #需要测试 
        #print 'want to find ',hash(data),data
        cdef:
            long l
            long fir
            long mid
            long end
            long pos
            HI cur  #范围

        dv = self.v(data)     #传入词的hash
        pos = self.hashIndex.pos( dv )
        #print '开始 pos',pos

        if pos!=-1 and pos<STEP:
            cur = self.hashIndex.hi[pos]
        else:
            print "the word is not in wordbar or pos wrong"
            return False

        #取得 hash 的一级推荐范围
        fir=cur.left
        end=cur.right
        mid=fir
        if dv > self.v(self.word_list[end]):
            return 0

        while fir<end:

            #print 'in wordbar while'
            #print 'dv',dv

            mid=(fir+ end)/2

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



