ctypedef unsigned int   uint
ctypedef unsigned long  ulong
ctypedef unsigned short ushort

ctypedef unsigned int   docid
ctypedef unsigned long  wordid

cdef struct Hit:
    uint wordID
    uint docID
    ushort format

#记录单个wordid对应的笨pos内的范围
cdef struct WordWidth:
    long left   #左范围
    long right  #右范围
    #本wordID命中的不重复的文档数目
    uint docnum
    int pos     #记录数组号
 
#倒排索引
cdef struct Idx:
    uint  wordID
    uint    docID
    float score

#单个hitlist字段
cdef struct HitList:
    Hit *_list
    ulong size
    ulong space

   
