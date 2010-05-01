Cimport wordwidthlist.pyx   swin2/indexer/wordwidthlist.pyx

#导入类型
Cimport Type.pyx    swin2/indexer/Type.pyx

cdef class Sorter:
    '''
    排序主算法	
    '''
    cdef Hit *dali
    cdef long length

    cdef void init(self, Hit *data, long length):
        '''
        init 
        '''
        self.dali = data
        self.length = length


    cdef double gvalue(self, Hit data):
        '''
		返回需要进行比较的值
        '''
        return data.wordID


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
        cdef Hit v
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

#------------------------ Sorter end --------------------------------------

cdef class WidSort(Sorter):
    '''
    根据 wid 进行排序
    不包括最后 根据 docid 进行排序
    '''
    #词库
    cdef object wordbar

    '''
    cdef void init1(self,Hit *data, long length):
        #初始化 父亲 Sorter
        Sorter.init(self, data,length)
    '''

    cdef double gvalue(self, Hit data):
        '''
        重载 Sorter 方法
		返回需要进行比较的值
        '''
        cdef long wid = data.wordID
        #返回 hit 对应 word 的 hashvalue
        return wid



cdef class DidSort(Sorter):
    '''
    根据 did 进行排序
    不包括 在 耽搁 did 文件中 根据 wid 进行排序
    '''
    '''
    cdef void init1(self,Hit *data,long length):
        #初始化 父亲 Sorter
        Sorter.init(self,data,length)
    '''
    cdef double gvalue(self,Hit data):
        '''
        返回排序字段
        '''
        return data.docID



   

cdef class HitSort:
    '''
    排序主程序
    单独为每一个pos内的index排序
    先依照wordID排序
    然后在相同wordID内进行docID的排序
    同时记录wordID的范围表
    '''
    cdef:
        Hit *_list
        int hitid
        long size #hitlist的长度
        #long width[List_num]
        WordWidthList widthlist
        WidSort widsort
        DidSort didsort

    def __cinit__(self):
        self.widthlist = WordWidthList()
        self.widsort = WidSort()
        self.didsort = DidSort()
    
    cdef init(self, int hitid,  Hit *list, long size):
        '''
        hitid:  hit 的文件编号
        需要传入一个pos内的index 然后进行处理
        index 为 一期索引
        '''
        self._list = list
        self.hitid = hitid
        self.size = size
        self.widsort.init(list, size)
        self.didsort.init(list, size)

    def run(self):
        '''
        运行主程序 一系列动作
        '''
        cdef HitList temhitlist
        self.wordidsort()
        #此处为临时产生width
        #trans type
        '''
        temhitlist.size = self.size
        temhitlist.space = self.space
        temhitlist._list = self._list
        '''
        self.transWordWidth()
        self.widthlist.saveToText()
        self.docidsort()

    cdef void wordidsort(self):
        '''
        先对wordID进行排序
        然后在同wordID内对docID进行排序
        '''
        print 'begin to sort wid'
        self.widsort.quicksort(0, self.size-1)


    cdef void  transWordWidth(self):
        '''
        扫描list 产生对于每个wordID的序列范围表
        '''
        cdef:
            WordWidth ww

        cdef long cur_wid = self._list[0].wordID

        ww.left = 0

        for i in range(self.size):
            if self._list[i].wordID != cur_wid:
                ww.right = i-1
                self.widthlist.append(ww)
                ww.left = i

        ww.right = self.size-1

        self.widthlist.append(ww)


    cdef void docidsort(self):
        '''
        在同一个wordID范围内进行docID的排序
        '''
        _size = self.widthlist.getSize()
        cdef long i
        cdef WordWidth width
        for i in range(_size):
            width = self.widthlist.get(i)
            self.didsort.quicksort(width.left, width.right)

    cdef void save(self):
        #self.__saveWidth()
        self.__saveIndex()
    
    '''
    cdef  void __saveWidth(self):
        print 'save word width'
        path = config.getpath('indexer', 'hits_path')
        cdef object fn
        fn = path + str(self.hitid) + '.width'
        cdef char *fname =  fn
        cdef FILE *fp=<FILE *>fopen(fname,"wb")
        fwrite(self.widthlist.getList(), sizeof(WordWidth), self.widthlist.getSize(), fp)
        fclose(fp)
    '''


    cdef void __saveIndex(self):
        print 'save index'
        path = config.getpath('indexer', 'hits_path')
        cdef object fn
        fn = path + str(self.hitid) + '.hit'
        cdef char *fname =  fn
        cdef FILE *fp=<FILE *>fopen(fname,"wb")
        fwrite(self._list, sizeof(Hit), self.size, fp)
        fclose(fp)

