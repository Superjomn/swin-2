cdef class Hit_lists:
    '''
    hit存储队列
    每个list对应于一个存储文件
    '''
    cdef:
        long length
        long top
        List hit_list[List_num]
        object ict
        #路径管理
        object path

    def __cinit__(self, object path):
        '''
        初始化数据空间
        '''
        print '>begin init List space'
        self.path = path
        self.ict = Ictclas('ICTCLAS50/')

        cdef:
            long i

        #初始化每个list节点
        for i in range(List_num):
            self.hit_list[i].start = <Hit *>malloc( sizeof(Hit) * List_init_size )
            self.hit_list[i].length=List_init_size
            self.hit_list[i].top=-1
            self.hit_list[i].size=0

            if self.hit_list[i].start!= NULL:
                print '>>init list ok!'

    cdef __delloc__(self):
        '''
        消去内存
        '''
        cdef long i
        print 'begin to delete the space'

        for i in range(List_num):
            free(self.hit_list[i].start)


    cdef void eq(self,long hit_id,int idx,int wordID,int docID,short score,int pos):
        '''
        赋值处理
        '''
        self.hit_list[hit_id].start[idx].wordID=wordID
        self.hit_list[hit_id].start[idx].docID=docID
        self.hit_list[hit_id].start[idx].score=score
        self.hit_list[hit_id].start[idx].pos=pos


    def ap(self, long hit_id ,int wordID ,int docID ,short score ,int pos):

        '''
        向list中添加数据
        如果list溢出 则返回False
        添加成功 返回True
        '''
        #print 'begin append the word hit >>>>>'
        self.hit_list[hit_id].top += 1
        self.hit_list[hit_id].size += 1
        #print '+ hit.top+1'
        #print '+ begin eq'
        self.eq( hit_id, self.hit_list[hit_id].top ,wordID,docID,score,pos)
        #print '> succed eq'

        if (self.hit_list[hit_id].top > self.hit_list[hit_id].length-2):
            #如果 分配长度快到最大长度 则返回false
            #如果 lenth还有空间 继续分配空间
           return False
        else:
            #空间和其他都不缺少
            #正常情况
            return True

    cdef void empty(self, long hit_id):
        '''
        将List清空
        释放空间
        再重新分配基本空间
        '''
        print 'begin to free the list'
        print 'begin to relloc it'
        self.hit_list[hit_id].top=-1


