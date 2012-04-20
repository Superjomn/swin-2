# -*- coding: utf-8 -*-
import threading  
import socket
from pyquery import PyQuery as pq

class ReptileSignal:
    def __init__(self):
        '''
        inQueue:    signal Queue to connect reptile lib
        '''
        pass
        
    def sendInit(self, signal_parser):
        '''
        send init info to reptilelib

        receive signal:
            <signal type='init'>
                <homeurl reptilenum=20>
                    <item title='CAU'  url='http://www.cau.edu.cn' maxpage=2000/>
                    <item title='CAU'  url='http://www.cau.edu.cn' maxpage=2000/>
                    <item title='CAU'  url='http://www.cau.edu.cn' maxpage=2000/>
                </homeurl>
            </signal>
        '''
        htmlurl = signal_parser('homeurl')
        items = htmlurl('item')
        res = {}
        res['type'] = 'init'
        res['reptilenum'] = htmlurl.attr('reptilenum')
        res['homeurls'] = []
        for i in range(len(items)):
            item = items.eq(i)
            sg = {}
            sg['title'] = item.attr('title')
            sg['url'] = item.attr('url')
            sg['maxpage'] = item.attr('maxpage')
            res['homeurls'].append(sg)
        self.inQueue.put(res)

    def sendResume(self):
        '''
        send Resume signal to reptile lib

        receive signal:
            <signal type='resume'/>
        '''
        res = {}
        res['type'] = 'resume'
        self.inQueue.put(res)

    def sendStop(self):
        '''
        send Stop signal to reptile lib
        '''
        res = {}
        res['type'] = 'stop'
        self.inQueue.put(res)

    
class ControlServer(threading.Thread):
    '''
    receive TCP XML signal from UserFrame and send 
    signal to reptilectrl lib by Queue
    '''
    def __init__(self, inQueue, outQueue):
        threading.Thread.__init__(self, name = "reptilelib" )  
        self.reptilesignal = ReptileSignal()
        self.inQueue = inQueue
        self.outQueue = outQueue

    def run(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.bind('', 8881)
        self.sock.listen(5)
        
        try:
            while True:
                newSocket, address = self.sock.accept()
                print "Connected from", address
                while True:
                    receivedData = newSocket.recv(8192)
                    if not receivedData:
                        print '.. no data received ..'
                        print '.. stop reptile Control Server ..'
                        break
                    self.handle_signal(receivedData)
                newSocket.close()
                print "Disconnected from", self.client_address
        finally:
            self.sock.close()
    
    def handle_signal(self, signal):
        print '.. get signal',signal
        _signal_parser = pq(signal)('signal')
        _type = _signal_parser.attr('type')

        if _type == 'init':
            '''
            init reptilelib by following info
            '''
            self.reptilesignal.sendInit(_signal_parser)
            
        elif _type == 'resume':
            '''
            resume repitle lib from database
            '''
            self.reptilesignal.sendResume()

        elif _type == 'stop':
            self.reptilesignal.sendStop()
    
    
        


