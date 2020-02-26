# Author: Gael Varoquaux <gael dot varoquaux at normalesup dot org>
#         Andreas Mueller <amueller@ais.uni-bonn.de>
# License: BSD 3 clause

print(__doc__)

# Standard scientific Python imports
import matplotlib.pyplot as plt
import numpy as np
from time import time

# Import datasets, classifiers and performance metrics
from sklearn import datasets, svm, pipeline
from sklearn.kernel_approximation import (RBFSampler,
                                          Nystroem)
from sklearn.decomposition import PCA

# The digits dataset
digits = datasets.load_digits(n_class=9)

n_samples = len(digits.data)
data = digits.data / 16.
data -= data.mean(axis=0)

# We learn the digits on the first half of the digits
data_train, targets_train = (data[:n_samples // 2],
                             digits.target[:n_samples // 2])


# Now predict the value of the digit on the second half:
data_test, targets_test = (data[n_samples // 2:],
                           digits.target[n_samples // 2:])
# data_test = scaler.transform(data_test)

# Create a classifier: a support vector classifier
kernel_svm = svm.SVC(gamma=.2)
linear_svm = svm.LinearSVC()




linear_svm_sizes_sample = []
linear_svm_times = []
linear_svm_scores = []

kernel_svm_times = []
kernel_svm_scores = []

for i in range(10,1,-1):
    sample_size = (n_samples//2)//i
    linear_svm_sizes_sample.append(sample_size)

    data_train_temp, targets_train_temp = (data_train[:sample_size],
                                           targets_train[:sample_size])
    # Linear svm
    linear_svm_time = time()
    linear_svm.fit(data_train_temp, targets_train_temp)
    linear_svm_time = time() - linear_svm_time
    linear_svm_times.append(linear_svm_time)

    linear_svm_score = linear_svm.score(data_test, targets_test)
    linear_svm_scores.append(linear_svm_score)

    # kernel svm
    kernel_svm_time = time()
    kernel_svm.fit(data_train_temp, targets_train_temp)
    kernel_svm_time = time() - kernel_svm_time
    kernel_svm_times.append(kernel_svm_time)

    kernel_svm_score = kernel_svm.score(data_test, targets_test)
    kernel_svm_scores.append(kernel_svm_score)


# plot the results:
plt.figure(figsize=(16, 4))
accuracy = plt.subplot(121)
# second y axis for timings
timescale = plt.subplot(122)

accuracy.plot(linear_svm_sizes_sample, linear_svm_scores, label="SVM linéaire")
accuracy.plot(linear_svm_sizes_sample, kernel_svm_scores, label="SVM à noyaux")

timescale.plot(linear_svm_sizes_sample, linear_svm_times, '--',
               label="SVM linéaire")
timescale.plot(linear_svm_sizes_sample, kernel_svm_times, '--',
               label="SVM à noyaux")

# legends and labels
accuracy.set_title("Classification accuracy")
timescale.set_title("Training times")
accuracy.set_xlim(linear_svm_sizes_sample[0], linear_svm_sizes_sample[-1])
accuracy.set_xlabel("Size of the data sample")

accuracy.set_xticks(())
#accuracy.set_ylim(np.min(fourier_scores), 1)
timescale.set_xlabel("Size of the data sample")
accuracy.set_ylabel("Classification accuracy")
timescale.set_ylabel("Training time in seconds")
accuracy.legend(loc='best')
timescale.legend(loc='best')
plt.tight_layout()
plt.show()