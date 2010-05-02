from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("sorter", ["__sorter.pyx"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("query", ["__query.pyx"])] 
)


