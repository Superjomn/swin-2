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
from ICTCLAS50.Ictclas import Ictclas

Cimport HashIndex.pyx swin2/_parser/HashIndex.pyx
Cimport ../reptile/datalist/List.pyx swin/reptile/datalist/List.pyx


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
            print '-'*50 
            #print _content
            print self.ict.split('try:中国农业大学')
            _splitedContent = self.ict.split(str(_content))
            print _splitedContent
            print '-'*50 

            for word in _splitedContent.split() :
                self.__list.find( word )

            if i > 5:
                print '.. larger than 5 return'
                return
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
        right = self.__list._list[_size]

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


