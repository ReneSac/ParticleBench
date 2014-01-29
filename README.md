ParticleBench
=============

OpenGL particle animation benchmark of various languages.

The benchmark can be run via 'go run Benchmarker.go', which will compile the languages, run them, and output an html table listing their average framerate, cpu time, resident memory usage, compile time, and compressed source size, as well as a .ppm framerate graph  for each language.

It reads from BenchmarkData.dat, so delete all the languages from there that you won't be testing and alter the Java classpath if necessary. Or, don't delete any, and hopefully it will just skip the invalid ones without crashing. The format is:

Line 1: Language name

Line 2: Command to compile (or '-' if language is intepreted)

Line 3: Command to run

Line 4: Name of source file (for measuring compressed source size and LOC)

Line 5: Name of executable file (for measuring output executable size)



The compilation instructions for individual languages are as follows:  

clang C.c -std=c99 -O3 -lGL -lGLU -lglfw3 -lX11 -lXxf86vm -lXrandr -lpthread -lXi -lm -lGLEW (gcc 4.72 doesn't work for me, llvm 3.2 does) 

g++ CPP.cpp -std=c++11 -O3 -lGL -lGLU -lglfw3 -lX11 -lXxf86vm -lXrandr -lpthread -lXi -lm -lGLEW (works with 4.7.3-1ubuntu1)

go build Go.go

dmd D.d -L-lDerelictGLFW3 -L-lDerelictUtil -L-ldl -L-lDerelictGL3 -O -release -inline

rustc R.rs --opt-level=3

racket Rkt.rkt

javac -classpath "lwjgl-2.9.0/jar/jinput.jar:lwjgl-2.9.0/jar/lwjgl.jar:lwjgl-2.9.0/jar/lwjgl_util.jar" ./ParticleBench.java

java -classpath "lwjgl-2.9.0/jar/jinput.jar:lwjgl-2.9.0/jar/lwjgl.jar:lwjgl-2.9.0/jar/lwjgl_util.jar:." -Djava.library.path=lwjgl-2.9.0/native/linux ParticleBench

mcs CS.cs -r:OpenTK.dll -unsafe

mono CS.exe

python Py.py

sbcl --load Lisp.lisp --eval "(pb:run)"

lein run (Clojure, requires leningen)

[babel](https://github.com/nimrod-code/babel) build *(Nimrod)*

[fcc](feephome.no-ip.org/%7Efeep/fccdists/fcc-latest.tar.bz2) Neat.nt && ./Neat
