#!/usr/bin/env python
import os
import sys
import traceback
import csv
import re
import math
import string
import operator
#import nltk
import pickle
from pprint import pprint
#from nltk.corpus import PlaintextCorpusReader
#from nltk.corpus import stopwords

import time
time.sleep(30)

#get freq count for each token in each doc
def freq(word, vocab):
    return vocab.count(word)

#get the term freq for each token in each doc
# This is the 'TF' in TF*IDF
# Here we take teh log of the freq+1 to smooth its probability mass over un-observed tokens.
def tf(frequency,vocab):
    return math.log(frequency+1) / float(len(vocab))

#get the inverse doc freq for each token. IDF[token] contains the count of no docs that contains token
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

#tokenize, only alphabets, no stopwords, TF*IDF
def preprocTrain(Vocab_file, Tf_file, file_key):
    global MIN_FREQ
    TF = {} #gets the freq for each token
    filter_TF = {} #get the freq for each token having freq > minFreq
    feature_train = {} #final features for training class. Passed on to write ARFF files
    minFreq = MIN_FREQ
    TrainingFiles = {}


    vocabulary = pickle.load ( open(Vocab_file, "rb") )
    vocabulary = list(set(vocabulary))
    filter_TF  = pickle.load ( open(Tf_file, "rb") )

    #print "Vocab type :", type(set(vocabulary))
    totalDocs = len(filter_TF.keys())

    totalDocs = 12

    #all_vocabulary = list(set(vocabulary))
    all_vocabulary = vocabulary
    featureIDF = idf(totalDocs,filter_TF,all_vocabulary)
    pprint(TF, stream=sys.stderr)

    #calculate TF-IDF
    fileid = file_key;

    sys.stderr.write(".")
    feature_train[fileid] = {}
    for token in all_vocabulary:
        feature_train[fileid][token] = 0.0
        if featureIDF[token] > 0:
            try:
                if  filter_TF[fileid][token] > 0:
                    filter_TF[fileid][token] = filter_TF[fileid][token] * featureIDF[token]
                    feature_train[fileid][token] = filter_TF[fileid][token]
            except:
                    pass
    return feature_train,all_vocabulary

# CLI ARGS:
THRESHOLD  = int(sys.argv[1]) # Report this many top-scoring terms, per-document (int).
MIN_FREQ   = int(sys.argv[2]) # Minimum frequency of a reportable term (int).
VOCAB      = sys.argv[3]
TF         = sys.argv[4]
KEY        = sys.argv[5]

if __name__ == '__main__':
    # Split the path to extract file name
    file_key = KEY.split('/')[-1]
    (feature_tfidf,all_vocabulary) = preprocTrain(VOCAB, TF, file_key)

    #print("Document,Term,TF-IDF")
    for k,v in feature_tfidf.iteritems():
        for entry in (sorted(v.iteritems(), key=operator.itemgetter(1))[-THRESHOLD:]):
            if (float(entry[1]) > 0.0): sys.stdout.write(str(k) + "," + str(entry[0]) + "," + str(entry[1]) + "\n")
