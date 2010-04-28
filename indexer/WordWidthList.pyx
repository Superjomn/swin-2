Cimport Type.pyx    swin2/indexer/Type.pyx

class WordWidthList:

    cdef:
        int AddPer
        int InitSize

        long size
        long space
        WordWidth *_list


    def __cinit__(self):
        self.InitSize = 1000
        self.AddPer = 100
        self.size = 0
        self.space = 0
        self._list = None
        self.initSpace()

    def __dealloc__(self):
        print "delete C space"
        free(self._list)

    cdef initSpace(self):
        print '.. init space'
        self._list = <WordWidth *>malloc(sizeof(WordWidth) * self.InitSize)
        self.space = self.InitSize

    cdef WordWidth *getList(self):
        return self._list

    cdef long getSize(self):
        return self.size

    cdef bool addSpace(self):
        '''
        if need to add space
        add space
        '''
        self.space += self.AddPer
        WordWidth *base = <WordWidth *>realloc(self._list, sizeof(WordWidth)*self.space) 
        if not base:
            return False
        self._list = base
        return True

    cdef append(self, WordWidth li):
        self.size += 1
        if self.size == self.space:
            self.addSpace()
        self._list[self.size - 1] = li

    cdef WordWidth get(self, long i):
        return self._list[i]


