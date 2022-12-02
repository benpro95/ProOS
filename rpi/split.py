#!/bin/python3
## Split up a delimited file, by data in a field also name the output file as that field name.

import pandas

data = pandas.read_csv('test.csv', sep='|', header=0, skipinitialspace=False)
for (ID), group in data.groupby(['Fruit ID']):
     group.to_csv(f'{ID}.csv', index=False , sep='|')

#print(data)

exit()
