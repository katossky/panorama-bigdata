from threading import Thread
import concurrent.futures
import time
import logging
import Queue
logging.basicConfig(level=logging.DEBUG)

class ThreadFibonacci (Thread):
    def __init__(self, n, queue_current):
        logging.info(
            'Création du thread pour le calcul de Fibonacci %s' % (n,))
        Thread.__init__(self)
        self.n = n
        self.queue_current = queue_current
        self.queue_next = Queue.Queue()

    def run(self):
        if self.n < 2:
            return 1
        else:
            thread_fib_1 = ThreadFibonacci(self.n-1,self.queue_next)
            thread_fib_2 = ThreadFibonacci(self.n-2,self.queue_next)

            x = thread_fib_1.start()
            y = thread_fib_2.start()
            thread_fib_1.join()
            thread_fib_2.join()

            logging.info('Fin du calcul de Fibonacci %s' % (self.n,))

            return x+y


for i in range(1, 10):
    print("iteration %s : valeur : %s" % (i, ThreadFibonacci(i).run()))
