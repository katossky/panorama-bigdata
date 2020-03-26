import json
import sseclient
import socket
import requests
    
proxies = {
 "http": "http://pxcache-02.ensai.fr:3128",
 "https": "http://pxcache-02.ensai.fr:3128",
}

def with_requests(url):
    """Get a streaming response for the given event feed using requests."""
    return requests.get(url, stream=True)

host = 'localhost'        # Symbolic name meaning all available interfaces
port = 10003     # Arbitrary non-privileged port
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host, port))
while True:
    s.listen(1)
    conn, addr = s.accept()
    print('Connected by', addr)
    url = 'https://stream.wikimedia.org/v2/stream/recentchange'
    response = with_requests(url)  # or with_requests(url)
    client = sseclient.SSEClient(response)
    for event in client.events():
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
