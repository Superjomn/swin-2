from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("HashIndex", ["__HashIndex.pyx"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("InitThes", ["__InitThes.pyx"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("Thes", ["__Thes.pyx"])] 
)

setup(
cmdclass = {'build_ext': build_ext},
ext_modules = [Extension("List", ["__List.pyx"])] 
)

