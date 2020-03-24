import socket
from time import sleep

from reccord2 import Reccord2

host = 'localhost'        # Symbolic name meaning all available interfaces
port = 10000     # Arbitrary non-privileged port
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host, port))
while True:
    s.listen(1)
    conn, addr = s.accept()
    print('Connected by', addr)
    while True:
        try:
            json = Reccord2().toJSON()
            json = json + "\n"
            print(json)
            conn.send(json.encode("utf-8"))
        except socket.error:
            print ("Error Occured.")
            break
        sleep(0.1)


conn.close()