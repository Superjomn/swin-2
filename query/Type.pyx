Cimport ../indexer/Type.pyx         swin2/indexer/Type.pyx

cdef enum bool:
    false   =   0
    true    =   1

cdef struct QueryRes:
    uint    docID
    float  score
    bool    able     #0 1 判定此记录是否有效

cdef struct QueryResList:
    QueryRes    *_list
    uint        size
    uint        space
    
    
