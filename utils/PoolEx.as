// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.utils {

	import starlingEx.utils.Utils;

	public class PoolEx {
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
		static private var objectV:Vector.<Object> = new <Object>[];
		static public function getObject():Object {
			if (objectV.length == 0) return {};
			else return objectV.pop();
		}
		static public function putObject(object:Object):void {
			if (object) {
				Utils.deleteObject(object,false);
				objectV[objectV.length] = object;
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
			if (uintV) {
				uintV.length = 0;
				uintVV[uintVV.length] = uintV;
			}
		}

		public function PoolEx() {}

	}

}
