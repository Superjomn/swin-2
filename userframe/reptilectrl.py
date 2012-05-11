# -*- coding: utf-8 -*-
from __future__ import division
import socket
import xml.dom.minidom as dom
from pyquery import PyQuery as pq

#self
import sys
sys.path.append('../')
from debug import *
import time

class ReptileStatus:
    '''
    show the reptilelib's operating efficiency
    and some other data 
    '''
    def __init__(self):
        self.historyNum = 20
        self.latestTimer = None
        #system init data
        self.maxpages = []
        self.homeurls = []
        self.threadNum = 0
        #real-time data
        self.pages = []
        #contain a list of numeric values of every urlQueue's length
        self.queue_nums = []
        #contain a list of numeric values of every list's length
        self.listnum = 0
        #calculated data
        self.pageSum = []
        #contains a queue of numeric values
        #asked by front web frame to show a line-graph
        self.downloadSpeed = []
        #asked by front to show change of the sum of queues's length
        #appear as a line graph
        self.queueLengths = []

    def init(self, maxpages, homeurls, threadNum):
        '''
        system init data
        '''
        self.maxpage = maxpage
        self.homeurls = homeurls
        self.threadNum = threadNum

    def refresh(self, signal):
        '''
        trans xml status to data in list
        '''
        def refreshListFromXML(statusNode, nodeName, _list):
            node = statusNode(nodeName)
            items = node('item')
            for i in range(len(items)):
                _list.append( int( items.eq(i).attr('attr') ) )

        #parse xml
        signal = pq(signal)
        status = signal('signal')
        #refresh pages
        self.pages = []
        refreshListFromXML(status, 'pages', self.pages)
        #refresh queue_nums
        self.queue_nums = []
        refreshListFromXML(status, 'queues', self.queue_nums)
        #refresh list_nums
        self.listnum = 0
        _list = status('list')
        self.listnum = int( _list.attr('attr'))
        self.imagenum = int( status('imagenum').attr('attr'))
        #refreshListFromXML(status, 'lists', self.list_nums)
        #refresh vs
        self.calDownloadSpeed()
        

    def getTimeSpan(self):
        if not self.latestTimer:
            self.latestTimer = time.time()
            return 0
        curTime = time.time()
        span = curTime - self.latestTimer
        self.latestTimer = curTime
        return span
    
    def listAppendData(self, _list, data):
        '''
        append new data to limited list
        '''
        if len(_list) == self.historyNum :
            #should remove a data space for the new data
            del _list[0]
        _list.append(data)


    def calDownloadSpeed(self):
        '''
        append new speed to self.downloadSpeed
        and drop the first speed value for the new speed
        the num of speeds remain self.historyNum
        '''
        total = sum(self.pages) + self.imagenum
        self.listAppendData(self.pageSum, total)

        if len(self.pageSum) == 1:
            total = self.pageSum[-1]
        else:
            total = self.pageSum[-1] - self.pageSum[-2]

        span = self.getTimeSpan()

        if not span :
            v = 0
        else:
            v = round(total/span, 3)

        self.listAppendData(self.downloadSpeed, v)



class ReptileCtrl:
    '''
    Reptile control commands
    '''
    def __init__(self):
        self.reptilestatus = ReptileStatus()
        
    def sendMessage(self, signal):
        '''
        base
        '''
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(("", 8881))
        print "..Connected to server .."
        sock.sendall(signal)
        print ".. Succeed send signal .."
        sock.close()

    def sendInit(self):

        signal = '''
            <signal type='init'>
                <homeurl reptilenum=4>

                    <item title='新闻中心'  url='http://news.cau.edu.cn' maxpage=300 />
                    <item title='教务处'  url='http://jwc.cau.edu.cn/administration_office' maxpage=200 />
                    <item title='人事处'  url='http://rsc1.cau.edu.cn/' maxpage=200 />
                    <item title='校团委'  url='http://youth.cau.edu.cn/' maxpage=300 />
                    <item title='团工委'  url='http://shetuan.cau.edu.cn/' maxpage=200 />
                    <item title='曲辰网'  url='http://quchen.cau.edu.cn' maxpage=200 />
                    <item title='农学院'  url='http://cab.cau.edu.cn/' maxpage=200 />
                    <item title='食品学院'  url='http://spxy.cau.edu.cn' maxpage=300 />
                    <item title='信息与电气学院'  url='http://www.ciee.cn/ciee/' maxpage=300 />
                    <item title='理学院'  url='http://www.cau.edu.cn/sci' maxpage=200 />
                    <item title='中国农业大学'  url='http://www.cau.edu.cn' maxpage=200 />

                </homeurl>
            </signal>
            '''


        signal_1 = """
            <signal type='init'>
                <homeurl reptilenum=1>
                    <item title='新闻中心'  url='http://news.cau.edu.cn' maxpage=200 />
                </homeurl>
            </signal>
        """
        self.sendMessage(signal)

    def sendStart(self):
        signal = '''
            <signal type='start'/>
        '''
        self.sendMessage(signal)

    def sendResume(self):
        signal = '''
            <signal type='resume'/>
        '''
        self.sendMessage(signal)

    def sendStop(self):
        signal = '''
            <signal type='stop'/>
        '''
        self.sendMessage(signal)

    def sendStatus(self):
        signal = '''
            <signal type='status'/>
        '''
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(("", 8881))
        sock.sendall(signal)
        data = sock.recv(1024)
        print data
        sock.close()
        self.reptilestatus.refresh(data)
        #show status
        print '.. status ..'
        print '.. pages', self.reptilestatus.pages
        print '.. imagenum', self.reptilestatus.imagenum
        print '.. queue_nums', self.reptilestatus.queue_nums
        print '.. list_nums', self.reptilestatus.listnum
        print '.. downloadSpeed', self.reptilestatus.downloadSpeed

    def sendHalt(self):
        signal = '''
            <signal type='halt'/>
        '''
        self.sendMessage(signal)

    def commandRun(self):
        while True:
            data = raw_input('>')
            if not data:
                break
            print '.. send Message:', data
            if data == 'init':
                self.sendInit()
            elif data == 'run':
                self.sendStart()
            elif data == 'stop':
                self.sendStop()
            elif data == 'halt':
                self.sendHalt()
            elif data == 'resume':
                self.sendResume()
            elif data == 'status':
                self.sendStatus()


if __name__ == '__main__':
    reptilectrl = ReptileCtrl()
    reptilectrl.commandRun()
