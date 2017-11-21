import os

os.system('tc qdisc add dev s2-eth2 root handle 1:0 htb default 233')
os.system('tc qdisc add dev s3-eth2 root handle 1:0 htb default 233')
os.system('tc qdisc add dev s4-eth2 root handle 1:0 htb default 233')

os.system('tc class add dev s2-eth2 parent 1:0 classid 1:233 htb rate 1mbit ceil 1mbit')
os.system('tc class add dev s3-eth2 parent 1:0 classid 1:233 htb rate 1mbit ceil 1mbit')
os.system('tc class add dev s4-eth2 parent 1:0 classid 1:233 htb rate 1mbit ceil 1mbit')
