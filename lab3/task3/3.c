#include <stdio.h>
#include <stdlib.h>

int calculate_expression(long int a, long int b) {
    return ((((b * b) + a) - b) * b) * b;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        return 1;
    }
    
    long int a = atoll(argv[1]);
    long int b = atoll(argv[2]);
    
    long int result = calculate_expression(a, b);
    
    printf("Выражение: ((((b*b)+a)-b)*b)*b\n");
    printf("Результат: %ld\n", result);
    
    return 0;
}