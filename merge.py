#!/usr/bin/env python
import os
import sys
import math
import string
import operator
import pickle


def idf(totalDocs,filter_TF,all_vocabulary):
    IDF = {}
    for token in all_vocabulary:
        IDF[token] = 0
        for fileid in filter_TF:
            try:
                if  filter_TF[fileid][token] > 0:
                    IDF[token] += 1
            except:
                pass
        if IDF[token] > 0:
            IDF[token]=math.log(totalDocs / float(IDF[token]))
    return IDF


if __name__ == '__main__':

    OUTPUT = sys.argv[1]
    # Load first item to determine the type
    ACCUM = pickle.load(open(sys.argv[2],"rb"))

    for i in sys.argv[3:]:
        temp = pickle.load(open(i,"rb"))
        if ( type(temp) == type(dict()) ):
            ACCUM.update(temp)
        elif ( type(temp) == type(list()) ):
            ACCUM = ACCUM + temp

    pickle.dump( ACCUM, open(OUTPUT, "wb"));
