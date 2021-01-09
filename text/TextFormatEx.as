// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.utils.Align;
	import starling.utils.Color;
	import starlingEx.text.TextFieldEx;

	/* A TextFormatEx stores default TextFieldEx formatting information such as the font, size, and colors of each corner and outline. Much of this code
	   is appropriated from starling.text.Textformat. */
	public class TextFormatEx extends EventDispatcher {
		static public const APERTURE_CHANGE:String = "apertureChange",
			SHADOW_CHANGE:String = "shadowChange",
			INVALID_ALIGNMENT:String = "Invalid alignment.";
		static private const instancePool:Vector.<TextFormatEx> = new <TextFormatEx>[];
		static public function getInstance(font:String,size:Number):TextFormatEx {
			var format:TextFormatEx;
			if (instancePool.length == 0) format = new TextFormatEx(font,size);
			else {
				format = instancePool.pop();
				format.init(font,size);
			}
			return format;
		}
		static public function putInstance(format:TextFormatEx):void {
			if (format) {
				format.reset();
				instancePool[instancePool.length] = format;
			}
		}
		
		private var _font:String;
		private var _size:Number, _leading:Number, _letterSpacing:Number, 
			_outlineWidth:Number, _softness:Number, _dropShadowX:Number, _dropShadowY:Number, _dropShadowAlpha:Number;
		private var _topLeftColor:uint, _topRightColor:uint, _bottomLeftColor:uint, _bottomRightColor:uint, _outlineColor:uint, _dropShadowColor:uint;
		private var _horizontalAlign:String, _verticalAlign:String;
		private var _kerning:Boolean;
		private var _textField:TextFieldEx;
		public function TextFormatEx(font:String,size:Number) {
			init(font,size);
		}
		private function init(font:String,size:Number):void {
			_font = font;
			_size = size;
			_letterSpacing = _leading = 0;
			_horizontalAlign = Align.TOP; 
			_verticalAlign = Align.LEFT;
			_kerning = true;
			_topLeftColor = _topRightColor = _bottomLeftColor = _bottomRightColor = _outlineColor = 0xffffff;
			_outlineWidth = 0;
			_softness = -1;
			_dropShadowX = _dropShadowY = 0;
			_dropShadowAlpha = .5
			_dropShadowColor = 0x000000;
		}
		public function copyFrom(sourceFormat:TextFormatEx):void {
			_font = sourceFormat._font;
			_size = sourceFormat._size;
			_leading = sourceFormat._leading;
			_letterSpacing = sourceFormat._letterSpacing;
			_outlineWidth = sourceFormat._outlineWidth;
			_softness = sourceFormat._softness;
			_dropShadowX = sourceFormat._dropShadowX;
			_dropShadowY = sourceFormat._dropShadowY;
			_dropShadowAlpha = sourceFormat._dropShadowAlpha;
			_topLeftColor = sourceFormat._topLeftColor;
			_topRightColor = sourceFormat._topRightColor;
			_bottomLeftColor = sourceFormat._bottomLeftColor;
			_bottomRightColor = sourceFormat._bottomRightColor;
			_outlineColor = sourceFormat._outlineColor;
			_dropShadowColor = sourceFormat._dropShadowColor;
			_horizontalAlign = sourceFormat._horizontalAlign;
			_verticalAlign = sourceFormat._verticalAlign;
			_kerning = sourceFormat._kerning;
			dispatch(Event.CHANGE);
		}
		public function clone():TextFormatEx {
			const cloneFormat:TextFormatEx = getInstance(null,NaN);
			cloneFormat.copyFrom(this);
			return cloneFormat;
		}
		public function get font():String {return _font;}
		public function set font(value:String):void {
			if (value != _font) {
				_font = value;
				dispatch(Event.CHANGE);
			}
		}
		public function get size():Number {return _size;}
		public function set size(value:Number):void {
			if (value != _size) {
				_size = value;
				dispatch(Event.CHANGE);
			}
		}
		public function get horizontalAlign():String {return _horizontalAlign;}
		public function set horizontalAlign(value:String):void {
			if (!Align.isValidHorizontal(value)) throw new ArgumentError(INVALID_ALIGNMENT);
			else if (value != _horizontalAlign) {
				_horizontalAlign = value;
				dispatch(Event.CHANGE);
			}
		}
		public function get verticalAlign():String {return _verticalAlign;}
		public function set verticalAlign(value:String):void {
			if (!Align.isValidVertical(value)) throw new ArgumentError(INVALID_ALIGNMENT);
			else if (value != _verticalAlign) {
				_verticalAlign = value;
				dispatch(Event.CHANGE);
			}
		}
		public function get kerning():Boolean {return _kerning;}
		public function set kerning(value:Boolean):void {
			if (value != _kerning) {
				_kerning = value;
				dispatch(Event.CHANGE);
			}
		}
		public function get leading():Number {return _leading;}
		public function set leading(value:Number):void {
			if (value != _leading) {
				_leading = value;
				dispatch(Event.CHANGE);
			}
		}
		public function get letterSpacing():Number {return _letterSpacing;}
		public function set letterSpacing(value:Number):void {
			if (value != _letterSpacing) {
				_letterSpacing = value;
				dispatch(Event.CHANGE);
			}
		}
		public function set color(value:uint):void {
			setCornerAndOutlineColors(value,value,value,value,value);
		}
		public function get topLeftColor():uint {return _topLeftColor;}
		public function set topLeftColor(value:uint):void {
			if (_topLeftColor != value) {
				_topLeftColor = value;
				dispatch(APERTURE_CHANGE,0xff000000);
			}
		}
		public function get topRightColor():uint {return _topRightColor;}
		public function set topRightColor(value:uint):void {
			if (_topRightColor != value) {
				_topRightColor = value;
				dispatch(APERTURE_CHANGE,0xff000000);
			}
		}
		public function get bottomLeftColor():uint {return _bottomLeftColor;}
		public function set bottomLeftColor(value:uint):void {
			if (_bottomLeftColor != value) {
				_bottomLeftColor = value;
				dispatch(APERTURE_CHANGE,0xff000000);
			}
		}
		public function get bottomRightColor():uint {return _bottomRightColor;}
		public function set bottomRightColor(value:uint):void {
			if (_bottomRightColor != value) {
				_bottomRightColor = value;
				dispatch(APERTURE_CHANGE,0xff000000);
			}
		}
		public function setCornerColors(topLeftHex:uint,topRightHex:uint,bottomLeftHex:uint,bottomRightHex:uint,dispatchOnChange:Boolean=true):void {
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
			if (dispatchColorB && dispatchOnChange) dispatch(APERTURE_CHANGE,0xff000000);
		}
		public function setCornerAndOutlineColors(topLeftHex:uint,topRightHex:uint,bottomLeftHex:uint,bottomRightHex:uint,outlineHex:uint,dispatchOnChange:Boolean=true):void {
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
			const changeCode:uint = Color.argb(colorCode,outlineColorCode,0,0);
			if (changeCode && dispatchOnChange) dispatch(APERTURE_CHANGE,changeCode);
		}
		public function get outlineColor():uint {return _outlineColor;}
		public function set outlineColor(value:uint):void {
			if (_outlineColor != value) {
				_outlineColor = value;
				dispatch(APERTURE_CHANGE,0x00ff0000);
			}
		}
		public function get outlineWidth():Number {return _outlineWidth;}
		public function set outlineWidth(value:Number):void {
			if (_outlineWidth != value) {
				_outlineWidth = value;
				dispatch(APERTURE_CHANGE,0x0000ff00);
			}
		}
		public function get softness():Number {return _softness;}
		public function set softness(value:Number):void {
			if (_softness != value) {
				_softness = value;
				dispatch(APERTURE_CHANGE,0x000000ff);
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
			const changeCode:uint = Color.argb(0,colorCode,widthCode,softnessCode);
			if (changeCode) dispatch(APERTURE_CHANGE,changeCode);
		}
		public function get dropShadowX():Number {return _dropShadowX;}
		public function set dropShadowX(newX:Number):void {
			_dropShadowX = newX;
			dispatch(SHADOW_CHANGE,0xff0000);
		}
		public function get dropShadowY():Number {return _dropShadowY;}
		public function set dropShadowY(newY:Number):void {
			_dropShadowY = newY;
			dispatch(SHADOW_CHANGE,0xff0000);
		}
		public function get dropShadowAlpha():Number {return _dropShadowAlpha;}
		public function set dropShadowAlpha(newAlpha:Number):void {
			_dropShadowAlpha = newAlpha;
			dispatch(SHADOW_CHANGE,0x00ff00);
		}
		public function get dropShadowColor():uint {return _dropShadowColor;}
		public function set dropShadowColor(newHex:uint):void {
			_dropShadowColor = newHex;
			dispatch(SHADOW_CHANGE,0x0000ff);
		}
		public function reset():void {
			_textField = null;
			removeEventListeners();
		}
		internal function assignTextField(textField:TextFieldEx):void {
			_textField = textField;
		}
		private function dispatch(type:String,hexCode:uint=0x000000):void {
			if (_textField) dispatchEventWith(type,false,hexCode);
		}
		public function dispose():void {
			reset();
		}
	}
	
}
