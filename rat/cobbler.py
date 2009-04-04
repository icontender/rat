#!/usr/bin/python
# Author: Corey Osman
# Date: 3-19-2009
# Purpose: cobbler xmlrpc web interface for RAT



import os
import xmlrpclib
class cobblermgr (object):
    # Cobbler Server Information
    uri = 'http://172.16.1.53/cobbler_api'
    server = None
    testuser = 'admin'
    testpass = 'password'
    token = ''
    distros = {}
    profiles = {}
    
    def __init__(self):
        self.server = xmlrpclib.Server(self.uri)
    def _getnewtoken(self):
        #token times out after 30 minutes
        try: 
            self.token =  self.server.login(self.testuser,self.testpass)
        except xmlrpclib.ProtocolError, err:
            print "Can't connect to the server"
            return err
        
        return True

    def getsystems(self):
        # We might want to reformat the array and only get specific items from the array
        return self.server.get_systems();
    def getprofiles(self):
        
        # need to format the profiles
        return self._getchildren()

    def getdistros(self):
        try:
            self.distros = self.server.get_distros()
        except xmlrpclib.ProtocolError, err:
            print "Can't connect to the server"
            return err
        
        return self.distros

    def _getarch(self,dname):
        if self.distros:
            for d in self.distros:
                if d['name'] is dname:
                    return d['arch']
                else:
                    return 'none'

    def _getbreed(self,dname):
        if self.distros:
            for d in self.distros:
                if d['name'] is dname:
                    return d['breed']
                else:
                    return 'none'

    def _getchildren(self):
        items = []
        familyname = ''
        familyvers = ''
        # get the latest profiles
        try:
            self.profiles = self.server.get_profiles()
        except xmlrpclib.ProtocolError, err:
            print "Can't connect to the server"
            return err
        
        # get the latest distros
        self.getdistros()       
        for p in self.profiles:
            if p['enable_menu'] != 'True':
                continue
            distroname = p['distro']
            arch = self._getarch(distroname)
            breed = self._getbreed(distroname)
            name = p['name']

            if name.lower().find('centos') is not -1:
               familyname = 'CentOS'
            elif name.lower().find('rhel') is not -1:
               familyname = 'RHEL'
            elif name.lower().find('sles') is not -1:
               familyname = 'SLES'
            else:
               familyname = 'Other'

            item = {'name': p['name'], 'arch': arch, 'breed': breed,
                    'distro': p['distro'], 'ostype': 'Linux', 'familyname': familyname,
                    'familyvers': p['name']}
            items.append(item)

        return items


    def addmachine(self, name, mac,profile):
         self._getnewtoken()
         # lets try and remove the system first just in case it already exists
         try:
             self.server.remove_system(name,self.token)
         except:
             pass
         try:
            
             sid = self.server.new_system(self.token)
             self.server.modify_system(sid, 'name', name, self.token)
             self.server.modify_system(sid, 'hostname', name + '.localdomain', self.token)
             self.server.modify_system(sid, 'profile', profile, self.token)
             self.server.modify_system(sid, 'modify-interface', {'macaddress-eth0': mac},self.token)
             code = self.server.save_system(sid,self.token)
         except xmlrpclib.ProtocolError, err:
             print "Can't connect to the server"
             return err
         return True
