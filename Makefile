targets = demo-static demo-dynamic demo-runtime

all: $(targets)

clean:
	rm -f $(targets) *.o *.so

%.o: %.c
	gcc -Wall -c $< -o $@
libmy-data.so: my-data.o
	gcc -fPIC -shared $< -o $@

demo-static: demo.o my-data.o my-data.h
	gcc -static -o demo-static demo.o my-data.o

demo-dynamic: demo.o libmy-data.so
	gcc -L. -o demo-dynamic demo.o -lmy-data

demo-runtime: demo-runtime.c
	gcc -Wall -o demo-runtime demo-runtime.c -ldl
