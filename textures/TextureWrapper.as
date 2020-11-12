// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.textures {

	import flash.display.BitmapData;
	import starling.textures.Texture;

	public class TextureWrapper {

		private var _bitmapData:BitmapData;
		private var _texture:Texture;
		public function TextureWrapper() {}
		public function initBitmapData(bitmapData:BitmapData,generateMipMaps:Boolean=false):void {
			_bitmapData = bitmapData;
			_texture = Texture.fromBitmapData(_bitmapData,generateMipMaps);
		}
		public function initTexture(texture:Texture):void {
			_texture = texture;
		}
		public function get texture():Texture {
			return _texture;
		}
		public function dispose():void {
			if (_bitmapData) {
				_bitmapData.dispose();
				_bitmapData = null;
			}
			if (_texture) {
				_texture.dispose();
				_texture = null;
			}
		}

	}

}
