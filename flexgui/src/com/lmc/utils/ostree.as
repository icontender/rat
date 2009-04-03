package com.lmc.utils
{
	public class ostree extends Object
	{
		import flash.utils.Dictionary;
		import mx.collections.ArrayCollection;
		[Bindable] public var breeds:Array = new Array();
		[Bindable] public var distros:Array = new Array();
		[Bindable] public var profiles:Array = new Array();
		
		
		public function ostree()
		{
			//TODO: implement function
			super();
		}
		public function getdistros(breed:String):ArrayCollection{
			var data:ArrayCollection = new ArrayCollection;
			for each (var d in distros){
				if (d.breed == breed){
					data.addItem(d);
				}
			}
			return data;
		}
		public function getprofiles(distro:String):ArrayCollection{
			var data:ArrayCollection = new ArrayCollection;
			for each (var p in profiles){
				if (p.distro == distro){
					data.addItem(p);
				}
			}
			return data;
		}
		private function search(data:Array, value:String, field:String):Boolean{
			
			for each (var b in data){
					if (b[field] == value){
						return true;
					}
			}
			return false;
		}
		public function addos(data:Object):void{
			var breed:String = data['breed'];
			var distro:String = data['distro'];
			var arch:String = data['arch'];
			var version:String = data['version'];
			var profile:String = data['profile'];
			var comment:String = data['comment'];
			
			
				if (! search(breeds, breed, 'name'))
					breeds.push({'name':breed});
			
				if (! search(distros, distro, 'name'))
					distros.push({'name':distro, 'breed':breed, 'arch':arch, 'version':version, 'comment': comment});
			
				if (! search(profiles, profile, 'name'))
					profiles.push({'name':profile, 'distro':distro});
		
		}
	}
}