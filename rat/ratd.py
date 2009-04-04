#!/usr/bin/python
# Author: Corey Osman
# Date: 1-21-2009
# Purpose: xmlrpc web interface for cobbler and dynacenter

# Todo:
# 1. Check to make sure all the xmlrpc services were loaded


from SimpleXMLRPCServer import SimpleXMLRPCServer
import subprocess
import os
import xmlrpclib
from usagestats import usagestats
from usagestats import stat
from cobbler import cobblermgr
from jumpstart import jumpstartmgr



# VMware information
vmserver = ''
vmuser = ''
vmpass = ''

#####################################    
class ratweb:
    cobbler = cobblermgr()
    
    # Disable to leave solaris stuff out
    jumpstartenabled = False;
    if jumpstartenabled:
        jumps = jumpstartmgr()
    
    profiles = []
    livestats = usagestats()

    SCRIPTS = '/opt/lmc/rat'
    
    def getstatistics(self, type='daily', user='all'):
        return self.livestats.getstats(type, user)
    def getjstemplates(self):
        return self.jumps.gettemplates()

    def getprofiles(self,format='flex'):
       
        cprofiles = self.cobbler.getprofiles()
        #jprofiles = self.jumps.getprofiles()
        profiles = []
        # In order for the gui to work properely I need to compile 
        # a complete list of all the OSs supported
       
        # Need to transform the following profiles into a format that the flex GUI can accept
        if format is 'flex':
            for c in cprofiles:
                profiles.append(c)
            if self.jumpstartenabled:
                for j in jprofiles:
                    profiles.append(j)
        
        if type is 'other':
            # future support for some other format
            pass

        # set this since we will need to query profiles later
        self.profiles = profiles
        return profiles

    def addsystem(self, name, mac, profileobj, user, reset_val, 
                  portgroup='\"Linux Provisioning\"'):
        # Profile Object contains the following
        #{ostype: ostype, family: family, os: os, template: template};
        template = profileobj.get('template');
        distro = profileobj.get('distro');
        ostype = profileobj.get('ostype');
        
                             
        # this is for solaris installs
        if ostype.lower().find('solaris') != -1:
            # Set the vlan for vmware
            portgroup = '\"Jumpstart\"'
            # Found a solaris profile
            if not self.jumps.addmachine(mac, distro, name, template):
                # lets not process anymore and quit
                return "false"
            # When it returns true everything went accordingly
            # add to the stats object
            p = stat({'Name':user, 'Solaris':1})
            self.livestats.updatestats(p)
    
        # this is for os that cobbler can handle (currently only linux)
        # cobbler is a little bit different so we use template instead of distro
        elif ostype.lower().find('linux') != -1:
            self.cobbler.addmachine(name,mac,template)
            self.livestats.updatestats(stat({'Name':user, 'Linux':1}))

        # future support for windows
        elif ostype.lower().find('windows') != -1:
            self.livestats.updatestats(stat({'Name':user, 'Windows':1}))
            
        #    self.cobbler.addmachine(name,mac,profile)
       
        # Reset the system if we need to
        
        if reset_val == 'true':
            self._resetsystem(mac, portgroup)
        
        # Change the vlan on the virtual machine, but don't reset the system
        elif mac.startswith('00:50:56') and reset_val != 'true':
            subprocess.Popen(self.SCRIPTS + '/getvmbymac.pl --server %s '
                             '--username %s --password %s --mac %s --portgroup %s'
                             % (vmserver, vmuser, vmpass,mac,portgroup), 
                             stdout=subprocess.PIPE, shell=True)
            
        return "none"
    def _resetsystem(self, mac, portgroup=None ):
	
	# Need to make sure we get correct esx server
        if mac.startswith('00:50:56'):
            # Reset power on virtual machine and change the vlan
            subprocess.Popen(self.SCRIPTS + '/getvmbymac.pl --server %s '
                             '--username %s --password %s --operation '
                             'reset --mac %s --portgroup %s'
                             % (vmserver, vmuser, vmpass,mac,portgroup), 
                             stdout=subprocess.PIPE, shell=True)

	return "none"

    def getcmdList(self,cmdfile):
        #somehow find out the name of the "list" that was executed
        # strip out all the newlines
        ignore_exec_globals = {}
        command_info = []
        try:
            try:
                f = open(self.SCRIPTS + '/commands/' + cmdfile, 'r')
                str = f.read()
                str = str.replace('\n','')
           
            except IOError:
                print "Error reading commands file"

        finally:
            if f:
                f.close()
       
           
            command_info = eval(str)

        return command_info 
    
    def listcmdProfiles(self):
        path= self.SCRIPTS + '/commands'
        dirlist = os.listdir(path)
        return dirlist

   

    def listsystems(self):
        return self.cobbler.getsystems()

    def listusers(self):
        # return list of users from users

        return ['cosman']
    

   

       

   


# Web Service Functions below

server = SimpleXMLRPCServer(('172.16.1.53', 9000))
server.register_instance(ratweb())
print 'Listening on port 9000'
#cacheData()
server.serve_forever()
