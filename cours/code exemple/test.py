import threading
import queue

fibo_dict = {}
shared_queue = queue.Queue()
input_list = [3, 10, 5, 7]

queue_condition = threading.Condition()


def fibonacci_task(condition):
    with condition:

        while shared_queue.empty():
            print("[{}] - waiting for elements in queue..".format(threading.current_thread().name))
            condition.wait()

        else:
            value = shared_queue.get()
            a, b = 0, 1
            for item in range(value):
                a, b = b, a + b
                fibo_dict[value] = a

        shared_queue.task_done()
        print("[{}] fibonacci of key [{}] with result [{}]".
              format(threading.current_thread().name, value, fibo_dict[value]))


def queue_task(condition):
    print('Starting queue_task...')
    with condition:
        for item in input_list:
            shared_queue.put(item)

        print("Notifying fibonacci task threads that the queue is ready to consume...")
        condition.notifyAll()


threads = []
for i in range(4):
    thread = threading.Thread(target=fibonacci_task, args=(queue_condition,))
    thread.daemon = True
    threads.append(thread)

[thread.start() for thread in threads]

prod = threading.Thread(name='queue_task_thread', target=queue_task, args=(queue_condition,))
prod.daemon = True
prod.start()

[thread.join() for thread in threads]

print("[{}] - Result {}".format(threading.current_thread().name, fibo_dict))