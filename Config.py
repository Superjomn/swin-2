import ConfigParser
import os
config = ConfigParser.ConfigParser()

def Config():
    path = os.path.abspath(__file__)
    path = os.path.dirname(path)
    path = os.path.join(path+'/', "swin2.ini")
    config.read(path)
    return config

if __name__ == '__main__':
    print Config()
    
    
