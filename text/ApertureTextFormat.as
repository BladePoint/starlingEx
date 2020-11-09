// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.text.TextFormat;
	import starling.utils.Color;
	import starling.utils.Align;
	import starlingEx.text.ApertureTextField;
	import starlingEx.utils.PoolEx;

	/* An ApertureTextFormat stores character formatting information such as the colors of each corner and outline. */
	public class ApertureTextFormat extends TextFormat {
		static public var APERTURE_CHANGE:String = "apertureChange",
			SHADOW_CHANGE:String = "shadowChange";
		static private var formatV:Vector.<ApertureTextFormat> = new <ApertureTextFormat>[];
		static public function getInstance(font:String,size:Number,color:uint=0xffffff,topRightColor:int=-1,bottomLeftColor:int=-1,bottomRightColor:int=-1,outlineColor:int=-1,outlineWidth:Number=0,softness:Number=-1,horizontalAlign:String=Align.LEFT,verticalAlign:String=Align.TOP,dropShadowX:Number=0,dropShadowY:Number=0,dropShadowAlpha:Number=.5,dropShadowColor:uint=0x000000):ApertureTextFormat {
			var format:ApertureTextFormat;
			if (formatV.length == 0) format = new ApertureTextFormat(font,size,color,topRightColor,bottomLeftColor,bottomRightColor,outlineColor,outlineWidth,softness,horizontalAlign,verticalAlign,dropShadowX,dropShadowY,dropShadowAlpha,dropShadowColor);
			else {
				format = formatV.pop();
				format.initSuper(font,size,horizontalAlign,verticalAlign);
				format.init(color,topRightColor,bottomLeftColor,bottomRightColor,outlineColor,outlineWidth,softness,dropShadowX,dropShadowY,dropShadowAlpha,dropShadowColor);
			}
			return format;
		}
		static public function putInstance(format:ApertureTextFormat):void {
			if (format) {
				format.dispose();
				formatV[formatV.length] = format;
			}
		}

		private var _topLeftColor:uint, _topRightColor:uint, _bottomLeftColor:uint, _bottomRightColor:uint, _outlineColor:uint, _dropShadowColor:uint;
		private var _outlineWidth:Number, _softness:Number, _dropShadowX:Number, _dropShadowY:Number, _dropShadowAlpha:Number;
		private var _textField:ApertureTextField;
		public function ApertureTextFormat(font:String,size:Number,color:uint=0xffffff,topRightColor:int=-1,bottomLeftColor:int=-1,bottomRightColor:int=-1,outlineColor:int=-1,outlineWidth:Number=0,softness:Number=-1,horizontalAlign:String=Align.LEFT,verticalAlign:String=Align.TOP,dropShadowX:Number=0,dropShadowY:Number=0,dropShadowAlpha:Number=.5,dropShadowColor:uint=0x000000) {
			super(font,size,color,horizontalAlign,verticalAlign);
			init(color,topRightColor,bottomLeftColor,bottomRightColor,outlineColor,outlineWidth,softness,dropShadowX,dropShadowY,dropShadowAlpha,dropShadowColor);
		}
		private function initSuper(font:String,size:Number,horizontalAlign:String,verticalAlign:String):void {
			this.font = font;
			this.size = size;
			this.horizontalAlign = horizontalAlign;
			this.verticalAlign = verticalAlign;
		}
		private function init(topLeftColor:uint,topRightColor:int,bottomLeftColor:int,bottomRightColor:int,outlineColor:int,outlineWidth:Number,softness:Number,dropShadowX:Number,dropShadowY:Number,dropShadowAlpha:Number,dropShadowColor:uint):void {
			_topLeftColor = topLeftColor;
			_topRightColor = topRightColor == -1 ? _topLeftColor : topRightColor;
			_bottomLeftColor = bottomLeftColor == -1 ? _topLeftColor : bottomLeftColor;
			_bottomRightColor = bottomRightColor == -1 ? _topLeftColor : bottomRightColor;
			_outlineColor = outlineColor == -1 ? _topLeftColor : outlineColor;
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
		override public function copyFrom(format:TextFormat):void {
			super.copyFrom(format);
			if (format is ApertureTextFormat) {
				var apertureFormat:ApertureTextFormat = format as ApertureTextFormat;
				_topLeftColor = apertureFormat._topLeftColor;
				_topRightColor = apertureFormat._topRightColor;
				_bottomLeftColor = apertureFormat._bottomLeftColor;
				_bottomRightColor = apertureFormat._bottomRightColor;
				_outlineColor = apertureFormat._outlineColor;
				_outlineWidth = apertureFormat._outlineWidth;
				_softness = apertureFormat._softness;
				_dropShadowX = apertureFormat._dropShadowX;
				_dropShadowY = apertureFormat._dropShadowY;
				_dropShadowAlpha = apertureFormat._dropShadowAlpha;
				_dropShadowColor = apertureFormat._dropShadowColor;
			}
		}
		override public function clone():TextFormat {
			var cloneFormat:ApertureTextFormat = cloneAperture();
			var starlingFormat:TextFormat = cloneFormat as TextFormat;
			return starlingFormat;
		}
		public function cloneAperture():ApertureTextFormat {
			var cloneFormat:ApertureTextFormat = getInstance(null,NaN);
			cloneFormat.copyFrom(this);
			return cloneFormat;
		}
		override public function setTo(font:String="Verdana",size:Number=12,color:uint=0x0,horizontalAlign:String="center",verticalAlign:String="center"):void {
			_topLeftColor = _topRightColor = _bottomLeftColor = _bottomRightColor = _outlineColor = color;
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
				dispatchEventWith(APERTURE_CHANGE,false,0xff000000);
			}
		}
		public function get topRightColor():uint {return _topRightColor;}
		public function set topRightColor(value:uint):void {
			if (_topRightColor != value) {
				_topRightColor = value;
				dispatchEventWith(APERTURE_CHANGE,false,0xff000000);
			}
		}
		public function get bottomLeftColor():uint {return _bottomLeftColor;}
		public function set bottomLeftColor(value:uint):void {
			if (_bottomLeftColor != value) {
				_bottomLeftColor = value;
				dispatchEventWith(APERTURE_CHANGE,false,0xff000000);
			}
		}
		public function get bottomRightColor():uint {return _bottomRightColor;}
		public function set bottomRightColor(value:uint):void {
			if (_bottomRightColor != value) {
				_bottomRightColor = value;
				dispatchEventWith(APERTURE_CHANGE,false,0xff000000);
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
			if (dispatchColorB && dispatchOnChange) dispatchEventWith(APERTURE_CHANGE,false,0xff000000);
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
			if (_outlineColor != outlineHex) {
				_outlineColor = outlineHex;
				outlineColorCode = 255;
			}
			var changeCode:uint = Color.argb(colorCode,outlineColorCode,0,0);
			if (changeCode && dispatchOnChange) dispatchEventWith(APERTURE_CHANGE,false,changeCode);
		}
		public function get outlineColor():uint {return _outlineColor;}
		public function set outlineColor(value:uint):void {
			if (_outlineColor != value) {
				_outlineColor = value;
				dispatchEventWith(APERTURE_CHANGE,false,0x00ff0000);
			}
		}
		public function get outlineWidth():Number {return _outlineWidth;}
		public function set outlineWidth(value:Number):void {
			if (_outlineWidth != value) {
				_outlineWidth = value;
				dispatchEventWith(APERTURE_CHANGE,false,0x0000ff00);
			}
		}
		public function get softness():Number {return _softness;}
		public function set softness(value:Number):void {
			if (_softness != value) {
				_softness = value;
				dispatchEventWith(APERTURE_CHANGE,false,0x000000ff);
			}
		}
		public function setOutline(outlineHex:uint,outlineWidth:Number,softness:Number=-1):void {
			var colorCode:uint,
				widthCode:uint,
				softnessCode:uint;
			if (_outlineColor != outlineHex) {
				_outlineColor = outlineHex;
				colorCode = 255;
			}
			if (_outlineWidth != outlineWidth) {
				_outlineWidth = outlineWidth
				widthCode = 255;
			}
			if (_softness != softness) {
				_softness = softness;
				softnessCode = 255;
			}
			var changeCode:uint = Color.argb(0,colorCode,widthCode,softnessCode);
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
			_textField = null;
		}
	}

}
