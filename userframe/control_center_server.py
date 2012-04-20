import SocketServer

class ControlCenter(SocketServer.BaseRequestHandler):
    def handle(self):
        print "Connected from", self.client_address
        while True:
            receivedData = self.request.recv(8192)
            if not receivedData:
                break
            self.request.sendall(receivedData)
        self.request.close()
        print "Disconnected from", self.client_address

class ReptileSignal:
    def sendInit(self, info=None):
        '''
        send init info to TCP Server
        '''
    def sendResume(self):
        pass
    