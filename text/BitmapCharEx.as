// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import flash.utils.Dictionary;
	import starling.textures.Texture;
	import starlingEx.text.IFont;
	import starlingEx.textures.TextureBitmapData;

	/* A helper class for arranging characters in a TextFieldEx by the Compositor class. */
	public class BitmapCharEx {
		static private const instancePool:Vector.<BitmapCharEx> = new <BitmapCharEx>[];
		static public function getInstance(iFont:IFont,id:int,xOffset:Number,yOffset:Number,xAdvance:Number):BitmapCharEx {
			var bitmapChar:BitmapCharEx;
			if (instancePool.length == 0) bitmapChar = new BitmapCharEx(iFont,id,xOffset,yOffset,xAdvance);
			else {
				bitmapChar = instancePool.pop();
				bitmapChar.init(iFont,id,xOffset,yOffset,xAdvance);
			}
			return bitmapChar;
		}
		static public function putInstance(bitmapChar:BitmapCharEx):void {
			if (bitmapChar) {
				bitmapChar.reset();
				instancePool[instancePool.length] = bitmapChar;
			}
		}

		private var _iFont:IFont;
		private var _charID:int;
		private var _xOffset:Number;
		private var _yOffset:Number;
		private var _xAdvance:Number;
		private var _textureBitmapData:TextureBitmapData;
		private var _texture:Texture;
		private var _kernings:Dictionary;
		public function BitmapCharEx(iFont:IFont,id:int,xOffset:Number,yOffset:Number,xAdvance:Number) {
			init(iFont,id,xOffset,yOffset,xAdvance);
		}
		private function init(iFont:IFont,id:int,xOffset:Number,yOffset:Number,xAdvance:Number):void {
			_iFont = iFont;
			_charID = id;
			_xOffset = xOffset;
			_yOffset = yOffset;
			_xAdvance = xAdvance;
		}
		public function initTexture(texture:Texture):void {
			_texture = texture;
		}
		public function initTextureBitmap(textureBitmapData:TextureBitmapData):void {
			_textureBitmapData = textureBitmapData;
		}
		public function addKerning(charID:int, amount:Number):void {
			if (_kernings == null) _kernings = new Dictionary();
			_kernings[charID] = amount;
		}
		public function getKerning(charID:int):Number {
			if (_kernings == null || _kernings[charID] == undefined) return 0.0;
			else return _kernings[charID];
		}
		public function get font():IFont {return _iFont;}
		public function get charID():int {return _charID;}
		public function get xOffset():Number {return _xOffset;}
		public function get yOffset():Number {return _yOffset;}
		public function get xAdvance():Number {return _xAdvance;}
		public function get texture():Texture {
			var returnTexture:Texture;
			if (_texture) returnTexture = _texture;
			else if (_textureBitmapData) returnTexture = _textureBitmapData.texture;
			return returnTexture;
		}
		public function get textureBitmapData():TextureBitmapData {return _textureBitmapData;}
		public function get width():Number {
			if (_texture) return _texture.width;
			else if (_textureBitmapData) return _textureBitmapData.textureWidth;
			else return 0;
		}
		public function get height():Number {
			if (_texture) return _texture.height;
			else if (_textureBitmapData) return _textureBitmapData.textureHeight;
			else return 0;
		}
		public function reset():void {
			_iFont = null;
			_textureBitmapData = null;
			_texture = null;
			if (_kernings) {
				for (var charID:int in _kernings) {
					delete _kernings[charID];
				}
			}
		}
		public function dispose():void {
			reset();
			_kernings = null;
		}
	}

}
