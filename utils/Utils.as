package starlingEx.utils {

	import mx.utils.NameUtil;

	public class Utils {
		static private var arrayV:Vector.<Array> = new <Array>[];
		static public function getArray():Array {
			if (arrayV.length == 0) return [];
			else return arrayV.pop();
		}
		static public function putArray(array:Array):void {
			if (array) {
				array.length = 0;
				arrayV[arrayV.length] = array;
			}
		}
		static private var uintVV:Vector.<Vector.<uint>> = new <Vector.<uint>>[];
		static public function getUintV(startUint:uint=0,endUint:uint=0):Vector.<uint> {
			var uintV:Vector.<uint>;
			if (uintVV.length == 0) uintV = new <uint>[];
			else uintV = uintVV.pop();
			if (startUint == 0 && endUint == 0) return uintV;
			else {
				var sign:int;
				var l:uint;
				if (endUint >= startUint) {
					sign = 1;
					l = endUint - startUint + 1;
				} else {
					sign = -1;
					l = startUint - endUint + 1;
				}
				for (var i:uint=0; i<l; i++) {
					uintV[uintV.length] = startUint + i*sign;
				}
				return uintV;
			}
		}
		static public function putUintV(uintV:Vector.<uint>):void {
			uintV.length = 0;
			uintVV[uintVV.length] = uintV;
		}
		static public function deleteObject(object:Object,recurse:Boolean=true):void {
			for (var property:String in object) {
				if (recurse && object[property] is Object) {
					var nestedObject:Object = object[property] as Object;
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
