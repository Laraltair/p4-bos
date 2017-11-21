import os

os.system('sudo /home/wu/behavioral-model/targets/simple_switch/simple_switch_CLI --thrift-port=9090 < /home/wu/burst_offloading/cmd_9090.txt')
os.system('sudo /home/wu/behavioral-model/targets/simple_switch/simple_switch_CLI --thrift-port=9091 < /home/wu/burst_offloading/cmd_inport.txt')
os.system('sudo /home/wu/behavioral-model/targets/simple_switch/simple_switch_CLI --thrift-port=9092 < /home/wu/burst_offloading/cmd_inport.txt')
os.system('sudo /home/wu/behavioral-model/targets/simple_switch/simple_switch_CLI --thrift-port=9093 < /home/wu/burst_offloading/cmd_inport.txt')
os.system('sudo /home/wu/behavioral-model/targets/simple_switch/simple_switch_CLI --thrift-port=9094 < /home/wu/burst_offloading/cmd_9094.txt')