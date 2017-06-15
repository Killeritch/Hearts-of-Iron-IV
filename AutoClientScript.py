import subprocess
import time
import sys
import os
from array import array

### User defined values that you as user/debugger will edit.
# What lands will the clients play?
lands = ["PRU", "COL", "BOL"]

# Specify where you want the clients log folders to be created.
userdir = "C:/code/hoi4/game/logs/clients/"

# Name of the executable
exe = "hoi4_server_RD.exe"

# Ip to the standalone server (localhost should be fine)
ip = "127.0.0.1"



### Script starts
print("This script will start a host and " + str(len(lands)) + " clients." )
print("-----")
print("Starting server.")
subprocess.Popen( exe + " -enet -randomlog -hard_oos -num_clients=3" )
print("Waiting 30 seconds for host to set up server.")
time.sleep(30)
for i in range(0,len(lands)):
	time.sleep(5)
	clientdir = userdir + str(i+1)
	if not os.path.exists(clientdir):
		os.makedirs(clientdir)
	s = " -enet -randomlog -hard_oos -client -country=" + lands[i] + " -ip=" + ip + " -name=client" + str(i+1) + " -userdir=" + clientdir
	print("Starting client with argument:" + s )
	subprocess.Popen( exe + s )