from HashIndex import CreateHashIndex

def createHashIndex()
    cdef long li[100]
    print '.. create list'
    for i in range(100):
        li[i] = i
    print 'create hashindex' 
    hi = CreateHashIndex(li[0], li[100])
    hi.initList(li, 100)
    hi.createHash()


