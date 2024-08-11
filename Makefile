

main: $(wildcard *.c3)
	c3c compile -g -O0 $(wildcard *.c3)
