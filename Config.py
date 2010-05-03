import ConfigParser
import os

class Config:
    def __init__(self):
        self.config = ConfigParser.ConfigParser()
        _path = os.path.abspath(__file__)
        _path = os.path.dirname(_path)
        _path = os.path.join(_path+'/', "swin2.ini")
        self.config.read(_path)
        self.basepath = self.config.get('whole', 'basepath')

    def get(self, section, key):
        return self.config.get(section, key)

    def getint(self, section, key):
        return self.config.getint(section, key)

    def getbool(self, section, key):
        return self.config.getbool(section, key)

    def getpath(self, section, key):
        _path = self.get(section, key)
        print 'path', _path
        return os.path.join( self.basepath, _path)
        
        


if __name__ == '__main__':
    config = Config()
    print config.getpath('indexer', 'idxs_num_path')

    
    
