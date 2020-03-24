import json
from sseclient import SSEClient as EventSource
import socket

host = 'localhost'        # Symbolic name meaning all available interfaces
port = 9999     # Arbitrary non-privileged port
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host, port))
while True:
    s.listen(1)
    conn, addr = s.accept()
    print('Connected by', addr)
    url = 'https://stream.wikimedia.org/v2/stream/recentchange'
    for event in EventSource(url):
        if event.event == 'message':
            try:
                change = json.loads(event.data)
                change.pop('meta', None)
                change.pop('revision', None)
                change.pop('length', None)
                change = json.dumps(change,indent=None)
                print(change)
                conn.send((str(change) + "\n").encode("utf-8"))
            except ValueError:
                pass
            except socket.error:
                print("Error Occured.")
                break

conn.close()
