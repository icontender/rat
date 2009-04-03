// ActionScript file
package com.lmc.utils
{
	import com.ak33m.rpc.xmlrpc.XMLRPCObject;
	import com.lmc.events.*;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.*;
	import mx.controls.Alert;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ArrayUtil;
	
	
	[Bindable]
	public class cobblerObject extends EventDispatcher
	{
		
		 super;
		 public var distroData:ArrayCollection = new ArrayCollection();
		 public var profileData:ArrayCollection = new ArrayCollection();
		 public var userData:ArrayCollection = new ArrayCollection();
         public var systemData:ArrayCollection = new ArrayCollection();
         private var systemname:String;
         private var macaddr:String;
         private var profile:String;
         
         private var jumpstartserver:String;
         private var username:String;
         private var password:String;
         private var token:String;
         public var result:String;
         private var server:XMLRPCObject;
         
         // read only functions
            //get_distros()
			//get_profiles()
			//get_systems()
			//get_repos()
			//get_distro(name)
			//get_profile(name)
			//get_repo(name)
			//get_distro_for_koan(name)
			//get_profile_for_koan(name)
			//get_repo_for_koan(name)
			//login(self, login_user, login_password)
			//register_mac(self, mac, profile, token=None, **rest)
			
			
		public function cobblerObject(endpoint:String="http://172.16.1.53", dest:String="/cobbler_api"){
		
			super();
			server = new XMLRPCObject();
			
		    if (endpoint){ //http://ip or hostname:port
				server.endpoint = endpoint;
		    }
              // Set the destination if any  "/webservice/service.cgi"
            if (dest) {
              	server.destination = dest;
            }
            
            // if connection is good, start fetching data
            
            this.getdistros();
            this.getprofiles();
            this.getsystems();
              
		 }
			
		   
		   public function set endpoint(endp:String):void{
		       this.server.endpoint = endp;
		       
		   }
		   public function set dest(dest:String):void{
		       this.server.destination = dest;
		       
		   }
		   private function getnewtoken():void{
           	//Token times out after 30 minutes
           	this.server.login(this.username, this.password).addResponder(new ItemResponder(getnewtokenResult, faultHandler));;

           }
		   public function getsystems():void{
		     // We want to reformat the array and only get selected fields from the array
        		this.server.get_systems().addResponder(new ItemResponder(getSystemsResult, faultHandler));
		   }
		   public function getdistros():void{
		   		this.server.get_distros().addResponder(new ItemResponder(getdistrosResult, faultHandler));
		   }
		   public function getprofiles():void{
		   		this.server.get_profiles().addResponder(new ItemResponder(getprofilesResult, faultHandler));
		   }
           public function togglenetboot(value:Boolean, sid:String):void{
           		if (value){
           			server.modify_system(sid, 'netboot-enabled', true, token);
           			server.save_system(sid, token);
           		}	
           		else{
           			this.server.disable_netboot(sid, this.token);
           		}
           }
		   
           public function addsystem(name:String,mac:String, hostname:String, profile:String):void{
             var sid:String = server.new_system(token);
             server.modify_system(sid, 'name', name, token);
             server.modify_system(sid, 'hostname', name + '.localdomain', token);
             server.modify_system(sid, 'profile', profile, token);
             server.modify_system(sid, 'modify-interface', {'macaddress-eth0': mac},token);
             server.save_system(sid,token);
          		
           }
          
           public function installos(sid:String, profile:String):void{
              server.modify_system(sid, 'profile', profile, token);
              server.save_system(sid,token);
           }
           
           //////////////// Result Events ////////////////////////////////////////
           private function getSystemsResult(event:ResultEvent, token:AsyncToken = null) : void {
             this.systemData = new ArrayCollection(ArrayUtil.toArray(event.result));
           }
           private function getdistrosResult(event:ResultEvent, token:AsyncToken = null) : void {
             this.distroData = new ArrayCollection(ArrayUtil.toArray(event.result));
           }
           private function getprofilesResult(event:ResultEvent, token:AsyncToken = null) : void {
             this.profileData = new ArrayCollection(ArrayUtil.toArray(event.result));
           }
           private function getnewtokenResult(event:ResultEvent, token:AsyncToken = null) : void {
             this.token = event.result.toString();
           }	   		
           private function userResult(event:ResultEvent, token:AsyncToken = null) : void {
           		
           	     userData = new ArrayCollection( ArrayUtil.toArray(event.result)  );
           	     var sortvar:Sort = new Sort();
           		 sortvar.fields = [new SortField(null, true)];
           		 userData.sort = sortvar;
           		 userData.refresh();
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