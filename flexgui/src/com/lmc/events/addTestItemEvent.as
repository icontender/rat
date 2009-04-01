package com.racemi.qa.events {
    import flash.events.Event;
    
    public class addTestItemEvent extends Event {
        public static const ADDTESTITEM:String = "Add Test Item";
            
        
        public static const CREATEDISPLAY:String = "Create Display";
        
        public var command:String;
        public var os:String;
        public var system:String;
        public var version:String;
        public var itemname:String;

        public function addTestItemEvent(command:String, os:String, system:String, version:String, itemname:String=" ") {
            super(ADDTESTITEM,true);
            this.command = command;
            this.os = os;
            this.system = system;
            this.version = version;
            this.itemname = itemname;
             
          
        }
    }
}