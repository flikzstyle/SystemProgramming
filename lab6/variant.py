import random as rd

Variant = 27
rd.seed(Variant)


colors = ['COLOR_BLACK', 'COLOR_RED', 'COLOR_GREEN', 'СOLOR_YELLOW', 'COLOR_BLUE', 'COLOR_MAGENTA', 'COLOR_CYAN', 'COLOR_WHITE']
buttons = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'a', 's', 'd', 'f', 'g', 'h', 'j','k','l','z','x','c','v','b','n','m']
print("Алгоритм: " , rd.sample([1,2,3,4,5,6,7,8],1))
print("Цвета заполнения: " , rd.sample(colors,2))
print("Кнопки выхода, изменения скорости: " , rd.sample(buttons,2))
