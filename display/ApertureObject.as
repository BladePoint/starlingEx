package starlingEx.display {

	import starling.utils.Color;

	public class ApertureObject {
		static const argumentErrorString:String = "ApertureObject must have 0, 1, or 3 arguments."
		static private var apertureObjectV:Vector.<ApertureObject> = new <ApertureObject>[];
		static public function getApertureObject(...args):ApertureObject {
			var apertureObject:ApertureObject;
			var l:uint = args.length;
			if (l == 0) {
				if (apertureObjectV.length == 0) apertureObject = new ApertureObject();
				else {
					apertureObject = apertureObjectV.pop();
					apertureObject.hex = Color.WHITE;
				}
			} else if (l == 1) {
				if (apertureObjectV.length == 0) apertureObject = new ApertureObject(args[0]);
				else {
					apertureObject = apertureObjectV.pop();
					apertureObject.hex = args[0];
				}
			} else if (l == 3) {
				if (apertureObjectV.length == 0) apertureObject = new ApertureObject(args[0],args[1],args[2]);
				else {
					apertureObject = apertureObjectV.pop();
					apertureObject.rgb(args[0],args[1],args[2]);
				}
			} else throw new ArgumentError(argumentErrorString);
			return apertureObject;
		}
		static public function putApertureObject(apertureObject:ApertureObject):void {
			if (apertureObject) apertureObjectV[apertureObjectV.length] = apertureObject;
		}
		static public function multiplyRGB(apertureObject:ApertureObject,multA:Array):uint {
			if (multA) {
				var r:uint = apertureObject.r * getRatio(multA[0]),
					g:uint = apertureObject.g * getRatio(multA[1]),
					b:uint = apertureObject.b * getRatio(multA[2]);
				return Color.rgb(r,g,b);
			} else return apertureObject.hex;
		}
		static private function getRatio(value:uint):Number {
			return value / 255;
		}

		private var _r:uint, _g:uint, _b:uint, _apertureHex:uint;
		public function ApertureObject(...args) {
			var l:uint = args.length;
			if (l == 0) {
				_apertureHex = Color.WHITE;
				calcRGB();
			} else if (l == 1) {
				_apertureHex = args[0];
				calcRGB();
			} else if (l == 3) {
				_r = args[0];
				_g = args[1];
				_b = args[2];
				calcHex();
			} else throw new ArgumentError(argumentErrorString);
		}
		private function calcRGB():void {
			_r = Color.getRed(_apertureHex);
			_g = Color.getGreen(_apertureHex);
			_b = Color.getBlue(_apertureHex);
		}
		private function calcHex():void {
			_apertureHex = Color.rgb(_r,_g,_b);
		}
		public function rgb(newR:uint,newG:uint,newB:uint):void {
			_r = newR;
			_g = newG;
			_b = newB;
			calcHex();
		}
		public function get r():uint {
			return _r;
		}
		public function set r(newR:uint):void {
			_r = newR;
			calcHex();
		}
		public function get g():uint {
			return _g;
		}
		public function set g(newG:uint):void {
			_g = newG;
			calcHex();
		}
		public function get b():uint {
			return _b;
		}
		public function set b(newB:uint):void {
			_b = newB;
			calcHex();
		}
		public function get hex():uint {
			return _apertureHex;
		}
		public function set hex(newHex:uint):void {
			_apertureHex = newHex;
			calcRGB();
		}

	}
	
}
