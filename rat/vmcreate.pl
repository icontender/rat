#!/usr/bin/perl -w
#
# Copyright (c) 2007 VMware, Inc.  All rights reserved.
#

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;
use XML::LibXML;
use AppUtil::XMLInputUtil;
use AppUtil::HostUtil;

$Util::script_version = "1.0";

my %opts = (
   filename => {
      type => "=s",
      help => "The location of the input xml file",
      required => 0,
      default => "../sampledata/vmcreate.xml",
   },
   schema => {
      type => "=s",
      help => "The location of the schema file",
      required => 0,
      default => "../schema/vmcreate.xsd",
   },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate(\&validate);

Util::connect();
create_vms();
Util::disconnect();


# This subroutine parses the input xml file to retrieve all the
# parameters specified in the file and passes these parameters
# to create_vm subroutine to create a single virtual machine
# =============================================================
sub create_vms {
   my $parser = XML::LibXML->new();
   my $tree = $parser->parse_file(Opts::get_option('filename'));
   my $root = $tree->getDocumentElement;
   my @vms = $root->findnodes('Virtual-Machine');

   foreach (@vms) {
      # default values will be used in case
      # the user do not specify some parameters
      my $memory = 256;  # in MB
      my $num_cpus = 1;
      my $guestid = 'winXPProGuest';
      my $disksize = 4096;  # in KB
      my $nic_poweron = 1;

      # If the properties are specified, the default values are not used.
      if ($_->findvalue('Guest-Id')) {
         $guestid = $_->findvalue('Guest-Id');
      }
      if ($_->findvalue('Disksize')) {
         $disksize = $_->findvalue('Disksize');
      }
      if ($_->findvalue('Memory')) {
         $memory = $_->findvalue('Memory');
      }
      if ($_->findvalue('Number-of-Processor')) {
         $num_cpus = $_->findvalue('Number-of-Processor');
      }
      if ($_->findvalue('Nic-Poweron')) {
         $nic_poweron = $_->findvalue('Nic-Poweron');
      }

      create_vm(vmname => $_->findvalue('Name'),
                vmhost => $_->findvalue('Host'),
                datacenter => $_->findvalue('Datacenter'),
                guestid => $guestid,
                datastore => $_->findvalue('Datastore'),
                disksize => $disksize,
                memory => $memory,
                num_cpus => $num_cpus,
                nic_network => $_->findvalue('Nic-Network'),
                nic_poweron => $nic_poweron);
   }
}


# create a virtual machine
# ========================
sub create_vm {
   my %args = @_;
   my @vm_devices;
   my $host_view = Vim::find_entity_view(view_type => 'HostSystem',
                                filter => {'name' => $args{vmhost}});
   if (!$host_view) {
       Util::trace(0, "\nError creating VM '$args{vmname}': "
                    . "Host '$args{vmhost}' not found\n");
       return;
   }

   my %ds_info = HostUtils::get_datastore(host_view => $host_view,
                               datastore => $args{datastore},
                               disksize => $args{disksize});

   if ($ds_info{mor} eq 0) {
      if ($ds_info{name} eq 'datastore_error') {
         Util::trace(0, "\nError creating VM '$args{vmname}': "
                      . "Datastore $args{datastore} not available.\n");
         return;
      }
      if ($ds_info{name} eq 'disksize_error') {
         Util::trace(0, "\nError creating VM '$args{vmname}': The free space "
                      . "available is less than the specified disksize.\n");
         return;
      }
   }
   my $ds_path = "[" . $ds_info{name} . "]";

   my $controller_vm_dev_conf_spec = create_conf_spec();
   my $disk_vm_dev_conf_spec =
      create_virtual_disk(ds_path => $ds_path, disksize => $args{disksize});

   my %net_settings = get_network(network_name => $args{nic_network},
                               poweron => $args{nic_poweron},
                               host_view => $host_view);
                               
   if($net_settings{'error'} eq 0) {
      push(@vm_devices, $net_settings{'network_conf'});
   } elsif ($net_settings{'error'} eq 1) {
      Util::trace(0, "\nError creating VM '$args{vmname}': "
                    . "Network '$args{nic_network}' not found\n");
      return;
   }

   push(@vm_devices, $controller_vm_dev_conf_spec);
   push(@vm_devices, $disk_vm_dev_conf_spec);

   my $files = VirtualMachineFileInfo->new(logDirectory => undef,
                                           snapshotDirectory => undef,
                                           suspendDirectory => undef,
                                           vmPathName => $ds_path);
   my $vm_config_spec = VirtualMachineConfigSpec->new(
                                             name => $args{vmname},
                                             memoryMB => $args{memory},
                                             files => $files,
                                             numCPUs => $args{num_cpus},
                                             guestId => $args{guestid},
                                             deviceChange => \@vm_devices);
                                             
   my $datacenter_views =
        Vim::find_entity_views (view_type => 'Datacenter',
                                filter => { name => $args{datacenter}});

   unless (@$datacenter_views) {
      Util::trace(0, "\nError creating VM '$args{vmname}': "
                   . "Datacenter '$args{datacenter}' not found\n");
      return;
   }

   if ($#{$datacenter_views} != 0) {
      Util::trace(0, "\nError creating VM '$args{vmname}': "
                   . "Datacenter '$args{datacenter}' not unique\n");
      return;
   }
   my $datacenter = shift @$datacenter_views;

   my $vm_folder_view = Vim::get_view(mo_ref => $datacenter->vmFolder);

   my $comp_res_view = Vim::get_view(mo_ref => $host_view->parent);

   eval {
      $vm_folder_view->CreateVM(config => $vm_config_spec,
                             pool => $comp_res_view->resourcePool);
      Util::trace(0, "\nSuccessfully created virtual machine: "
                       ."'$args{vmname}' under host $args{vmhost}\n");
    };
    if ($@) {
       Util::trace(0, "\nError creating VM '$args{vmname}': ");
       if (ref($@) eq 'SoapFault') {
          if (ref($@->detail) eq 'PlatformConfigFault') {
             Util::trace(0, "Invalid VM configuration: "
                            . ${$@->detail}{'text'} . "\n");
          }
          elsif (ref($@->detail) eq 'InvalidDeviceSpec') {
             Util::trace(0, "Invalid Device configuration: "
                            . ${$@->detail}{'property'} . "\n");
          }
           elsif (ref($@->detail) eq 'DatacenterMismatch') {
             Util::trace(0, "DatacenterMismatch, the input arguments had entities "
                          . "that did not belong to the same datacenter\n");
          }
           elsif (ref($@->detail) eq 'HostNotConnected') {
             Util::trace(0, "Unable to communicate with the remote host,"
                         . " since it is disconnected\n");
          }
          elsif (ref($@->detail) eq 'InvalidState') {
             Util::trace(0, "The operation is not allowed in the current state\n");
          }
          elsif (ref($@->detail) eq 'DuplicateName') {
             Util::trace(0, "Virtual machine already exists.\n");
          }
          else {
             Util::trace(0, "\n" . $@ . "\n");
          }
       }
       else {
          Util::trace(0, "\n" . $@ . "\n");
       }
   }
}


# create virtual device config spec for controller
# ================================================
sub create_conf_spec {
   my $controller =
      VirtualBusLogicController->new(key => 0,
                                     device => [0],
                                     busNumber => 0,
                                     sharedBus => VirtualSCSISharing->new('noSharing'));

   my $controller_vm_dev_conf_spec =
      VirtualDeviceConfigSpec->new(device => $controller,
         operation => VirtualDeviceConfigSpecOperation->new('add'));
   return $controller_vm_dev_conf_spec;
}


# create virtual device config spec for disk
# ==========================================
sub create_virtual_disk {
   my %args = @_;
   my $ds_path = $args{ds_path};
   my $disksize = $args{disksize};

   my $disk_backing_info =
      VirtualDiskFlatVer2BackingInfo->new(diskMode => 'persistent',
                                          fileName => $ds_path);

   my $disk = VirtualDisk->new(backing => $disk_backing_info,
                               controllerKey => 0,
                               key => 0,
                               unitNumber => 0,
                               capacityInKB => $disksize);

   my $disk_vm_dev_conf_spec =
      VirtualDeviceConfigSpec->new(device => $disk,
               fileOperation => VirtualDeviceConfigSpecFileOperation->new('create'),
               operation => VirtualDeviceConfigSpecOperation->new('add'));
   return $disk_vm_dev_conf_spec;
}


# get network configuration
# =========================
sub get_network {
   my %args = @_;
   my $network_name = $args{network_name};
   my $poweron = $args{poweron};
   my $host_view = $args{host_view};
   my $network = undef;
   my $unit_num = 1;  # 1 since 0 is used by disk

   if($network_name) {
      my $network_list = Vim::get_views(mo_ref_array => $host_view->network);
      foreach (@$network_list) {
         if($network_name eq $_->name) {
            $network = $_;
            my $nic_backing_info =
               VirtualEthernetCardNetworkBackingInfo->new(deviceName => $network_name,
                                                          network => $network);

            my $vd_connect_info =
               VirtualDeviceConnectInfo->new(allowGuestControl => 1,
                                             connected => 0,
                                             startConnected => $poweron);

            my $nic = VirtualPCNet32->new(backing => $nic_backing_info,
                                          key => 0,
                                          unitNumber => $unit_num,
                                          addressType => 'generated',
                                          connectable => $vd_connect_info);

            my $nic_vm_dev_conf_spec =
               VirtualDeviceConfigSpec->new(device => $nic,
                     operation => VirtualDeviceConfigSpecOperation->new('add'));

            return (error => 0, network_conf => $nic_vm_dev_conf_spec);
         }
      }
      if (!defined($network)) {
      # no network found
       return (error => 1);
      }
   }
    # default network will be used
    return (error => 2);
}


# check the XML file
# =====================
sub validate {
   my $valid = XMLValidation::validate_format(Opts::get_option('filename'));
   if ($valid == 1) {
      $valid = XMLValidation::validate_schema(Opts::get_option('filename'),
		                                      Opts::get_option('schema'));
      if ($valid == 1) {
         $valid = check_missing_value();
      }
   }
   return $valid;
}

# check missing values of mandatory fields
# ========================================
sub check_missing_value {
   my $valid = 1;
   my $filename = Opts::get_option('filename');
   my $parser = XML::LibXML->new();
   my $tree = $parser->parse_file($filename);
   my $root = $tree->getDocumentElement;
   
   # defect 223162
   if($root->nodeName eq 'Virtual-Machines') {
      my @vms = $root->findnodes('Virtual-Machine');
      foreach (@vms) {
         if (!$_->findvalue('Name')) {
            Util::trace(0, "\nERROR in '$filename':\n<Name> value missing " .
                           "in one of the VM specifications\n");
            $valid = 0;
         }
         if (!$_->findvalue('Host')) {
            Util::trace(0, "\nERROR in '$filename':\n<Host> value missing " .
                           "in one of the VM specifications\n");
            $valid = 0;
         }
         if (!$_->findvalue('Datacenter')) {
            Util::trace(0, "\nERROR in '$filename':\n<Datacenter> value missing " .
                           "in one of the VM specifications\n");
            $valid = 0;
         }
      }
   }
   else {
      Util::trace(0, "\nERROR in '$filename': Invalid root element ");
      $valid = 0;
   }
   return $valid;
}

__END__

=head1 NAME

vmcreate.pl - Creates virtual machines as per the specifications
              provided in the input XML file.

=head1 SYNOPSIS

 vmcreate.pl [options]

=head1 DESCRIPTION

This VI Perl command-line utility provides an interface for creating one
or more new virtual machines based on the parameters specified in the
input valid XML file. The syntax of the XML file is validated against the
specified schema file.

=head1 OPTIONS

=head2 GENERAL OPTIONS

=over

=item B<filename>

Optional. The location of the XML file which contains the specifications of the virtual
machines to be created. If this option is not specified, then the default
file 'vmcreate.xml' will be used from the "../sampledata" directory. The user can use
this file as a reference to create there own input XML files and specify the file's
location using the <filename> option.

=item B<schema>

Optional. The location of the schema file against which the input XML file is
validated. If this option is not specified, then the file 'vmcreate.xsd' will
be used from the "../schema" directory. This file need not be modified by the user.

=back

=head2 INPUT PARAMETERS

The parameters for creating the virtual machine are specified in an XML
file. The structure of the input XML file is:

   <virtual-machines>
      <VM>
         <!--Several parameters like machine name, guest OS, memory etc-->
      </VM>
      .
      .
      .
      <VM>
      </VM>
   </virtual-machines>

Following are the input parameters:

=over

=item B<vmname>

Required. Name of the virtual machine to be created.

=item B<vmhost>

Required. Name of the host.

=item B<datacenter>

Required. Name of the datacenter.

=item B<guestid>

Optional. Guest operating system identifier. Default: 'winXPProGuest'.

=item B<datastore>

Optional. Name of the datastore. Default: Any accessible datastore with free
space greater than the disksize specified.

=item B<disksize>

Optional. Capacity of the virtual disk (in KB). Default: 4096

=item B<memory>

Optional. Size of virtual machine's memory (in MB). Default: 256

=item B<num_cpus>

Optional. Number of virtual processors in a virtual machine. Default: 1

=item B<nic_network>

Optional. Network name. Default: Any accessible network.

=item B<nic_poweron>

Optional. Flag to specify whether or not to connect the device
when the virtual machine starts. Default: 1

=back

=head1 EXAMPLE

Create five new virtual machines as per the specification given in
the following input XML file:

 <?xml version="1.0"?>
  <Virtual-Machines>
         <Virtual-Machine>
            <Name>VirtualA1</Name>
           	<Host>111.112.111.2</Host>
            <Datacenter>Dracula</Datacenter>
           	<Guest-Id>winXPProGuest</Guest-Id>
           	<Datastore>storage1</Datastore>
           	<Disksize>4096</Disksize>
           	<Memory>256</Memory>
           	<Number-of-Processor>1</Number-of-Processor>
           	<Nic-Network>VM Network</Nic-Network>
           	<Nic-Poweron>0</Nic-Poweron>
         </Virtual-Machine>
        <Virtual-Machine>
            <Name>VirtualA2</Name>
           	<Host>111.112.111.2</Host>
            <Datacenter>Dracula</Datacenter>
           	<Guest-Id>winXPProGuest</Guest-Id>
           	<Datastore>storage1</Datastore>
           	<Disksize>4096</Disksize>
           	<Memory>256</Memory>
           	<Number-of-Processor>1</Number-of-Processor>
           	<Nic-Network>VM Network</Nic-Network>
           	<Nic-Poweron>0</Nic-Poweron>
         </Virtual-Machine>
  </Virtual-Machines>

The command to run the vmcreate script is:

  vmcreate.pl --url https://<ipaddress>:<port>/sdk/webService
              --username administrator --password mypassword
              --filename create_vm.xml --schema schema.xsd

The script will continue to create the next virtual machines even if
some previous machine creation process is failed.

The output of the above script is:

 --------------------------------------------------------------
 Successfully created virtual machine: 'VirtualA1'

 Successfully created virtual machine: 'VirtualA2'
 --------------------------------------------------------------

=head1 SUPPORTED PLATFORMS

Create operation work with VMware VirtualCenter 2.0 or later.

