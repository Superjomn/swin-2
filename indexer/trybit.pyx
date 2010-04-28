from libc.stdlib cimport malloc,free

cdef struct List:
    int a
    int b


cdef List list[10]

#init
for i in range(10):
    list[i].a = 0
    list[i].b = 0

cdef List *cur 
cur = list+5
cur.a = 1

for i in range(10):
    print i, list[i].a, list[i].b

cdef class Apple:
    cdef:
        int *a
    def __cinit__(self):
        print 'init'
        self.a = <int *>malloc(sizeof(int)*5)

    def __del__(self):
        print 'del'
        free(self.a)

    def __delloc__(self):
        print 'delloc'
        free(self.a)

    def __dealloc__(self):
        print 'dealloc'
        free(self.a)

apples = []
for i in range(20):
    a = Apple()
    apples.append(a)

