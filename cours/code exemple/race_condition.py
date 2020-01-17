import threading

def taskofThread():

   for _ in range(500000):

      increment_global()


def increment_global():

   global x
   x += 1

def main():
    global x
    x = 0

    t1 = threading.Thread(target= taskofThread)
    t2 = threading.Thread(target= taskofThread)

    t1.start()
    t2.start()

    t1.join()
    t2.join()

if __name__ == "__main__":
    for i in range(10):
        main()
        print("x = {1} after Iteration {0}".format(i,x))