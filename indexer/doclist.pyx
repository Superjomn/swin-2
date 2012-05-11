import sys
sys.path.append('../')

from Config import Config
from htmldb import HtmlDB
import math
from _parser.ICTCLAS50.Ictclas import Ictclas
from datetime import date

from libc.stdlib cimport malloc,free,realloc
from libc.stdio cimport fopen ,fclose ,fwrite ,FILE ,fread

config = Config()

Cimport Type.pyx            swin2/indexer/Type.pyx

cdef class DocList:
    '''
    记录每个doc的值
    生成一个list
    '''
    cdef:
        float *_list
        int size
        int docID
        object date
        object url
        object htmldb
        object ict
        #status
        object statusPath
        uint    curHtmlNum
        uint    refreshFrequency

    def __cinit__(self):
        self.ict = Ictclas( config.getpath('parser', 'ict_configure_path') )
        self.htmldb = HtmlDB()
        self.__initSpace()
        #status
        self.statusPath = config.getpath('indexer', 'status_path')
        self.refreshFrequency = config.getint('indexer', 'refresh_frequency')

    def __dealloc__(self):
        print 'delete all C space!'
        free(self._list)


    def run(self):
        '''
        DocList运行主程序
        可以自行运行
        '''
        cdef int i
        for i in range(self.size):
            self.setRecordHandle(i)
            self.calScore()
            #status
            self.curHtmlNum = i+1
            self.saveStatus()
        self.save()


    def saveStatus(self):
        '''
        人机界面刷新
        '''
        cdef:
            object res
            float radio
        
        if self.curHtmlNum%self.refreshFrequency == 0 or self.curHtmlNum==self.size:
            radio = self.curHtmlNum + 0.0
            radio = radio/self.size * 100

            res = 'doclist' + ' ' + str(self.size) + ' ' + str(self.curHtmlNum) + ' ' + str( int(radio) )
            f = open(self.statusPath, 'w')
            f.write(res)
            f.close()




    cdef void calScore(self):
        #默认不启用 timespan
        #_score = self.getLevel() * self.getTW() / self.getWordCount()
        cdef:
            unsigned int size
            float _score

        size = max(1, self.getWordCount())
        _score = self.getLevel() / size
        self.setValue(_score)


    cdef void save(self):
        print 'begin to save doclist'
        path = config.getpath('indexer', 'doc_score_path')
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph,"wb")
        fwrite( self._list, sizeof(float), self.size, fp)
        fclose(fp)
        #save record num
        path = config.getpath('indexer', 'doc_score_num_path')
        f = open(path, 'w')
        f.write(str(self.size))
        f.close()
        self.saveToText()
        
    cdef void saveToText(self):
        #测试使用
        path = '/home/chunwei/swin2/data/doclist.txt'
        res = ''
        for  i in range(self.size):
            res += str(i) + ' ' + str(self._list[i])
            res += '\n'
        f=open(path, 'w')
        f.write(res)
        f.close()
        


    cdef __initSpace(self):
        '''
        取得dod数量 初始化空间
        '''
        #get doc num
        self.size = self.htmldb.getHtmlNum()
        #分配空间
        self._list = <float *>malloc(sizeof(float) * self.size)

    cdef void setValue(self, float value):
        self._list[ self.docID ] = value
        

    cdef void setRecordHandle(self, int docID):
        htmlinfo = self.htmldb.setRecordHandle(docID)
        self.date = htmlinfo.date
        self.url = htmlinfo.url
        self.docID = docID

    cdef float getLevel(self):
        '''
        计算页面level值
        '''
        cdef:
            float _level
            unsigned int size
            
        size = self.url.count('/')

        if self.url[-1] == '/':
            _level = size  - 3
        else:
            _level = size - 2

        _level += 1.1


        return 1/_level


    cdef float getTW(self):
        '''
        计算时间值
        '''
        cdef:
            int days

        days = (date.today() - self.date).days
        return math.log(math.e, days)

    cdef int getWordCount(self):
        '''
        计算词汇数目
        '''
        _content = self.htmldb.getContentByIndex(self.docID)
        word_split = self.ict.split(str(_content)).split()
        return len(word_split)



cdef class InitDocList:
    '''
    通过doclist文件初始化doclist
    '''
    cdef:
        float *_list
        int size
        object htmldb

    def __cinit__(self):
        '''
        init float space 
        '''
        #init values
        self.size = 0
        self.htmldb = HtmlDB()
        #具体的初始化工作
        self.__init()

    def __init(self):
        self.__initSize()
        self.__initSpace()
        self.__initList()

    def get(self, int docID):
        return self._list[docID]

    cdef __initSize(self):
        #init list
        path = config.getpath('indexer', 'doc_score_num_path')
        f = open(path)
        c = f.read()
        f.close()
        self.size = int(c)
        
        
    cdef __initList(self):
        path = config.getpath('indexer', 'doc_score_path')
        cdef char* ph = path
        cdef FILE *fp=<FILE *>fopen(ph, "rb")
        fread(self._list, sizeof(float), self.size ,fp)
        fclose(fp)


    cdef __initSpace(self):
        '''
        取得dod数量 初始化空间
        '''
        #分配空间
        self._list = <float *>malloc(sizeof(float) * self.size)
        
    def __dealloc__(self):
        print 'delete all C space!'
        free(self._list)

