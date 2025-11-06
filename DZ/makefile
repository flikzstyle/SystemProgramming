TARGET = queue_test

all: $(TARGET)

$(TARGET): main.o dz.o
	gcc -no-pie $^ -o $@

dz.o: dz.asm
	fasm dz.asm dz.o

clean:
	rm -f $(TARGET) *.o

run: all
	./$(TARGET)