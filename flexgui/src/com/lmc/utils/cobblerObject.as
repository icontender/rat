// ActionScript file
package com.lmc.utils
{
	import com.ak33m.rpc.xmlrpc.XMLRPCObject;
	import com.lmc.events.*;
	import mx.collections.*;
	import mx.controls.Alert;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ArrayUtil;
	import flash.events.EventDispatcher;
	
	
	[Bindable]
	public class cobblerObject extends EventDispatcher
	{
		
		 super;
		 public var distroData:ArrayCollection = null;
		 public var profiles:ArrayCollection = new ArrayCollection();
		 public var userData:ArrayCollection = null;
         public var systemData:ArrayCollection = null;
         private var systemname:String;
         private var macaddr:String;
         private var profile:String;
         private var cobblerserver:String;
         private var jumpstartserver:String;
         
         public var result:String;
         private var server:XMLRPCObject;
		public function cobblerObject(endpoint:String="http://172.16.1.53:9000", dest:String="/"){
		
			super();
			server = new XMLRPCObject();
		    if (endpoint){
				server.endpoint = endpoint;
		    }
              // Set the destination if any  "/webservice/service.cgi"
            if (dest) {
              	server.destination = dest;
            }
              
		 }
		
		   public function set endpoint(endp:String):void{
		       this.server.endpoint = endp;
		       
		   }
		   public function set dest(dest:String):void{
		       this.server.destination = dest;
		       
		   }
		   
		   public function getsystems():void{
		   	    
		   	    server.getsystems().addResponder(new ItemResponder(systemsResult, faultHandler));
		   	    
           }
           
		   public function getusers():void{
		   	    
		   	    server.listusers().addResponder(new ItemResponder(userResult, faultHandler));
		   		
           }
           public function getprofiles():void{
		   	    
		   	    server.getprofiles().addResponder(new ItemResponder(profileResult, faultHandler));
		   		
           }
          
		   
           public function addsystem(systemname:String,macaddr:String, profileobj:Object, user:String, reset:String):void{
          		// the profileobj contains a number of items (profile, template, os, osfamily)
          		this.systemname = systemname;
          		this.macaddr = macaddr;
          		//this.profile = profile;
          		
          		server.addsystem(systemname,macaddr, profileobj, user, reset).addResponder(new ItemResponder(addSystemResult, faultHandler));
          		
           }
           
           
           //////////////// Result Events ////////////////////////////////////////
           
          
           	   		
           private function userResult(event:ResultEvent, token:AsyncToken = null) : void {
           		
           	     userData = new ArrayCollection( ArrayUtil.toArray(event.result)  );
           	     var sortvar:Sort = new Sort();
           		 sortvar.fields = [new SortField(null, true)];
           		 userData.sort = sortvar;
           		 userData.refresh();
           }	   			
           private function systemsResult(event:ResultEvent, token:AsyncToken = null) : void {	   	
           	     systemData = new ArrayCollection( ArrayUtil.toArray(event.result)  );
           	   	
           }
           
           private function profileResult(event : ResultEvent, token : AsyncToken = null) : void {
              // comes back pre sorted and if cobbler has enabled=false, those items will not be available
              this.profiles = new ArrayCollection(ArrayUtil.toArray( event.result ) );
              
              
           }
           private function addSystemResult(event:ResultEvent, token : AsyncToken = null) : void {
           		var register:String = new String(event.result.toString());
           		// If result is true, then it was successful
           		if (register){
           			Alert.show(systemname + " was registered, please PXE boot the machine");
           		
           		}
           		else {
           			Alert.show(systemname + " failed to register with error code " + register);
           		}
           }
           
           
           
           
           //////////////// Result Events ////////////////////////////////////////
           private function faultHandler (event:FaultEvent,token:AsyncToken = null) : void {
            Alert.show(event.fault.faultString, event.fault.faultCode);
           } 
		
}
}