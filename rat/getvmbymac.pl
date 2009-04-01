#!/usr/bin/perl -w
#Author: Corey Osman corey@logicminds.biz
#Date: 1-27-09
#Purpose: powers on/off a vm given a mac address
#Additional: can also switch the portgroup 
########################################################
# Todo: add setOSOption function

# Import runtime libraries
use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;

my %opts = (
   'vmname' => {
      type => "=s",
      help => "The name of the virtual machine",
      required => 0,
   }, 
   'mac' => {
      type => "=s",
      help => "The mac address of the virtual machine",
      required => 0,
   },
   'portgroup' => {
      type => "=s",
      help => "The portgroup you wish to change too for kickstarting",
      required => 0,
   },
   'operation' => {
      type => "=s",
      help => "values are on, off,prep, reset",
      required => 0,
   }

);

# VMware virtual ethernet card types
my %text = (
    VirtualE1000 => 'E1000',
    VirtualPCNet32 =>  'PC Net 32',
    VirtualVMXnet => 'vmx net');


# Read and validate command-line parameters
Opts::add_options(%opts);
Opts::parse();
Opts::validate();

# Get any arguments passed in
my $vm_name = Opts::get_option('vmname');
my $mac = Opts::get_option('mac');
my $portgroupname = Opts::get_option('portgroup');
my $operation = Opts::get_option('operation');

# change mac to lower case because vmware returns all lowercase mac addresses
$mac = lc($mac);

# change the operation to lowercase
$operation = lc($operation);

# Connect to the server and login
Util::connect();

# start Here
my $vms = GetVm();
my $foundvm = findVMbyMac($vms, $mac);


# change the vlan if you need to 
if ($portgroupname){
     changevlan($foundvm,$portgroupname);
}

# power on the system
if ($operation eq "on"){
     powerON($foundvm);
}

# power off the system
elsif ($operation eq "off"){
     powerOFF($foundvm);
}

# reset the system
# this will either poweron the system or reset it
elsif ($operation eq "reset"){
     resetvm($foundvm);
}
elsif ($operation eq "scott"){
     printstuff($vms);
}

# Close server connection
Util::disconnect();

##############################################################################
sub printstuff{
   my $vmlist = shift;
   my $vm = "";
   foreach $vm (@$vmlist) {
        my $vmmac = getmac($vm);
        print $vm->name . " mac address =  " . $vmmac . " state =  " . $vm->runtime->powerState->val . " \n";

   }
}



sub powerON{
# requires mac address and list of vms (but these are global anyways)
         my $vm = shift;
	my $state = $vm->runtime->powerState->val;
        if ($state eq "poweredOff"){
        	 print "Powering on ...\n";
        	 $vm->PowerOnVM();
	}

}

sub powerOFF{
# requires ddmac address and list of vms (but these are global anyways)
        my $vm = shift;
	my $state = $vm->runtime->powerState->val;
	if ($state eq "poweredOn"){
         	print "Powering off ...\n";
        	 $vm->PowerOffVM();
	}
	 # this is not a shutdown but a complete "flip the switch" event

}

sub GetVm {
   my $vmname = shift;
   return Vim::find_entity_views(
             view_type => 'VirtualMachine');
          #   filter => {
          #   'name' => $vmname }
          #   );
	  # Damn, it would be nice to filter by mac address, but we can't since 
	  # having a network card is a enumerated device
}

sub findVMbyMac {
# requires a list of vms and the mac address to search for

   my $vms = shift;
   my $mac = shift;
   my $vm = "";
   foreach $vm (@$vms) {
        my $vmmac = getmac($vm);
#        print $vmmac . " = " . $mac . "\n";
   	if ($vmmac eq $mac){
#        	print "Found " . $mac . " that belongs to " . $vm->name . "\n";
		return $vm;
	}
   }
}


sub resetvm {
# this will determine if the vm needs to be reset or powered on
# this will detect if the vm is on or off by looking at the power state
my $vm = shift;
#print $vm->name . " ";
if (! $vm){
	print "VM with mac address " . $mac . " is not defined";
}
my $state = $vm->runtime->powerState->val;
if ($state eq "poweredOff"){
         print "Powering On ...\n";
         $vm->PowerOnVM();
}
elsif ($state eq "poweredOn"){
         print "Resetting ...\n";
         $vm->ResetVM();
}
#  This will occur if its in a hibernated state
else 
         {print $state . "\n"}
}

sub getmac{
my $vm = shift;
#print $vm->name . " ";
my $firstnic = "Network Adapter 1";
my $devices = $vm->config->hardware->device;
foreach my $dev (@$devices) {
    next unless ($dev->isa ("VirtualEthernetCard"));
    if ($dev->deviceInfo->label eq $firstnic){
	return $dev->macAddress;
    }
	
    }
}
#sub getnetworks{
#  Have not been able to find the proper "managed entitiy name"
#  This will enventually get all the available portgroups
#   return Vim::find_entity_views(
#             view_type => 'network');
          #   filter => {
          #   'name' => $vmname }
          #   );
#}

#sub listnetworks{
#	my $nets = getnetworks();
#        foreach my $net (@$nets){
#            print $net->name;
#	}
#}

sub changevlan {
# changes the vlan of the vm.  must be called via changevlan(vm, new port group name) 
	my $vm = shift;
        my $new_net_name = shift;
        # my $new_net_name = "new port group";
	my $net_name = "Network Adapter 1";
        my $net_device = " ";
        my $config_spec_operation = VirtualDeviceConfigSpecOperation->new('edit');
	my $devices = $vm->config->hardware->device;
        foreach my $device (@$devices){
        	if ($device->deviceInfo->label eq $net_name){
                	$net_device=$device;
		}
	}

	if ($net_device){
		$net_device->deviceInfo->summary( $new_net_name);
		$net_device->backing->deviceName( $new_net_name);
	}

	my $vm_dev_spec = VirtualDeviceConfigSpec->new(
         device => $net_device,
         operation => $config_spec_operation
	   );

  	 my $vmSwitchspec = VirtualMachineConfigSpec->new(deviceChange => [ $vm_dev_spec ] );

  	 eval{
     		 $vm->ReconfigVM(spec => $vmSwitchspec);
  	 };
 	  if ($@) { print "Reconfiguration failed.\n $@";}
    	  else {print "Reconfig vSwitch OK.\n"; }
}
########################################################################################
