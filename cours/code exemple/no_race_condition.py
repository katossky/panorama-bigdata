import threading

x = 0

def increment_global():

   global x
   x += 1

def taskofThread(lock):

   for _ in range(50000):
      lock.acquire()
      increment_global()
      lock.release()

def main():
   global x
   x = 0

   lock = threading.Lock()
   t1 = threading.Thread(target = taskofThread, args = (lock,))
   t2 = threading.Thread(target = taskofThread, args = (lock,))

   t1.start()
   t2.start()

   t1.join()
   t2.join()

if __name__ == "__main__":
   for i in range(10):
      main()
      print("x = {1} after Iteration {0}".format(i,x))

