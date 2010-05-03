'''
Created on May 19, STEP11

@author: chunwei
'''
#需要添加进动态内存管理
#但似乎动态管理不可能--词库中char长度不一
#需要提前知道词库大小(可以保存到sqlite)
#本文件包含两个库 建立词库  及新建词库

# *******相关函数可以考虑写为   inline   提供必要接口

#hashIndex 结构

from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread

import sys
sys.path.append('../')
from Config import Config
config = Config()
import htmldb
from _parser.ICTCLAS50.Ictclas import Ictclas

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

from libc.stdlib cimport malloc,free,realloc

DEF ADD_PER = 100
DEF INIT_SPACE = 200

cdef class List:
    cdef: 
        long space
        long size
        long addPer
        long *_list

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
        self._list = <long *>malloc( sizeof(long) * (self.space) )

    cdef long* getListPos(self):
        return self._list
        
        
    cdef addSpace(self):
        self.space += ADD_PER
        self._list = <long *>realloc( self._list, sizeof(long) * (self.space) )

    cdef insert(self, long i, long v):
        if i < 0:
            return False

        self.size += 1
        if self.size == self.space:
            self.addSpace()
        #向后耨动
        cdef long a = self.size-1
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
            long l, first, end, mid, hv

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
            long i

        res = []
        for i in range(self.size):
            res.append(self._list[i])
        return res


#--------------------------------------------------
#   End of ../reptile/datalist/List.pyx
#--------------------------------------------------



cdef class CreateThes:
    '''
    新建词库
    '''
    #此处字符串传入方式需要确定
    cdef:
        List __list
        object htmldb
        object htmlnum
        object ict

    def __cinit__(self):
        self.__list = List()
        self.htmldb = htmldb.HtmlDB()
        self.htmlnum = self.htmldb.getHtmlNum()
        self.ict = Ictclas( config.getpath('parser', 'ict_configure_path') )

    def run(self):
        '''
        此处直接将词转化为相应的hash值
        词库即为hash值
        '''
        for i in range(self.htmlnum):
            _content = self.htmldb.getContentByIndex(i)
            _splitedContent = self.ict.split(str(_content))
            f = open('../data/bug_words.txt', 'a')
            f.write(_splitedContent)
            f.close()

            for word in _splitedContent.split():
                self.__list.find( word )

        print '词库分词完毕'

        
    def save(self):
        '''
        将hash值存储为二进制文件
        '''
        print 'begin to save'
        print 'thes size', self.__list.size
        self.__createHashIndex()
        #save thes size
        path = config.getpath('parser', 'thes_size_path')
        f = open(path, 'w')
        f.write( str(self.__list.size) )
        f.close()
        #save list
        path = config.getpath('parser', 'thes_path')
        cdef char *ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"wb")
        fwrite( self.__list.getListPos(), sizeof(long), self.__list.size, fp)
        fclose(fp)


    cdef __createHashIndex(self):
        '''
        生成一级索引哈系表
        需要通过动态分配内存的方式？
        '''
        print 'begin create_hash'
        #分为STEP个hashindex表
        cdef long left, right
        _size = self.__list.getSize()
        left = self.__list._list[0]
        right = self.__list._list[_size-1]
        print '-'*50
        print 'left : right',left, right
        print '-'*50

        cdef CreateHashIndex cHashIdx = CreateHashIndex(left, right)
        _list = self.__list.getListPos()
        cHashIdx.initList(_list, _size)
        cHashIdx.createHash()


    cdef find(self, long word):
        '''
        在list中查找word
        如果查找到 返回True
        如果没有找到 返回False
        '''
        print 'begin find()'

        #定义变量
        cdef:
            long l       #长度 
            long first
            long end
            long mid
            long num

        #初始值
        l=len(self.li)
        first=0
        end=l-1
        mid=0
        num=hash(word)

        if l==0:
            print 'the list is empty'
            self.li.insert(0,word)
            return False
        
        while first<end:
            mid=(first+end)/2

            if num>hash(self.li[mid]):
                first=mid+1

            elif num<hash(self.li[mid]):
                end=mid-1

            else:
               first=mid
               end=mid

               while hash(self.li[first])==num and first>=0:
                   
                    if self.li[first]==word:
                        return True
                    first-=1

               while hash(self.li[end])==num and end<l:
                   
                    if self.li[end]==word:
                        return True 
                    end=end+1

               self.li.insert(mid+1,word)

               return False
            
        if first==end:
            if hash(self.li[first])>num:
                self.li.insert(first,word)
                return False

            elif hash(self.li[first])<num:
                self.li.insert(first+1,word)
                return False

            else:
                
                if self.li[first]==word:
                    return True

                else:
                    self.li.insert(first+1,word)
                    return False

        elif first>end:
            self.li.insert(first,word)
            return False

        else:
            return True

    def show(self):
        '''
        展示词库
        '''
        for i in self.li:
            print i


#--------------------------------------------------
#   End of Thes.pyx
#--------------------------------------------------

