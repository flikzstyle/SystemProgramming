import random as rd

Variant = 27
rd.seed(Variant+4335)

Numbers_of_problems = [rd.sample(range(5),1)[0]+1, rd.sample(range(5),1)[0]+1, rd.sample(range(5),1)[0]+1]
print(Numbers_of_problems)
