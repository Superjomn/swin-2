import socket
import xml.dom.minidom as dom
from __future__ import division
from pyquery import PyQuery as pq

#self
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
        self.list_nums = []
        #calculated data
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
            _list = []
            node = statusNode(nodeName)
            items = node('item')
            for i in range(len(items)):
                _list.append( int( items.eq(i).attr('attr') ) )
        #parse xml
        signal = pq(signal)
        status = signal('signal')
        #refresh pages
        refreshListFromXML(status, 'pages', self.pages)
        #refresh queue_nums
        refreshListFromXML(status, 'queues', self.queue_nums)
        #refresh list_nums
        refreshListFromXML(status, 'lists', self.list_nums)
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
        total = sum(self.pages)
        v = total/self.getTimeSpan
        self.listAppendData(self.downloadSpeed, v)
        

@dec
def sendMessage(signal):
    '''
    base
    '''
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(("", 8881))
    print "..Connected to server .."
    sock.sendall(signal)
    print ".. Succeed send signal .."
    sock.close()

@dec
def sendInit():
    signal = '''
        <signal type='init'>
            <homeurl reptilenum=2>
                <item title='CAU'  url='http://news.cau.edu.cn' maxpage=200 />
                <item title='hsz'  url='http://org.wusetu.cn/hsz/' maxpage=200 />
            </homeurl>
        </signal>
    '''
    sendMessage(signal)

def sendRun():
    signal = '''
        <signal type='start'/>
    '''
    sendMessage(signal)

def sendResume():
    signal = '''
        <signal type='resume'/>
    '''
    sendMessage(signal)

def sendStop():
    signal = '''
        <signal type='stop'/>
    '''
    sendMessage(signal)

def sendStatus():
    signal = '''
        <signal type='status'/>
    '''
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(("", 8881))
    sock.sendall(signal)
    data = sock.recv(1024)
    print data
    sock.close()

def sendHalt():
    signal = '''
        <signal type='halt'/>
    '''
    sendMessage(signal)


if __name__ == '__main__':
    while True:
        data = raw_input('>')
        if not data:
            break
        print '.. send Message:', data
        if data == 'init':
            sendInit()
        elif data == 'run':
            sendRun()
        elif data == 'stop':
            sendStop()
        elif data == 'halt':
            sendHalt()
        elif data == 'resume':
            sendResume()
        elif data == 'status':
            sendStatus()

