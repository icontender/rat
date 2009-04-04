package com.lmc.events {
    import flash.events.Event;
    
    public class deployOSEvent extends Event {
        public static const DEPLOYOS:String =
            "Deploy OS";

       
      
        public var systemname:String;
        public var macaddr:String;
        public var profile:String;
        
        public function deployOSEvent(systemname:String, mac:String,profile:String=null) {
            super(DEPLOYOS,true);
           
            this.profile = profile;
            this.systemname = systemname;
            
            this.macaddr = mac;
            
            
            
            
          
        }
    }
}