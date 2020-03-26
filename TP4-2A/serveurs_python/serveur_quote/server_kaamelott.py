import codecs
import socket
from time import sleep

host = 'localhost'        # Symbolic name meaning all available interfaces
port = 10001     # Arbitrary non-privileged port
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host, port))
while True:
    s.listen(1)
    conn, addr = s.accept()
    print('Connected by', addr)
    with codecs.open("quote.json", "r", "utf-8") as file:
        while True:
            try:
                json = file.readline()
                print(json)
                conn.send(json.encode("utf-8"))
            except socket.error:
                print ("Error Occured.")
                break
            sleep(0.1)


conn.close()