# Streaming Client
import socket

HOST = 'localhost'
PORT = 9999

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))

while True:
    data = s.recv(1024)
    print (repr(data))

s.close()