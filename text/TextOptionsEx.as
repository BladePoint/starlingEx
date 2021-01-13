// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import flash.text.StyleSheet;
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.text.TextFieldAutoSize;
	import starlingEx.text.TextFieldEx;

	/* Much of this code is appropriated from starling.text.TextOptions. */
	public class TextOptionsEx extends EventDispatcher {
		static private const textOptionsV:Vector.<TextOptionsEx> = new <TextOptionsEx>[];
		static public function getInstance(wordWrap:Boolean=true,autoScale:Boolean=false):TextOptionsEx {
			if (textOptionsV.length == 0) return new TextOptionsEx(wordWrap,autoScale);
			else {
				const textOptions:TextOptionsEx = textOptionsV.pop();
				textOptions.init(wordWrap,autoScale);
				return textOptions;
			}
		}
		static public function putInstance(textOptions:TextOptionsEx):void {
			if (textOptions) {
				textOptions.reset();
				textOptionsV[textOptionsV.length] = textOptions;
			}
		}

		private var _wordWrap:Boolean, _autoScale:Boolean, _isHtmlText:Boolean;
		private var _autoSize:String, _textureFormat:String;
		private var _textureScale:Number, _padding:Number;
		private var _styleSheet:StyleSheet;
		public function TextOptionsEx(wordWrap:Boolean=true,autoScale:Boolean=false) {
			init(wordWrap,autoScale);
		}
		private function init(wordWrap:Boolean,autoScale:Boolean):void {
			_wordWrap = wordWrap;
			_autoScale = autoScale;
			_isHtmlText = false;
			_autoSize = TextFieldAutoSize.NONE;
			_textureFormat = TextFieldEx.defaultTextureFormat;
			_textureScale = Starling.contentScaleFactor;
			_padding = 0;
		}
		public function copyFrom(options:TextOptionsEx):void {
			_wordWrap = options._wordWrap;
			_autoScale = options._autoScale;
			_autoSize = options._autoSize;
			_isHtmlText = options._isHtmlText;
			_textureScale = options._textureScale;
			_textureFormat = options._textureFormat;
			_styleSheet = options._styleSheet;
			_padding = options._padding;
			dispatchEventWith(Event.CHANGE);
		}
		public function clone():TextOptionsEx {
			var textOptions:TextOptionsEx = getInstance();
			textOptions.copyFrom(this);
			return textOptions;
		}
		public function get wordWrap():Boolean {return _wordWrap;}
		public function set wordWrap(value:Boolean):void {
			if (_wordWrap != value) {
				_wordWrap = value;
				dispatchEventWith(Event.CHANGE);
			}
		}
		public function get autoSize():String {return _autoSize;}
		public function set autoSize(value:String):void {
			if (_autoSize != value) {
				_autoSize = value;
				dispatchEventWith(Event.CHANGE);
			}
		}
		public function get autoScale():Boolean {return _autoScale;}
		public function set autoScale(value:Boolean):void {
			if (_autoScale != value) {
				_autoScale = value;
				dispatchEventWith(Event.CHANGE);
			}
		}
		public function get isHtmlText():Boolean {return _isHtmlText;}
		public function set isHtmlText(value:Boolean):void {
			if (_isHtmlText != value) {
				_isHtmlText = value;
				dispatchEventWith(Event.CHANGE);
			}
		}
		public function get styleSheet():StyleSheet {return _styleSheet;}
		public function set styleSheet(value:StyleSheet):void {
			_styleSheet = value;
			dispatchEventWith(Event.CHANGE);
		}
		public function get textureScale():Number {return _textureScale;}
		public function set textureScale(value:Number):void {_textureScale = value;}
		public function get textureFormat():String {return _textureFormat;}
		public function set textureFormat(value:String):void {
			if (_textureFormat != value) {
				_textureFormat = value;
				dispatchEventWith(Event.CHANGE);
			}
		}
		public function get padding():Number {return _padding;}
		public function set padding(value:Number):void {
			if (value < 0) value = 0;
			if (_padding != value) {
				_padding = value;
				dispatchEventWith(Event.CHANGE);
			}
		}
		public function reset():void {
			_styleSheet = null;
			removeEventListeners();
		}
		public function dispose():void {
			reset();
		}
	}

}
