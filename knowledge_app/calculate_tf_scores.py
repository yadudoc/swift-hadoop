#!/usr/bin/env python
import os
import sys
import traceback
import csv
import re
import math
import string
import operator
import nltk
import pickle
from pprint import pprint
from nltk.corpus import PlaintextCorpusReader
from nltk.corpus import stopwords

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
def preprocTrain(corpus, tf_file, vocab_file):
    global MIN_FREQ
    stopwds = stopwords.words('english')

    TF = {} #gets the freq for each token
    filter_TF = {} #get the freq for each token having freq > minFreq
    feature_train = {} #final features for training class. Passed on to write ARFF files
    vocabulary = []
    ctDocs = {}
    totalDocs = 0
    minFreq = MIN_FREQ
    TrainingFiles = {}

    #loading our corpus
    corpus_root=corpus
    wordlists = PlaintextCorpusReader(corpus_root, '.*')
    ctDocs = len(wordlists.fileids()) #total no of files in each class
    totalDocs = ctDocs + totalDocs #total no of files
    TrainingFiles = wordlists.fileids() #contains files for each class

    sys.stderr.write("Reading corpus")
    for fileid in wordlists.fileids():
        sys.stderr.write(".")

        raw = wordlists.raw(fileid)
        tokens = nltk.word_tokenize(raw)
        text = nltk.Text(tokens)

        words = [w.lower() for w in text if w.isalnum() and w.lower() not in stopwds and len(w) > 3]
        vocab = set(words)
        words = nltk.Text(words)

        #calculate TF
        TF[fileid] = {fileid:fileid}
        filter_TF[fileid] = {fileid:fileid}
        for token in vocab:
            TF[fileid][token] = freq(token, words)

            if TF[fileid][token] > minFreq:  #min feature freq.
                vocabulary.append(token)
                filter_TF[fileid][token] = tf(TF[fileid][token],words)

    pickle.dump(filter_TF, open(tf_file, "wb"));
    sys.stderr.write("done\nCalculating TF*IDF scores")
    all_vocabulary = list(set(vocabulary))
    pickle.dump(all_vocabulary, open(vocab_file, "wb"));
    #featureIDF = idf(totalDocs,filter_TF,all_vocabulary)
    pprint(TF, stream=sys.stderr)

# CLI ARGS:
CORPUS_DIR = sys.argv[1]      # Path to a directory of txt documents.
THRESHOLD  = int(sys.argv[2]) # Report this many top-scoring terms, per-document (int).
MIN_FREQ   = int(sys.argv[3]) # Minimum frequency of a reportable term (int).
TF_FILE    = sys.argv[4]
VOCAB_FILE = sys.argv[5]

if __name__ == '__main__':
    preprocTrain(CORPUS_DIR, TF_FILE, VOCAB_FILE)
