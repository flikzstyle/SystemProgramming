#include <stdio.h>

long long N = 5277616985;

int main() {
    char sum = 0;
    for (; N; N /= 10){ // for быстрее
        sum += N % 10;
    }

    printf("%d\n", sum);

    return 0;
}
