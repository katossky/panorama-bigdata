import sys
from random import random
from operator import add

from pyspark import SparkContext


if __name__ == "__main__":
    sc = SparkContext(appName="word_count")
   
    print(sc.textFile("s3://gdelt-open-data/events/2016*").count())
    print(sc.textFile("s3://gdelt-open-data/events/2016*").first())

    sc.stop()