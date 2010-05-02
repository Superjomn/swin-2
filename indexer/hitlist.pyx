import sys
sys.path.append('../')
from Config import Config
config = Config()

from libc.stdlib cimport malloc,free,realloc
from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread

#导入类型
Cimport Type.pyx    swin2/indexer/Type.pyx

cdef class Hitlist:
    '''
    单个范围内的Hits管理
    '''
    cdef:
        int AddPer
        int InitSize

        long size
        long space
        Hit *_list


    def __cinit__(self):
        self.InitSize = 1000
        self.AddPer = 100
        self.size = 0
        self.space = 0
        self.__initSpace()

    cdef Hit get(self, unsigned long i):
        return self._list[i]

    cdef Hit *getList(self):
        return self._list

    cdef long getSize(self):
        return self.size

    cdef append(self, Hit li):
        self.size += 1
        if self.size == self.space:
            self.__addSpace()
        self._list[self.size - 1] = li

    cdef save(self, path):
        cdef:
            object ph
            char *fname
        ph = path
        fname = ph
        fp = <FILE *>fopen(fname,"wb")
        fwrite( self._list , sizeof(Hit), self.size, fp)
        fclose(fp)



    def __dealloc__(self):
        print "delete C space"
        free(self._list)

    cdef short __addSpace(self):
        '''
        if need to add space
        add space
        '''
        self.space += self.AddPer
        cdef Hit *base 
        base = <Hit *>realloc(self._list, sizeof(Hit)*self.space) 
        if not base:
            return False
        self._list = base
        return True

    cdef __initSpace(self):
        print '.. init space'
        self._list = <Hit *>malloc(sizeof(Hit) * self.InitSize)
        self.space = self.InitSize





cdef class InitHitlist:
    '''
    初始化 HitList
    每次仅仅初始化一个hitlist
    '''
    cdef: 
        unsigned int pos
        unsigned long size
        Hit *_list

    def __cinit__(self):
        pass

    cdef void init(self, unsigned int pos):
        self.__setPos(pos)
        self.__initSize()
        self.__initSpace()
        self.__initList()

    cdef Hit get(self, i):
        return self._list[i]
        
    
    def __dealloc__(self):
        print 'delete all C space'
        free(self._list)
    
    cdef void __dealloc(self):
        if self.size > 0:
            print 'delete all C space'
            free(self._list)

    cdef void __setPos(self, unsigned int pos):
        self.pos = pos
        self.__dealloc()


    cdef void __initList(self):
        path = str(self.pos)+'.hit'
        path = config.getpath('indexer', 'hits_path') + path
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"rb")
        fread(self._list, sizeof(Hit), self.size ,fp)
        fclose(fp)
    

    cdef void __initSize(self):
        path = config.getpath('indexer', 'hits_num_path')
        f = open(path)
        c = f.read()
        f.close()
        _split = c.split()
        self.size = int(_split[self.pos])
        print 'self.size', self.size
        
    cdef void __initSpace(self):
        self._list = <Hit *>malloc(sizeof(Hit)*self.size)
        
