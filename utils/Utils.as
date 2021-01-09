// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.utils {

	import flash.utils.Dictionary;
	import mx.utils.NameUtil;

	public class Utils {
		static private var lowercaseCache:Dictionary;
		static public function convertToLowerCase(string:String):String {
			if (lowercaseCache == null) lowercaseCache = new Dictionary();
			var result:String = lowercaseCache[string];
			if (result == null) {
				result = string.toLowerCase();
				lowercaseCache[string] = result;
			}
			return result;
		}
		/* Shallow copy an array. */
		static public function copyArray(sourceA:Array,targetA:Array):void {
			if (sourceA && targetA) {
				const l:uint = sourceA.length;
				for (var i:uint=0; i<l; i++) {targetA[i] = sourceA[i];}
			}
		}
		static public function deleteObject(object:Object,recurse:Boolean=true):void {
			for (var property:String in object) {
				if (recurse && object[property] is Object) {
					const nestedObject:Object = object[property] as Object;
					if (nestedObject.constructor == Object) deleteObject(nestedObject);
				} 
				delete object[property];
			}
		}
		static public function getID(object:Object):String {
			return NameUtil.createUniqueName(object);
		}
		static public function nextPowerOfTwo(i:uint):uint {
			i--;
			i |= i >> 1;
			i |= i >> 2;
			i |= i >> 4;
			i |= i >> 8;
			i |= i >> 16;
			i++;
			return i;
		}

		public function Utils() {}

	}

}
