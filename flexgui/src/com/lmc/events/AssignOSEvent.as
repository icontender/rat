package com.racemi.qa.events {
    import flash.events.Event;
    
    public class AssignOSEvent extends Event {
        public static const ASSIGNOS:String =
            "Assign OS";

        public var slotid:String;
        public var resStatus:String;
        public var instance:String;
        public var template:String;
        public var slotname:String;
        public var macaddr:String;
        public var profile:String;
        public var user:String;

        public function AssignOSEvent(Slotname:String, mac:String, slot:String, user:String, profile:String=null) {
            super(ASSIGNOS,true);
           
            this.profile = profile;
            this.slotname = Slotname;
            this.slotid = slot;
            this.macaddr = mac;
            this.user = user;
            
            
            
          
        }
    }
}