package com.racemi.qa.events {
    import flash.events.Event;
    
    public class CreateReservationEvent extends Event {
        public static const CREATE:String =
            "create reservation";

        public var slotid:String;
        public var resStatus:String;
        public var instance:String;
        public var template:String;
        public var slotname:String;
        public var desc:String;

        public function CreateReservationEvent(Slotid:String, Slotname:String, resstatus:String, description:String=null,instancename:String=null, tempname:String=null) {
            super(CREATE,true);
            this.template = tempname;
            this.slotid = Slotid;
            this.resStatus = resstatus;
            this.slotname = Slotname;
            this.instance = instancename;
            this.desc = description
            
            
            
          
        }
    }
}