package com.lmc.events {
    import flash.events.Event;
    
    public class AssignOSEvent extends Event {
        public static const ASSIGNOS:String =
            "Assign OS";

       
      
        public var systemname:String;
        public var macaddr:String;
        public var profile:String;
        
        public function AssignOSEvent(systemname:String, mac:String,profile:String=null) {
            super(ASSIGNOS,true);
           
            this.profile = profile;
            this.systemname = systemname;
            
            this.macaddr = mac;
            
            
            
            
          
        }
    }
}