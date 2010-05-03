import sys
sys.path.append('../')
from Config import Config
config = Config()

from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread


Cimport recordcollector.pyx swin2/query/recordcollector.pyx
Cimport query.pyx           swin2/query/query.pyx




cdef class Queryer:
    '''
    传入 docIDs
    传出 object []  直接给Django
    包含站点控制
    '''
    cdef:
        Query   __query
        uint    pagePerNum          #每页多少记录
        uint    perPage             #当前页面
        uint    pageNum             #页面数目
        object  docIDs
        object  siteNums             #num of pages of each site
        RecordCollector recordCollector


    def __cinit__(self):
        self.__query = Query()
        self.recordCollector = RecordCollector()
        self.docIDs = []
        self.pagePerNum = 0
        self.perPage = 0
        self.siteNums = []      #[ [left,right], [left,right]]


    def search(self, strr, siteID, page):
        '''
        input search words and pager
        return :
            [
                [ dectitle, url, date, dectext],
                [ dectitle, url, date, dectext],
            ]
        '''
        self.docIDs = self.__query.query(strr)

        print '.. return docIDs', self.docIDs

        if siteID != 0:
            '''
            siteID为 siteID+1
            if siteID == 0 that means all sites hits
            '''
            siteID -= 1
            #self.siteNumFilter(siteID)

        #self.pagerFilterDocIDs(page)    #将docIDs进行一些筛选处理
        #现在self.docIDs可以使用
        return self.recordCollector.getRecord(self.docIDs)
        

    cdef inline void pagerFilterDocIDs(self, pager):
        '''
        根据页码 对docIDs作一些处理
        此处不会对页码作判断
        所有判断在以后
        '''
        cdef:
            uint size
            uint left
            uint right

        size = len(self.docIDs)
        self.pageNum = int((size+self.pagePerNum-1)/self.pagePerNum) 
        left = self.pagePerNum * (pager-1)
        right = self.pagePerNum * pager
        self.docIDs = self.docIDs[left:right]


    cdef inline void siteNumFilter(self, siteID):
        '''
        filter pages by siteID
        '''
        cdef:
            uint left
            uint right
            uint docID
            object _tem
        
        [left, right] = self.siteNums[siteID]
        _tem = []

        for docID in self.docIDs:
            if docID >= left and docID <= right:
                _tem.append(docID)
        self.docIDs = _tem


    cdef void initSiteNums(self):
        cdef:
            int i

        path = getpath('indexer', 'sites_num_path')
        f = open(path)
        c = f.read()
        f.close()
        tem = [int(word) for word in c.split()]
        self.siteNums 
        total = 0

        for i,num in enumerate(tem):
            self.siteNums.append( [total, total+num] )
            total += num

   
