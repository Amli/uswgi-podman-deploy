import os
import time

def application(env, start_response):
    start_response('200 OK', [('Content-Type','text/html')])
    time.sleep(0.5)
    return [os.environ.get("VERSION", "").encode("utf-8") or b"Unknow version"]
