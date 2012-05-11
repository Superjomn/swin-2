from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("fileparser", ["fileparser.py"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("htmlparser", ["htmlparser.py"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("urlparser", ["urlparser.py"])] 
)



