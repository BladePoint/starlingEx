// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import flash.utils.Dictionary;
	import starling.textures.Texture;
	import starlingEx.text.IFont;
	import starlingEx.textures.TextureBitmapData;

	public class BitmapCharEx {

		private var _iFont:IFont;
		private var _charID:int;
		private var _xOffset:Number;
		private var _yOffset:Number;
		private var _xAdvance:Number;
		private var _textureBitmapData:TextureBitmapData;
		private var _texture:Texture;
		private var _kernings:Dictionary;
		public function BitmapCharEx(iFont:IFont,id:int,xOffset:Number,yOffset:Number,xAdvance:Number) {
			_iFont = iFont;
			_charID = id;
			_xOffset = xOffset;
			_yOffset = yOffset;
			_xAdvance = xAdvance;
			_kernings = null;
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
			else if (_textureBitmapData) {
				if (_textureBitmapData.quadW == 0) _textureBitmapData.calcQuadDimensions();
				return _textureBitmapData.quadW;
			} else return 0;
		}
		public function get height():Number {
			if (_texture) return _texture.height;
			else if (_textureBitmapData) {
				if (_textureBitmapData.quadH == 0) _textureBitmapData.calcQuadDimensions();
				return _textureBitmapData.quadH;
			} else return 0;
		}
	}

}
