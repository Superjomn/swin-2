# -*- coding: utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
import threading  
import socket
from pyquery import PyQuery as pq
import xml.dom.minidom as dom
#self
sys.path.append('../')
from Config import Config
_config = Config()
from debug import *

class ReptileSignal:
    '''
    send dic signal through inQueue to core reptile lib
    '''
    def __init__(self, inQueue, outQueue):
        '''
        inQueue:    signal Queue to connect reptile lib
        '''
        self.inQueue = inQueue
        self.outQueue = outQueue

    @dec
    def queueStatus(self):
        '''
        detect signal queue status
        '''
        print 'inQueue size:', self.inQueue.qsize()
        print 'outQueue size', self.outQueue.qsize()
        
    @dec
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
        res['reptilenum'] = int( htmlurl.attr('reptilenum') )
        res['homeurls'] = []
        res['maxpages'] = []

        for i in range(len(items)):
            item = items.eq(i)
            sg = []
            sg.append(item.attr('title'))
            sg.append(item.attr('url'))
            res['maxpages'].append( int(item.attr('maxpage')) )
            res['homeurls'].append(sg)
        self.inQueue.put(res)

    @dec
    def sendStart(self):
        '''
        preparation is done and start reptile threads
        get signal:
        <signal type='start'/>
        '''
        res = {}
        res['type'] = 'start'
        self.inQueue.put(res)
        #get status from queue
        #status = self.outQueue.get()

    def sendStatus(self, newSocket):
        '''
        send Status to client
        '''
        def sendStatusSignal(_signal):
            '''
            send status to client
            xml:
            <signal type='status'>
                <pages>
                    <item attr="2"/>
                    <item attr="2"/>
                </pages>
                <queues>
                    <item attr="2"/>
                </queues>
                <lists>
                    <item attr="2"/>
                </lists>
            </signal>
            '''
            pages = _signal['pages']
            queue_num = _signal['queue_num']
            list_num = _signal['list_num']

            dd = dom.parseString('<signal></signal>')
            signal = dd.firstChild
            signal.setAttribute('type', 'status')
            pages_node = dd.createElement('pages')
            signal.appendChild(pages_node)

            for page in pages:
                item = dd.createElement('item')
                item.setAttribute('attr', str(page))
                pages_node.appendChild(item)

            queue_node = dd.createElement('queues')
            signal.appendChild(queue_node)

            for _queue in queue_num:
                item = dd.createElement('item')
                item.setAttribute('attr', str(_queue))
                queue_node.appendChild(item)

            list_node = dd.createElement('list')
            list_node.setAttribute('attr', str(list_num))
            signal.appendChild(list_node)

            imagenum_node = dd.createElement('imagenum')
            imagenum_node.setAttribute('attr', str(_signal['imagenum']))
            signal.appendChild(imagenum_node)

            return signal.toxml()

        res = {}
        res['type'] = 'status'
        self.inQueue.put(res)
        #get status and send them
        try:
            signal = self.outQueue.get(timeout=3)
        except:
            return

        _signal = sendStatusSignal(signal)
        print _signal
        newSocket.sendall(_signal)
        #newSocket.close()

    @dec
    def sendResume(self):
        '''
        send Resume signal to reptile lib

        receive signal:
            <signal type='resume'/>
        '''
        res = {}
        res['type'] = 'resume'
        self.inQueue.put(res)

    @dec
    def sendStop(self):
        '''
        send Stop signal to reptile lib
        '''
        res = {}
        res['type'] = 'stop'
        self.inQueue.put(res)

    @dec
    def sendHalt(self):
        '''
        send halt signal to reptile lib
        '''
        res = {}
        res['type'] = 'halt'
        self.inQueue.put(res)
        
    
class ControlServer(threading.Thread):
    '''
    receive TCP XML signal from UserFrame and send 
    signal to reptilectrl lib by inQueue
    '''
    def __init__(self, inQueue, outQueue):
        threading.Thread.__init__(self, name = "reptilelib" )  
        self.reptilesignal = ReptileSignal(inQueue, outQueue)
        self.inQueue = inQueue
        self.outQueue = outQueue

    @dec
    def queueStatus(self):
        '''
        detect signal queue status
        '''
        print 'inQueue size:', self.inQueue.qsize()
        print 'outQueue size', self.outQueue.qsize()

    @dec
    def run(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        #get value from config file 'swin2.ini'
        _address = _config.get("server", "server_address")
        _port = _config.getint("server", "server_port")
        self.sock.bind((_address, _port))
        self.sock.listen(5)
        
        try:
            while True:
                newSocket, address = self.sock.accept()
                print "Connected from", address
                while True:
                    receivedData = newSocket.recv(8192)
                    if not receivedData:
                        break
                    print '.. get Signal', receivedData
                    self.handle_signal(newSocket, receivedData)

                newSocket.close()
                print "Disconnected from", address
        finally:
            self.sock.close()
    
    @dec
    def handle_signal(self, newSocket, signal):
        print '.. get signal',signal
        _signal_parser = pq(signal)
        _signal_parser = _signal_parser('signal')
        _type = _signal_parser.attr('type')

        if _type == 'init':
            '''
            init reptilelib by following info
            '''
            self.queueStatus()
            self.reptilesignal.sendInit(_signal_parser)

        elif _type == 'start':
            '''
            preparation is done
            start reptile threads and work
            '''
            self.queueStatus()
            self.reptilesignal.sendStart()
            
        elif _type == 'resume':
            '''
            resume repitle lib from database
            '''
            self.queueStatus()
            self.reptilesignal.sendResume()

        elif _type == 'stop':
            self.queueStatus()
            self.reptilesignal.sendStop()
        
        elif _type == 'halt':
            self.reptilesignal.sendHalt()

        elif _type == 'status':
            self.reptilesignal.sendStatus(newSocket)
    
