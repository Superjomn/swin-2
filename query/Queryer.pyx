import sys
sys.path.append('../')
from Config import Config
config = Config()
from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread
import time
import math
import htmldb

Cimport recordcollector.pyx swin2/query/recordcollector.pyx
Cimport query.pyx           swin2/query/query.pyx

cdef struct Domain:
    uint left
    uint right

cdef enum FileType:
    Html    =   0
    Image   =   1
    File    =   2



cdef class Queryer:
    '''
    传入 docIDs
    传出 object []  直接给Django
    包含站点控制
    '''
    cdef:
        Query   __query

        uint    pagePerNum          #每页多少记录
        uint    imagePerNum         #每页多少图片
        uint    filePerNum          #每页多少文件

        #-----------缓存----------------
        object  text                #用于底层 Cache
        uint    siteID

        uint    pageNum             #页面数目
        uint    imageNum            #image数目
        uint    fileNum             #file数目

        uint    perPage             #当前页面

        Domain  domain              #当前范围

        object  docIDs              #底层的cache docIDs 最底层的查询
        object  resIDs              #返回的docIDs
        object  siteNums             #num of pages of each site
        RecordCollector             recordCollector
        object  htmldb
        object titles


    def __cinit__(self):
        self.__query = Query()
        self.recordCollector = RecordCollector()
        self.docIDs = []
        self.siteNums = []      #[ [left,right], [left,right]]
        self.text = ''
        #分码
        self.perPage = 0
        self.pagePerNum = config.getint('query', 'page_per_num')
        self.imagePerNum = config.getint('query', 'image_per_num')
        self.filePerNum = config.getint('query', 'file_per_num')
        #siteID 区分
        self.initSiteNums()
        self.htmldb = htmldb.HtmlDB()


    cdef void setDomain(self, FileType filetype, uint page):
        '''
        得到范围
        从 1开始
        '''
        cdef:
            uint left
            uint right

        assert(page>0)
        page -= 1

        if filetype == Html:
            left = self.pagePerNum * page
            right = self.pagePerNum * (page+1)
            right = min(right, self.pageNum)
            self.domain.left = left
            self.domain.right = right

        elif filetype == Image:
            left = self.imagePerNum * page
            right = self.imagePerNum * (page+1)
            right = min(right, self.imageNum)
            self.domain.left = left
            self.domain.right = right

        else:
            left = self.filePerNum * page
            right = self.filePerNum * (page+1)
            right = min(right, self.pageNum)
            self.domain.left = left
            self.domain.right = right
            

    cdef void search(self, object strr, uint siteID):
        '''
        最底层的搜索程序
        input search words and pager
        return :
            [
                [ dectitle, url, date, dectext],
                [ dectitle, url, date, dectext],
            ]
        '''
        print 'siteID', siteID
        if self.text == strr and siteID == self.siteID:
            #底层 Cache
            return

        #缓存判断
        self.text = strr
        self.siteID = siteID
        self.docIDs = self.__query.query(strr)
        self.pageNum = len(self.docIDs)

        #print '.. return docIDs', self.docIDs

        self.docIDs.reverse()
        if siteID != 0:
            '''
            siteID为 siteID+1
            if siteID == 0 that means all sites hits
            '''
            siteID -= 1
            self.siteNumFilter(siteID)
            print 'siteNum left, right',self.siteNums[siteID]
            #sort reverse from big to less

        #self.pagerFilterDocIDs(page)    #将docIDs进行一些筛选处理
        #现在self.docIDs可以使用


    def searchText(self, strr, siteID, page):

        cdef:
            object docIDs
            object res
            uint pagenum

        time1 = time.time()
        self.search(strr, siteID)
        #self.pagerFilterDocIDs(page)
        self.setDomain(Html, page)
        #print '.. begin to left:right', self.domain.left, self.domain.right

        self.resIDs = self.docIDs[self.domain.left : self.domain.right]
        #print 'self.resIDs', self.resIDs
        #包装
        #print self.resIDs 
        #开始生成部分结果格式 ---------------------
        #计算页面数目

        pagenum = self.pageNum / self.pagePerNum

        if pagenum * self.pagePerNum > self.pageNum:
            pagenum += 1

        #print '.. pagenum', pagenum

        res = {}
        res['res_list'] = self.recordCollector.getRecord(self.resIDs, self.__query.words)
        #print 'res[res_list]', res['res_list']
        time2 = time.time()
        res['time'] = round(time2-time1, 4)
        res['site'] = siteID
        res['length'] = self.pageNum
        res['page'] = page
        res['pagenum'] = pagenum
        res['query_text'] = strr

        #print res

        return res


    def searchImages(self, strr, siteID, page):
        '''
        查找图片
        '''
        cdef:
            object res
            object images
            object image
            object tem
            uint pagenum

        time1 = time.time()
        print '.. searching Image'
        self.search(strr, siteID)
        self.imageNum = self.htmldb.get_image_num(self.docIDs)
        self.setDomain(Image, page)
        self.docIDs.reverse()
        res = self.htmldb.get_images(self.docIDs, self.domain.left, self.domain.right)

        images = []
        for image in res:
            tem = []
            tem.append(image.height)
            tem.append(image.width)
            tem.append(image.path[24:])
            tem.append(image.url)
            images.append(tem)

        time2 = time.time()
        #res =  self.recordCollector.getImages(res)
        #print '.. final res',res
        pagenum = self.imageNum / self.imagePerNum
        if pagenum * self.imagePerNum > self.imageNum:
            pagenum += 1

        res = {}
        res['time'] = round(time2-time1, 4)
        res['site'] = siteID
        res['length'] = self.imageNum
        res['page'] = page
        res['pagenum'] = pagenum
        res['res_list'] = images
        res['query_text'] = strr

        return res


    def searchFiles(self, strr, siteID, page):
        '''
        查找文件
        '''
        cdef:
            object res

        self.search(strr, siteID)
        self.fileNum = self.htmldb.get_file_num(self.docIDs)
        self.setDomain(File, page)
        res = self.get_files(self.docIDs, self.domain.left, self.domain.right)

        files = []
        for image in res:
            tem = []


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
                print 'siteIDs append', docID
                _tem.append(docID)
        self.docIDs = _tem
        self.pageNum = len(self.docIDs)
        print 'filter siteNUm siteID' ,self.docIDs


    cdef void initSiteNums(self):
        cdef:
            int i

        path = config.getpath('indexer', 'sites_num_path')
        f = open(path)
        c = f.read()
        f.close()
        tem = [int(word) for word in c.split()]
        self.siteNums 
        total = 0

        for i,num in enumerate(tem):
            self.siteNums.append( [total, total+num] )
            total += num

   
