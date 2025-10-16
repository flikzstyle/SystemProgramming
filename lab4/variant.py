import random as rd

Variant = 27
rd.seed(Variant)

Numbers_of_problems = [i+1 for i in rd.sample(range(14),3)]
Numbers_of_problems

print(Numbers_of_problems)
