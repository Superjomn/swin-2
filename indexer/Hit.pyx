Cimport Type.pyx    swin2/indexer/Type.pyx


cdef class HitCtrl:
    '''
    负责Hit的基础控制
    赋值及取值
    '''
    cdef:
        Hit *_list
        Hit cur

    cdef void init(self, Hit *_list):
        self._list = _list

    cdef void setCurIndex(self, long i):
        self.__initbit()
        self.cur = self._list + i

    cdef Hit getIndex(self):
        '''
        get a hit 
        '''
        return self.cur

    cdef void __initbit(self):
        '''
        初始对score清0
        '''
        #self._list[ self.cur ].score &= 0
        self.cur.score &= 0
        
    cdef void setFormat(self, Format f):
        '''
        set ith hit to right format
        '''
        #self._list[ self.cur ].score |= f
        self.cur.score |= f

    cdef void setLevel(self, Level l):
        #self._list[ self.cur].score |= l
        self.cur.score |= l

    cdef void setWordID(self, int wordID):
        #self._list[ self.cur].wordID = wordID
        self.cur.wordID = wordID

    cdef void setDocID(self, int docID):
        self.cur.docID = docID


    cdef int getFormat(self):
        '''
        返回 format 的数值
        如 1,2,3个等级
        '''
        cdef unsigned char _format
        _format = 192   #11 00 0000
        _format &= self.cur.score

        if _format == TOP:
            return 3
        elif _format == MID:
            return 2
        elif _format == LOW:
            return 1

    
    cdef int getLevel(self):
        '''
        返回 level 的数值
        如 1,2,3个等级
        '''
        cdef unsigned char _level
        _level = 48     #00 11 0000
        _level &= self.cur.score

        if _level == ONE:
            return 1
        elif _level == TWO:
            return 2
        elif _level == THREE:
            return 3
        elif _level == FOUR:
            return 4

    cdef int getWordID(self):
        return self.cur.wordID

    cdef int getDocID(self):
        return self.cur.docID
        
        
