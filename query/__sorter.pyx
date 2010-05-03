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

   
#--------------------------------------------------
#   End of ../indexer/Type.pyx
#--------------------------------------------------


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
    
    
#--------------------------------------------------
#   End of Type.pyx
#--------------------------------------------------


cdef class QueryResSorter:
    '''
    排序主算法	
    '''
    cdef QueryRes *dali
    cdef long length

    cdef void init(self,QueryRes *data, long length):
        '''
        init 
        '''
        self.dali = data
        self.length = length


    cdef double gvalue(self, QueryRes  data):
        '''
		返回需要进行比较的值
        '''
        return data.score


    cdef void quicksort(self,long p,int q):
        cdef long j
        a=self.dali
        st=[]

        while True:
            while p<q:
                j=self.partition(p,q)

                if (j-p)<(q-j):
                    st.append(j+1)
                    st.append(q)
                    q=j-1

                else:
                    st.append(p)
                    st.append(j-1)
                    p=j+1

            if(len(st)==0):
                return

            q=st.pop()
            p=st.pop()


    cdef long partition(self,int low,int high):
        cdef QueryRes  v
        v=self.dali[low]

        while low<high:

            while low<high and self.gvalue( self.dali[high] ) >= self.gvalue( v ):
                high-=1
            self.dali[low]=self.dali[high]

            while low<high and self.gvalue( self.dali[low] )<=self.gvalue( v ):
                low+=1
            self.dali[high]=self.dali[low]

        self.dali[low]=v

        return low

#--------------------------------------------------
#   End of sorter.pyx
#--------------------------------------------------

