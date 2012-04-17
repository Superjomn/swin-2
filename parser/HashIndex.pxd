from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
DEF STEP = 20

cdef struct HI: 
    int left    #左侧范围
    int right   #右侧范围

cdef class CreateHashIndex:
    cdef: 
        object wlist
        double left     #左侧最小hash
        double right    #右侧最大hash
        long step

    cdef saveHash(self, char *ph, HI *hi)

    cdef double v(self,double data)

    cdef int find(self, double data)



cdef class InitHashIndex:
    cdef HI hi[STEP]
