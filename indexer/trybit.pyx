from libc.stdlib cimport malloc,free

cdef struct Per:
    int age
    int num

cdef struct Per2:
    int name

cdef class Apple:
    cdef Per per
    cdef init(self):
        self.per.age = 22

    cdef show(self):
        print 'self.per', self.per.age


cdef class Bear(Apple):
    cdef Per2 per

    cdef init(self):
        self.per.name = 233

    cdef show(self):
        print 'self.name', self.per.name


