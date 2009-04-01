package com.racemi.qa.events {
    import flash.events.Event;
    
    public class ReservationSent extends Event {
        public static const SENT:String =
            "sent";
		
        public var slotid:String;
        public var template:String;
        public var user:String;
        public var sDate:Date;
        public var eDate:Date;
        public var reason:String;
        public var slotname:String;
        public var data:Date = new Date();

        public function ReservationSent(id:String, name:String, t:String=null) {
            super(SENT,true);
          //  this.user = User;
           this.slotid = id;
           this.template = t;
           this.slotname = name;
          //  this.sDate = Sdate;
          //  this.eDate = Edate;
          //  this.reason = result;
          
        }
        
    }
}