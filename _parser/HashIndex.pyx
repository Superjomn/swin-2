from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
import os
import sys
sys.path.append('../')
from Config import Config
config = Config()

DEF STEP = 20

cdef struct HI: 
    int left    #左侧范围
    int right   #右侧范围

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
        long left     #左侧最小hash
        long right    #右侧最大hash
        long step


    def __cinit__(self, left, right):
        '''
        init
        li : 词库list '''
        self.left = left
        self.right = right
        self.step=long( (self.right-self.left)/STEP )

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
        
        minidx = self.left

        for i in range(STEP):
            #寻找边界
            minidx += self.step*i
            hashIndex[i].left = cur_step+1
            hashIndex[i].right = self.find(minidx)

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

    cdef int find(self, double data):
        '''
        具体查取值 
        若存在 返回位置 
        若不存在 返回   0
        '''
        #需要测试 
        #print 'want to find ',hash(data),data
        cdef:
            int l
            int fir
            int mid
            int end

        l=self.size
        dv=self.v(data)     #传入词的hash

        #取得 hash 的一级推荐范围
        #此处可以进一步推进fir范围 暂时没有必要
        fir=0
        end=l-1
        mid=0

        if l == 0:
            return 0#空

        while fir<end:

            mid=(fir+ end)/2

            if ( dv > self.v(self.wlist[mid]) ):
                fir = mid + 1

            elif  dv < self.v(self.wlist[mid]) :
                end = mid - 1

            else:
                break

        if fir == end:

            if self.v(self.wlist[fir]) > dv:
                #假定 在此hash值内
                return fir-1 

            elif self.v(self.wlist[fir]) < dv:
                #此处不确定??????
                return fir

            else:
                #print 'return fir,mid,end',fir,mid,end
                return end#需要测试
                
        elif fir>end:
            #此情况为何种情况????????
            return 0

        else:
            #print '1return fir,mid,end',fir,mid,end
            return mid#需要测试





cdef class InitHashIndex:
    '''
    init he hash index
    '''
    #define the hash index 
    cdef HI hi[STEP]

    def __cinit__(self):
        '''
        init
        '''
        cdef object path = config.get("parser", "hash_index_path")
        cdef char *ph = path
        cdef FILE *fp = <FILE *>fopen(ph, "rb")
        fread(self.hi, sizeof(HI), STEP, fp)
        fclose(fp)

    def pos(self,double hashvalue):
        '''
        pos the word by hashvalue 
        if the word is beyond hash return -1
        else return the pos
        '''
        cdef int cur=-1
        
        if hashvalue>self.hi[0].left:
            cur+=1
        else:
            return cur

        while hashvalue > self.hi[cur].left:
            cur+=1

        return cur


