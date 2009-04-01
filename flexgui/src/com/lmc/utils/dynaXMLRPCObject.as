package com.racemi.qa.utils
{
	import com.ak33m.rpc.xmlrpc.XMLRPCObject;
	import com.racemi.qa.events.*;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ItemResponder;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ArrayUtil;
	import mx.collections.*;
           
    [Bindable]
	public class dynaXMLRPCObject extends Object
	{
		
		super;
		 public var stats:ArrayCollection = null
		 public var userData:ArrayCollection = null;
         public var slotData:ArrayCollection = null;
         public var templateData:ArrayCollection = null;
         public var jstemplates:ArrayCollection = null;
         
         public var profiles:ArrayCollection = new ArrayCollection();
         // cmdproifles holds all the command profiles that were found
         public var cmdprofiles:ArrayCollection;
           //cmdlist holds all the commands and args from the selected profile
         public var cmdlist:ArrayCollection;
           // holds the names of just the commands (no args) gathered form the loaded profile
         public var commands:ArrayCollection = new ArrayCollection();
           
         private var slotname:String;
         private var slotid:String;
         private var macaddr:String;
         private var profile:String;
       
         public var result:String;
        
        
        private var methodname:String;
        private var server:XMLRPCObject;
		public function dynaXMLRPCObject(endpoint:String="http://192.168.1.82:8889", dest:String="/rattwebservice")
		{
			super();
			server = new XMLRPCObject();
		    
		    
		    
			server.endpoint = endpoint;
              // Set the destination if any  "/webservice/service.cgi"
              if (dest) {
              	server.destination = dest;
              }
              
           // cache the data   
           this.getslots(); 
           this.getusers();
           // Can no longer get this data upfront due to the slotid requirement
           //this.gettemplates();
           this.getprofiles();
           this.getjstemplates();
           
           
             
             
		}
		
		
		   public function getslots():void{
		   	    this.methodname = "listslots";
		   	    server.listslots().addResponder(new ItemResponder(slotResult, faultHandler));
		   	    
           }
           
		   public function getusers():void{
		   	    this.methodname = "listusers";
		   	    server.listusers().addResponder(new ItemResponder(userResult, faultHandler));
		   		
           }
           public function getprofiles():void{
		   	    this.methodname = "getprofiles";
		   	    server.getprofiles().addResponder(new ItemResponder(profileResult, faultHandler));
		   		
           }
           public function getstatistics(type:String='daily'):void{
           		server.getstatistics(type).addResponder(new ItemResponder(statResult, faultHandler));
           }
		   public function gettemplates(slotid:String):void{
		   	    this.methodname = "listtemplates";
		   	    
		   	    server.listtemplates(slotid).addResponder(new ItemResponder(templateResult, faultHandler));
           	   
           }
           public function assignslot(slotid:Array, template:String, desc:String="none"):void{
           	
           		server.assignslot(slotid, template, desc).addResponder(new ItemResponder(assignslotResult, faultHandler));
           }
           public function releaseslot(slotid:String):void{
           		server.releaseslot(slotid).addResponder(new ItemResponder(releaseResult, faultHandler));
           }
           public function addsystem(slotname:String,macaddr:String, profileobj:Object, user:String, reset:String, slotid:String):void{
          		// the profileobj contains a number of items (profile, template, os, osfamily)
          		this.slotname = slotname;
          		this.macaddr = macaddr;
          		//this.profile = profile;
          		
          		server.addsystem(slotname,macaddr, profileobj, user, reset, ArrayUtil.toArray(slotid)).addResponder(new ItemResponder(addSystemResult, faultHandler));
          		
           }
           public function getjstemplates():void{
           		server.getjstemplates().addResponder(new ItemResponder(getjstemplatesResult, faultHandler));
           }
           public function listcmdProfiles():void{
           		server.listcmdProfiles().addResponder(new ItemResponder(cmdprofileResult, faultHandler));
           }
           public function getcmdList(version:String):void{
           		server.getcmdList(version).addResponder(new ItemResponder(cmdListResult, faultHandler));
           }
           
           //////////////// Result Events ////////////////////////////////////////
           
           private function templateResult(event:ResultEvent, token:AsyncToken = null) : void {
           	     templateData = new ArrayCollection( ArrayUtil.toArray(event.result)  );
           }
           private function getjstemplatesResult(event:ResultEvent, token:AsyncToken = null) : void {
           		jstemplates = new ArrayCollection( ArrayUtil.toArray(event.result)  );
           }	   		
           private function userResult(event:ResultEvent, token:AsyncToken = null) : void {
           		
           	     userData = new ArrayCollection( ArrayUtil.toArray(event.result)  );
           	     var sortvar:Sort = new Sort();
           		 sortvar.fields = [new SortField(null, true)];
           		 userData.sort = sortvar;
           		 userData.refresh();
           }	   			
           private function slotResult(event:ResultEvent, token:AsyncToken = null) : void {	   	
           	     slotData = new ArrayCollection( ArrayUtil.toArray(event.result)  );
           	   	
           }
           private function assignslotResult(event:ResultEvent, token:AsyncToken = null) : void {    
              	
              	// reload the data (update it)
              	this.result = event.result.toString();
              	Application.application.dispatchEvent(new ReservationCreated(event.result.toString()));
                this.getslots();
              	
           }
           private function releaseResult(event:ResultEvent, token:AsyncToken = null) : void {    
              	Application.application.dispatchEvent(new ReservationCreated(event.result.toString()));
              	
              	this.result = event.result.toString();
              	// reload the data (update it)
              	this.getslots();
              	//Alert.show("Slot was released" + event.result.toString());
           }
           private function profileResult(event : ResultEvent, token : AsyncToken = null) : void {
              // comes back pre sorted and if cobbler has enabled=false, those items will not be available
              this.profiles = new ArrayCollection(ArrayUtil.toArray( event.result ) );
              
              
           }
           private function addSystemResult(event:ResultEvent, token : AsyncToken = null) : void {
           		var register:String = new String(event.result.toString());
           		// If result is true, then it was successful
           		if (register){
           			Alert.show(slotname + " was registered, please PXE boot the machine");
           		
           		}
           		else {
           			Alert.show(slotname + " failed to register with error code " + register);
           		}
           }
           private function cmdprofileResult(event : ResultEvent, token : AsyncToken = null) : void {
              // gets a directory listing of ./commands which should be the command profiles
              // each command profile has a list of commands that will be loaded once the user picks the profile
              cmdprofiles = new ArrayCollection(ArrayUtil.toArray( event.result ) );
              
            }
            private function cmdListResult(event : ResultEvent, token : AsyncToken = null) : void {
              
              cmdlist = new ArrayCollection(ArrayUtil.toArray( event.result ) );
              for each (var item:Array in cmdlist){
             	commands.addItem(item[0]);
               }
			
            }
            private function statResult(event : ResultEvent, token : AsyncToken = null) : void {
            	stats = new ArrayCollection(ArrayUtil.toArray( event.result ) );
            }
          
           
           
           
           
           //////////////// Result Events ////////////////////////////////////////
           private function faultHandler (event:FaultEvent,token:AsyncToken = null) : void {
            Alert.show(event.fault.faultString, event.fault.faultCode);
           } 
		
	}
}