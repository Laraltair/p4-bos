import os
import time


def token_rewrite():
    os.system('sudo /home/wu/behavioral-model/targets/simple_switch/simple_switch_CLI --thrift-port=9090 < /home/wu/burst_offloading/cmd_rewrite_token.txt')
    time.sleep(1)

if __name__ == '__main__':
    while(True):
        token_rewrite()
        print "rewrite one time"