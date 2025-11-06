#include <stdio.h>
#include <stdlib.h>

extern unsigned long* queue_create(unsigned long capacity);
extern void queue_destroy(unsigned long* queue);
extern int enqueue(unsigned long* queue, unsigned long value);
extern int dequeue(unsigned long* queue, unsigned long* value_ptr);
extern void queue_fill_random(unsigned long* queue);
extern unsigned long queue_count_even(unsigned long* queue);
extern unsigned long queue_count_ending_in_1(unsigned long* queue);
extern unsigned long queue_get_odd_numbers(unsigned long* queue, unsigned long* output_array);

int main() {
    unsigned long capacity = 15;
    unsigned long value;

    printf("1. Создание очереди на %lu элементов \n", capacity);
    unsigned long* my_queue = queue_create(capacity);
    printf("Очередь создана.\n\n");

    printf("2. Заполнение очереди случайными числами \n");
    queue_fill_random(my_queue);
    printf("Очередь заполнена.\n\n");

    
    printf("3. Подсчет четных чисел \n");
    unsigned long even_count = queue_count_even(my_queue);
    printf("Найдено четных чисел: %lu\n\n", even_count);

    printf("4. Подсчет чисел, оканчивающихся на 1\n");
    unsigned long ends_in_1_count = queue_count_ending_in_1(my_queue);
    printf("Найдено чисел, оканчивающихся на 1: %lu\n\n", ends_in_1_count);

    printf("5. Получение списка всех нечетных чисел \n");
    unsigned long odd_numbers_array[capacity];
    long odd_count = queue_get_odd_numbers(my_queue, odd_numbers_array);
    
    printf("Найдено нечетных чисел: %lu. Список: [ ", odd_count);
    for (int i = 0; i < odd_count; i++) {
        printf("%lu ", odd_numbers_array[i]);
    }
    printf("]\n\n");
    
    printf("--- 6. Демонстрация добавления и удаления ---\n");
    printf("Извлекаем первый элемент из очереди...\n");
    if (dequeue(my_queue, &value)) {
        printf("Извлекли значение: %lu\n", value);
    } else {
        printf("Очередь пуста.\n");
    }

    printf("Теперь добавляем число 999 в конец очереди...\n");
    if (enqueue(my_queue, 999)) {
        printf("Число 999 успешно добавлено.\n\n");
    } else {
        printf("Не удалось добавить число (очередь полна).\n\n");
    }

    printf("--- 7. Финальное содержимое очереди ---\n");
    printf("Содержимое: [ ");
    while (dequeue(my_queue, &value)) {
        printf("%lu ", value);
    }
    printf("]\n\n");

    printf("--- 8. Уничтожение очереди ---\n");
    queue_destroy(my_queue);
    printf("Память очищена. Программа завершена.\n");
    
    return 0;
}