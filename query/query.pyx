import sys
sys.path.append('../')
from Config import Config
config = Config()

Cimport ../indexer/Type.pyx         swin2/indexer/Type.pyx
Cimport ../_parser/InitThes.pyx     swin2/_parser/InitThes.pyx
Cimport ../indexer/idxlist.pyx      swin2/indexer/idxlist.pyx
Cimport Type.pyx                    swin2/query/Type.pyx
Cimport sorter.pyx                  swin2/query/sorter.pyx

from _parser.ICTCLAS50.Ictclas import Ictclas

cdef class ResList:
    '''
    查询结果列表的方法
    包括 docID list 的组织及排序和最终生成
    '''
    cdef:
        int AddPer
        int InitSize

        long size
        long space
        QueryRes *_list
        QueryResSorter sorter
        #现在的轮数 以区分不同的批次
        uint curStep

    def __cinit__(self):
        self.InitSize = 1000
        self.AddPer = 100
        self.size = 0
        self.space = 0
        self.__initSpace()
        
        self.sorter = QueryResSorter()

    cdef void sort(self):
        self.sorter.init(self._list, self.size)
        self.sorter.quicksort(0, self.size-1)

    def getRes(self):
        cdef:
            uint i
            object res

        res = []
        for i in range(self.size):
            print self._list[i].docID
            res.append( self._list[i].docID )

        return res



    cdef append(self, QueryResList reslist, uint step):
        if step == 0:
            self.appendInitList(reslist)

        else:
            self.stepAppend(reslist)


    cdef inline void stepAppend(self, QueryResList reslist):
        '''
        每次调用为新的一轮
        新一轮会在原有基础上进行叠加
        '''
        cdef:
            uint cur
            QueryRes *res
            uint i

        #新的一轮开始
        cur = 0
        for i in range(reslist.size):
            '''
            对于每一个i都需要进行处理
            对于命中的res需要合并
            对于未命中的 将其有效值减去
            '''
            res = reslist._list + i

            while reslist._list[cur].docID < res.docID :
                cur += 1

            if res.docID == reslist._list[cur].docID:
                reslist._list[cur].score += res.score
            else:
                #cur > res
                res.able = false
            
        print 'end stepAppend'
        #清空内存
        self.__freeResList( reslist )


    cdef appendInitList(self, QueryResList reslist):
        '''
        最初初始化的一轮
        需要对重复的进行处理!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        '''
        cdef:
            uint i 
        for i in range(reslist.size):
            '''
            对每个记录进行处理
            '''
            self.size += 1
            if self.size == self.space:
                self.__addSpace()
            self._list[self.size - 1] = reslist._list[i]
        #清空reslist参数 内存
        self.__freeResList(reslist)


    cdef __freeResList(self, QueryResList reslist):
        '''
        清空 QueryRes *list 的内存
        '''
        print 'delete reslist space'
        if reslist.size > 0:
            free(reslist._list)



    cdef short __addSpace(self):
        '''
        if need to add space
        add space
        '''
        self.space += self.AddPer
        cdef QueryRes *base 
        base = <QueryRes *>realloc(self._list, sizeof(QueryRes)*self.space) 
        if not base:
            return False
        self._list = base
        return True

    cdef __initSpace(self):
        print '.. reslist init space'
        self._list = <QueryRes *>malloc(sizeof(QueryRes) * self.InitSize)
        self.space = self.InitSize


    def __dealloc__(self):
        print 'delete all C space'
        free(self._list)




cdef class Query:
    '''
    查询主程序
    输入查询语句 输出docIDs
    '''
    cdef:
        object      ict
        InitThes    thes
        ResList     reslist
        InitIdxList idxlist

    def __cinit__(self):
        self.ict = Ictclas( config.getpath('parser', 'ict_configure_path') )
        self.thes = InitThes()
        self.reslist = ResList()
        self.idxlist = InitIdxList()

    def query(self, strr):
        '''
        strr: 查询语句
        '''
        cdef:
            uint pos
            long wordID
            QueryResList _reslist
            ushort step

        #分配空间
        _reslit = <QueryResList *>malloc(sizeof(QueryResList))

        words = self.ict.split(strr).split()
        wordhashs = [hash(word) for word in words]
        wordgroups = self.__splitGroup(wordhashs)
        #将词通过pos分组
        #self.__splitGroup(words)
        #开始逐组查询
        step = 0
        for group in wordgroups:
            '''
            wordgroups:
                [
                    [pos, [wordID, ..]],
                ]
            '''
            self.idxlist.init( group[0] )

            for wordID in group[1]:
                _reslist = self.idxlist.find(wordID)
                self.reslist.append(_reslist, step)
                step += 1
            
        #对结果根据score进行排序
        self.reslist.sort()
        #返回查询结果!!!!!!!!!!!!!!!!!!
        #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!后续结果
        return self.reslist.getRes()

        

    cdef inline object __splitGroup(self, object wordhashs):
        '''
        将词汇进行分组
        每组有同一pos
        '''
        cdef:
            uint i
            object res

        poses = [ [self.thes.pos(wordhash), self.thes.findByHash(wordhash)] for wordhash in wordhashs]
        poses.sort()
        res = []

        for pos in poses:
            if not res:
                res.append([ pos[0], [pos[1]] ])
            elif pos[0] == res[-1][0]:
                res[-1][1].append(pos[1])
            else:
                res.append([ pos[0], [pos[1]] ])
        return res

            

        


