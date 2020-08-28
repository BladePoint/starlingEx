package starlingEx.text {

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.text.TextFormat;
	import starling.utils.Color;
	import starling.utils.Align;
	import starlingEx.display.ApertureObject;
	import starlingEx.text.ApertureTextField;
	import starlingEx.utils.PoolEx;

	public class ApertureTextFormat extends TextFormat {
		static public var APERTURE_CHANGE:String = "apertureChange",
			SHADOW_CHANGE:String = "shadowChange";

		private var _topLeftColor:uint, _topRightColor:uint, _bottomLeftColor:uint, _bottomRightColor:uint, _dropShadowColor:uint;
		private var outlineTrue_AO:ApertureObject, outlineMult_AO:ApertureObject;
		private var _outlineWidth:Number, _softness:Number, _dropShadowX:Number, _dropShadowY:Number, _dropShadowAlpha:Number;
		private var _textField:ApertureTextField;
		public function ApertureTextFormat(font:String,size:Number,color:uint=0xffffff,topRightColor:int=-1,bottomLeftColor:int=-1,bottomRightColor:int=-1,outlineColor:int=-1,outlineWidth:Number=0,softness:Number=-1,horizontalAlign:String=Align.LEFT,verticalAlign:String=Align.TOP,dropShadowX:Number=0,dropShadowY:Number=0,dropShadowAlpha:Number=.5,dropShadowColor:uint=0x000000) {
			super(font,size,color,horizontalAlign,verticalAlign);
			_topLeftColor = color;
			_topRightColor = topRightColor == -1 ? _topLeftColor : topRightColor;
			_bottomLeftColor = bottomLeftColor == -1 ? _topLeftColor : bottomLeftColor;
			_bottomRightColor = bottomRightColor == -1 ? _topLeftColor : bottomRightColor;
			outlineTrue_AO = outlineColor == -1 ? ApertureObject.getApertureObject(_topLeftColor) : ApertureObject.getApertureObject(outlineColor);
			outlineMult_AO = ApertureObject.getApertureObject(outlineTrue_AO.hex);
			_outlineWidth = outlineWidth;
			_softness = softness;
			_dropShadowX = dropShadowX;
			_dropShadowY = dropShadowY;
			_dropShadowAlpha = dropShadowAlpha;
			_dropShadowColor = dropShadowColor;
		}
		internal function assignTextField(textField:ApertureTextField):void {
			_textField = textField;
		}
		public function multiplyOutline():Array {
			var multA:Array;
			if (_textField) {
				multA = _textField.getMultRGB();
				outlineMult_AO.hex = ApertureObject.multiplyRGB(outlineTrue_AO,multA);
			}
			return multA;
		}
		
		override public function copyFrom(format:TextFormat):void {
			if (format is ApertureTextFormat) {
				var apertureFormat:ApertureTextFormat = format as ApertureTextFormat;
				_topLeftColor = apertureFormat._topLeftColor;
				_topRightColor = apertureFormat._topRightColor;
				_bottomLeftColor = apertureFormat._bottomLeftColor;
				_bottomRightColor = apertureFormat._bottomRightColor;
				outlineTrue_AO.hex = apertureFormat.outlineTrue_AO.hex;
				outlineMult_AO.hex = apertureFormat.outlineMult_AO.hex;
				_outlineWidth = apertureFormat._outlineWidth;
				_softness = apertureFormat._softness;
				_dropShadowX = apertureFormat._dropShadowX;
				_dropShadowY = apertureFormat._dropShadowY;
				_dropShadowAlpha = apertureFormat._dropShadowAlpha;
				_dropShadowColor = apertureFormat._dropShadowColor;
			}
			super.copyFrom(format);
		}
		override public function clone():TextFormat {
			var cloneFormat:ApertureTextFormat = cloneAperture();
			var starlingFormat:TextFormat = cloneFormat as TextFormat;
			return starlingFormat;
		}
		public function cloneAperture():ApertureTextFormat {
			var cloneFormat:ApertureTextFormat = new ApertureTextFormat("",0);
			cloneFormat.copyFrom(this);
			return cloneFormat;
		}
		override public function setTo(font:String="Verdana",size:Number=12,color:uint=0x0,horizontalAlign:String="center",verticalAlign:String="center"):void {
			_topLeftColor = _topRightColor = _bottomLeftColor = _bottomRightColor = color;
			outlineTrue_AO.hex = color;
			PoolEx.putArray(multiplyOutline());
			super.setTo(font,size,color,horizontalAlign,verticalAlign);
		}
		override public function get color():uint {return topLeftColor;}
		override public function set color(value:uint):void {
			setAllHex(value,value,value,value,value);
		}
		public function get topLeftColor():uint {return _topLeftColor;}
		public function set topLeftColor(value:uint):void {
			if (_topLeftColor != value) {
				_topLeftColor = value;
				dispatchEventWith(APERTURE_CHANGE,false,0xff0000);
			}
		}
		public function get topRightColor():uint {return _topRightColor;}
		public function set topRightColor(value:uint):void {
			if (_topRightColor != value) {
				_topRightColor = value;
				dispatchEventWith(APERTURE_CHANGE,false,0xff0000);
			}
		}
		public function get bottomLeftColor():uint {return _bottomLeftColor;}
		public function set bottomLeftColor(value:uint):void {
			if (_bottomLeftColor != value) {
				_bottomLeftColor = value;
				dispatchEventWith(APERTURE_CHANGE,false,0xff0000);
			}
		}
		public function get bottomRightColor():uint {return _bottomRightColor;}
		public function set bottomRightColor(value:uint):void {
			if (_bottomRightColor != value) {
				_bottomRightColor = value;
				dispatchEventWith(APERTURE_CHANGE,false,0xff0000);
			}
		}
		public function setEachHex(topLeftHex:uint,topRightHex:uint,bottomLeftHex:uint,bottomRightHex:uint,dispatchOnChange:Boolean=true):void {
			var dispatchColorB:Boolean;
			if (_topLeftColor != topLeftHex) {
				_topLeftColor = topLeftHex;
				dispatchColorB = true;
			}
			if (_topRightColor != topRightHex) {
				_topRightColor = topRightHex;
				dispatchColorB = true;
			}
			if (_bottomLeftColor != bottomLeftHex) {
				_bottomLeftColor = bottomLeftHex;
				dispatchColorB = true;
			}
			if (_bottomRightColor != bottomRightHex) {
				_bottomRightColor = bottomRightHex;
				dispatchColorB = true;
			}
			if (dispatchColorB && dispatchOnChange) dispatchEventWith(APERTURE_CHANGE,false,0xff0000);
		}
		public function setAllHex(topLeftHex:uint,topRightHex:uint,bottomLeftHex:uint,bottomRightHex:uint,outlineHex:uint,dispatchOnChange:Boolean=true):void {
			var colorCode:uint;
			if (_topLeftColor != topLeftHex) {
				_topLeftColor = topLeftHex;
				colorCode = 255;
			}
			if (_topRightColor != topRightHex) {
				_topRightColor = topRightHex;
				colorCode = 255;
			}
			if (_bottomLeftColor != bottomLeftHex) {
				_bottomLeftColor = bottomLeftHex;
				colorCode = 255;
			}
			if (_bottomRightColor != bottomRightHex) {
				_bottomRightColor = bottomRightHex;
				colorCode = 255;
			}
			var outlineColorCode:uint;
			if (outlineTrue_AO.hex != outlineHex) {
				outlineTrue_AO.hex = outlineHex;
				PoolEx.putArray(multiplyOutline());
				outlineColorCode = 255;
			}
			var changeCode:uint = Color.rgb(colorCode,outlineColorCode,0);
			if (changeCode && dispatchOnChange) dispatchEventWith(APERTURE_CHANGE,false,changeCode);
		}
		public function get outlineColor():uint {return outlineMult_AO.hex;}
		public function set outlineColor(value:uint):void {
			if (outlineTrue_AO.hex != value) {
				outlineTrue_AO.hex = value;
				PoolEx.putArray(multiplyOutline());
				dispatchEventWith(APERTURE_CHANGE,false,0x000100);
			}
		}
		public function get outlineWidth():Number {return _outlineWidth;}
		public function set outlineWidth(value:Number):void {
			if (_outlineWidth != value) {
				_outlineWidth = value;
				dispatchEventWith(APERTURE_CHANGE,false,0x000001);
			}
		}
		public function get softness():Number {return _softness;}
		public function set softness(value:Number):void {
			if (_softness != value) {
				_softness = value;
				dispatchEventWith(APERTURE_CHANGE,false,0x000001);
			}
		}
		public function setOutline(outlineHex:uint,outlineWidth:Number,softness:Number=-1):void {
			var outlineColor:uint;
			if (outlineTrue_AO.hex != outlineHex) {
				outlineTrue_AO.hex = outlineHex;
				PoolEx.putArray(multiplyOutline());
				outlineColor = 1;
			}
			var outlineEdge:uint;
			if (_outlineWidth != outlineWidth) {
				_outlineWidth = outlineWidth
				outlineEdge = 1;
			}
			if (_softness != softness) {
				_softness = softness;
				outlineEdge = 1;
			}
			var changeCode:uint = Color.rgb(0,outlineColor,outlineEdge);
			if (changeCode) dispatchEventWith(APERTURE_CHANGE,false,changeCode);
		}
		public function get dropShadowX():Number {return _dropShadowX;}
		public function set dropShadowX(newX:Number):void {
			_dropShadowX = newX;
			dispatchEventWith(SHADOW_CHANGE,false,0x010000);
		}
		public function get dropShadowY():Number {return _dropShadowY;}
		public function set dropShadowY(newY:Number):void {
			_dropShadowY = newY;
			dispatchEventWith(SHADOW_CHANGE,false,0x010000);
		}
		public function get dropShadowAlpha():Number {return _dropShadowAlpha;}
		public function set dropShadowAlpha(newAlpha:Number):void {
			_dropShadowAlpha = newAlpha;
			dispatchEventWith(SHADOW_CHANGE,false,0x000100);
		}
		public function get dropShadowColor():uint {return _dropShadowColor;}
		public function set dropShadowColor(newHex:uint):void {
			_dropShadowColor = newHex;
			dispatchEventWith(SHADOW_CHANGE,false,0x000001);
		}
		public function dispose():void {
			ApertureObject.putApertureObject(outlineTrue_AO);
			ApertureObject.putApertureObject(outlineMult_AO);
			outlineTrue_AO = outlineMult_AO = null;
		}
	}

}
