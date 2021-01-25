// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.utils {

	import flash.utils.Dictionary;
	import mx.utils.NameUtil;
	import starling.errors.AbstractClassError;

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
			var result:uint = 1;
			while (result < i) result <<= 1;
			return result;
		}
		static public function previousPowerOfTwo(i:uint):uint {
			var next:uint = nextPowerOfTwo(i);
			if (next == i) return i;
			else return next >>= 1;
		}
		static public function setPrecision(num:Number,decimals:int,roundUp:Boolean=false):Number {
			const m:int = Math.pow(10,decimals);
			var mathFunction:Function = Math.round;
			if (roundUp) mathFunction = Math.ceil;
			return mathFunction(num * m) / m;
		}

		public function Utils() {throw new AbstractClassError();}
	}

}
