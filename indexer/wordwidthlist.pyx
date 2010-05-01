from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
from libc.stdlib cimport malloc,free, realloc
import sys
sys.path.append('../')
from debug import *
from Config import Config
config = Config()

Cimport Type.pyx    swin2/indexer/Type.pyx

cdef class WordWidthList:
    '''
    在HitList内存中生成后执行
    记录每个wordID对应的hit宽度
    此处与HitList合作 记录HitList中每个wordID对应的width
    note:
        width为每个List[i]数组对应的宽度 
    '''
    cdef:
        int AddPer
        int InitSize

        long size
        long space
        WordWidth *_list


    def __cinit__(self):
        conheader('WordWidthList')
        self.InitSize = 1000
        self.AddPer = 100
        self.size = 0
        self.space = 0
        self.__initSpace()


    def __dealloc__(self):
        console('__dealloc__')
        print "delete C space"
        free(self._list)

    def __dealloc(self):
        '''
        日常的内存清扫
        '''
        if self.size > 0:
            print '清扫下内存'
            free(self._list)
            self.size = 0
            self.space = 0
            print '重新 init'
            self.__initSpace()



    cdef short transWidth(self, HitList hitlist, uint pos):
        '''
        运行主程序
        每次处理一个段 
        处理的hitlist必须已经根据wordid及docid进行排序
        range(left, right)
        '''
        cdef: 
            long i, j
            long wordID
            long left
            WordWidth wordwidth
            WordWidth *curwidth
            unsigned int docID
            unsigned int docnum
            Hit *_hits

            
        self.__dealloc()
        console('transWidth')
        
        _size = hitlist.size
        _hits = hitlist._list
            
        print '.. _size', _size
        wordID = _hits[0].wordID
        left = 0

        for i in range(_size):
            '''
            对于每一个 List
            '''
            if _hits[i].wordID != wordID:
                wordwidth.left =  left
                wordwidth.right = i
                left = i
                wordwidth.pos = pos
                self.append(wordwidth)
                wordID = _hits[i].wordID

        #the last one
        wordwidth.left = left
        wordwidth.right = _size
        self.append(wordwidth)
        
        #生成docnum
        curwidth = self._list+0
        for i in range(self.size):
            curwidth = self._list + i
            docID = _hits[ curwidth.left ].docID
            docnum = 1
            curwidth.docnum = docnum

            for j in range(curwidth.left, curwidth.right):
                if docID != _hits[j].docID:
                    docnum += 1
                    docID = _hits[j].docID
                    curwidth.docnum = docnum
        #the last one
       

    cdef void __save(self):
        console('__save')
        print 'begin to save doclist'
        #save num
        path = config.getpath('indexer', 'word_width_num_path')
        f = open(path, 'w')
        f.write(str(self.size))
        f.close()
        #save data
        path = config.getpath('indexer', 'word_width_path')
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"wb")
        fwrite( self._list, sizeof(WordWidth), self.size, fp)
        fclose(fp)

        self.__saveToText()

    cdef void saveToText(self):
        print '-'*5000
        path = config.getpath('indexer', 'word_width_path')
        path += '.txt'
        res = ""

        for i in range(self.size):
            res += str(self._list[i].left) + ' '
            res += str(self._list[i].right) + ' '
            res += str(self._list[i].docnum) + ' '
            res += str(self._list[i].pos) + ' '
            res += "\n"

        f = open(path, 'w')
        f.write(res)
        f.close()
            
        


    cdef __initSpace(self):
        console('__initSpace')
        print '.. init space'
        self._list = <WordWidth *>malloc(sizeof(WordWidth) * self.InitSize)
        self.space = self.InitSize


    cdef WordWidth *getList(self):
        console('getList')
        return self._list


    cdef long getSize(self):
        return self.size


    cdef short __addSpace(self):
        '''
        if need to add space
        add space
        '''
        console('__addSpace')
        self.space += self.AddPer
        cdef WordWidth *base 
        base = <WordWidth *>realloc(self._list, sizeof(WordWidth)*self.space) 
        if not base:
            return False
        self._list = base
        return True


    cdef append(self, WordWidth li):
        self.size += 1
        if self.size == self.space:
            self.__addSpace()
        self._list[self.size - 1] = li



    cdef WordWidth get(self, long i):
        console('get')
        return self._list[i]



cdef class InitWordWidthList:
    '''
    从文件中恢复wordwidthlist
    '''
    cdef:
        long size
        WordWidth *_list

    def __cinit__(self):
        self.initSize()
        self.initList()
    
    def __dealloc__(self):
        print 'delete all C space'
        free(self._list)

    cdef get(self, long wordID):
        '''
        取得wordID对应的hits记录范围及位置
        '''
        return self._list[wordID]
        

    cdef initSize(self):
        cdef object path
        path = config.getpath('indexer', 'word_width_num_path')
        f = open(path)
        c = f.read()
        f.close()
        self.size = int(c)
        

    cdef initList(self):
        path = config.getpath('indexer', 'word_width_path')
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"rb")
        fread(self._list, sizeof(WordWidth), self.size ,fp)
        fclose(fp)
        
