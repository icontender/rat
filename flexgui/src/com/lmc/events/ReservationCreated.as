package com.racemi.qa.events {
    import flash.events.Event;
    
    public class ReservationCreated extends Event {
        public static const CREATED:String = "created reservation";
          
        public var result:String = "";

        public function ReservationCreated(r:String) {
            super(CREATED,true);
          //  this.user = User;
          //  this.slotid = Slotid;
          //  this.template = Template;
          //  this.slotname = Slotname;
          //  this.sDate = Sdate;
          //  this.eDate = Edate;
          //  this.reason = result;
          this.result = r;
          
        }
        
    }
}