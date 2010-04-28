import math
from datetime import date

cdef class ScoreCal:
    '''
    具体计算每个hit的score值 
    并且合成最终hit的score值
    此模块生成最终的倒排索引
    '''
    #页面数量
    cdef long pagenum
    cdef long 

    def __cinit__(self):
        self.pagenum = 0

    cdef float getLevel(self, int l):
        '''
        计算level值
        '''
        return 1 + 1/(2 * math.log(math.e, l))

    cdef float getTW(self):
        '''
        计算时间值
        '''
        return 1 + 1/(2* math.log(math.e, days))

    cdef int getWordCount(self, int docID):
        '''
        计算相应网页的词汇数量
        '''
        pass

    def 
        

    cdef float calScore(self,





        

    

