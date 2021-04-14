#Copyright © 2019, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#!/usr/local/bin/python3
import sys, getopt
import http.client
import urllib
import re
import base64
import jwt

def main(argv):
   tenantId = ''
   secretKey = ''
   try:
      opts, args = getopt.getopt(argv,"ht:s:",["tenantId=","secretKey="])
   except getopt.GetoptError:
      print ('generatejwt.py -t <tenantId> -s <secretKey>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print ('generatejwt.py -t <tenantId> -s <secretKey>')
         sys.exit()
      elif opt in ("-t", "--tenantId"):
         tenantId = arg
      elif opt in ("-s", "--secretKey"):
         secretKey = arg
		 
   secretKey=bytes(secretKey,encoding='ascii')
  
   #encode the encoded secret
   encodedSecret = base64.b64encode(secretKey)
   #Generate the JWT
   token = jwt.encode({'clientID': tenantId}, encodedSecret, algorithm='HS256')
   #print (bytes.decode(token))  
   try:
      print (bytes.decode(token))
   except:
      print(token)
   

if __name__ == "__main__":
   main(sys.argv[1:])