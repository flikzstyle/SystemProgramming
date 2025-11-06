import random as rd

Variant = 27
rd.seed(Variant+65456)

list_struct = ["Очередь", "Массив"]
get_memory = ["Куча", "Анонимное отображение"]
list_func_array = ["Создание массива заданного размера","Заполнение случайными числами", "Нахождение суммы элементов массива", "Подсчет количества четных чисел",
                   "Получение списка нечетных чисел", "Подсчет количества простых чисел", "Реверсирование элементов массива"]
list_func_quiuing = ["Добавление в конец","Удаление из начала", "Заполнение случайными числами",
                     "Подсчет количества четных чисел", "Получение списка нечетных чисел", "Подсчет количества простых чисел",
                    "Подсчет количества чисел, оканчивающихся на 1",
                     "Удаление всех четных чисел (прочитанное нечетное число добавляется обратно в конец)"]

name_struct = rd.sample(list_struct,1)
name_get_memory = rd.sample(get_memory,1)
if name_struct == ["Очередь"]:
    list_action =[list_func_quiuing[0], list_func_quiuing[1], list_func_quiuing[2]]+rd.sample(list_func_quiuing[3:],3)
if name_struct == ["Массив"]:
    list_action =[list_func_quiuing[0], list_func_quiuing[1]]+rd.sample(list_func_quiuing[2:],3)
print("Структура: ", name_struct)
print("Метод выделения памяти: ", name_get_memory)
print("Список функций (действий): ", list_action);