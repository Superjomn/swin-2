import socket

#self
from debug import *

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

def sendStop():
    signal = '''
        <signal type='stop'/>
    '''
    sendMessage(signal)

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

