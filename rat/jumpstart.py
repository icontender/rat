#!/usr/bin/python
# Author: Corey Osman
# Date: 3-19-2009

import os
import xmlrpclib


class jumpstartmgr:
    # Jumpstart Server Information
    jumpsuri = 'http://localhost:25251'
    server = None
    
    # Sparc System Registry
    # This registry is used to find out what sparc architecture to
    # use when jumpstarting a system
    # mac address: sparc arch
    sparc_reg = {'00:14:4F:2B:07:20': 'sun4v',
                 '00:14:4F:A7:46:BC': 'sun4v',
                 '00:03:BA:0D:FE:CC': 'sun4u',
                 '00:03:BA:0F:C3:7B': 'sun4u',
                 '08:00:20:C2:2C:FC': 'sun4u',
                 '08:00:20:B2:FA:6F': 'sun4u',
                 '00:03:BA:99:0E:2F': 'sun4u',
                 '00:14:4F:C3:E0:4C': 'sun4u'}


    def __init__(self):
         self.server = xmlrpclib.Server(self.jumpsuri)
  
    def addmachine(self,mac, os, hostname,template='tem_racemibase'):
        # this is for adding a client to the jumpstart server
        # the jumpstart server should have a xmlrpc server running (jswebservice.py)

        # Since I am not able to determine the arch of a sparc machine I must 
        # consult the sparc registry
        # If the mac is not in the registry than the default arch is i86pc
        arch = self.sparc_reg.get(mac.upper(),'i86pc')
        try:
            self.server.addclient(mac, os, hostname, arch, template)
        except xmlrpclib.ProtocolError, err:
            print "Can't connect to the server"
            return err

        
        return True
    def getprofiles(self):
        try:
            values = self.server.listprofiles()
        except xmlrpclib.ProtocolError, err:
            print "Can't connect to the server"
            return err
        return values
    

    def gettemplates(self):
        try:
            values = self.server.listtemplates()
        except xmlrpclib.ProtocolError, err:
            print "Can't connect to the server"
            return err
        return values
