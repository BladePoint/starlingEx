// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.textures {

	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import starling.textures.Texture;
	//import starlingEx.display.QuadDemander;
	import starlingEx.textures.DynamicAtlas;
	import starlingEx.textures.ITextureOnDemand;
	import starlingEx.utils.Utils;

	public class TextureDrawable extends Rectangle implements ITextureOnDemand {
		static public const transparentGreenHex:uint = 0x0000ff00;
		static public function newBitmapData(w:uint,h:uint):BitmapData {
			return new BitmapData(w,h,true,transparentGreenHex);
		}
		static private var whiteTransform:ColorTransform;
		static public function applyWhiteTransform(bitmapData:BitmapData,targetRect:Rectangle):void {
			if (whiteTransform == null) whiteTransform = new ColorTransform(0,0,0,1,255,255,255,0);
			bitmapData.colorTransform(targetRect,whiteTransform);
		}
		static public const sourceDimensionError:String = "Dimensions cannot be greater than source BitmapData.";

		public var sourceOffsetX:Number = 0, sourceOffsetY:Number = 0;
		public var atlasPadding:int; //Width of transparent padding to be added around the texture in the atlas. An atlasPadding is necessary to prevent textures from bleeding into one another. Default value of 0 pads the bottom and right sides by one pixel. Set to -1 to remove atlas padding.
		public var whiteFill:Boolean, //Create a white silhouette version.
			mipMapping:Boolean; //If a dynamic atlas is in use, the atlas's mipmap settings will be used
		protected var sourceDrawable:IBitmapDrawable;
		protected var cropW:Number, cropH:Number;
		protected var bitmapData:BitmapData;
		private var originalW:Number, originalH:Number;
		private var _texturePadding:uint, _textureWidth:uint, _textureHeight:uint;
		private var _atlasExtrude:Boolean;
		private var _texture:Texture;
		private var mappedO:Object;
		private var dynamicAtlas:DynamicAtlas;
		public function TextureDrawable(iBitmapDrawable:IBitmapDrawable) {
			sourceDrawable = iBitmapDrawable;
			const sourceO:Object = sourceDrawable as Object;
			originalW = sourceO.width;
			originalH = sourceO.height;
			cropW = cropH = 0;
			mappedO = {};
		}
		public function setSourceDimensions(w:Number,h:Number):void {
			sourceW = w;
			sourceH = h;
		}
		public function set sourceW(w:Number):void {
			if (w > originalW) throw new ArgumentError(sourceDimensionError);
			else cropW = originalW - w;
		}
		public function get sourceW():Number {return originalW - cropW;}
		public function set sourceH(h:Number):void {
			if (h > originalH) throw new ArgumentError(sourceDimensionError);
			else cropH = originalH - h;
		}
		public function get sourceH():Number {return originalH - cropH;}
		public function setSourceOffset(offsetX:uint,offsetY:uint):void {
			sourceOffsetX = offsetX;
			sourceOffsetY = offsetY;
		}
		//The width of transparent padding to go around and be included in texture. Padding is necessary when a rounded texture touches the edge. Setting texturePadding to a value greater than 0 sets atlasExtrude to false.
		public function set texturePadding(padding:uint):void {
			if (padding > 0) _atlasExtrude = false;
			_texturePadding = padding;
		}
		public function get texturePadding():uint {return _texturePadding;}
		//True adds a 1 pixel extrusion around the texture that is colored to match the nearest pixel in the atlas. Set atlasExtrude to true if the edge of the texture becomes transparent.
		public function set atlasExtrude(boolean:Boolean):void {
			if (boolean) _texturePadding = 0;
			_atlasExtrude = boolean;
		}
		public function get atlasExtrude():Boolean {return _atlasExtrude;}
		public function calcTextureDimensions():void {
			_textureWidth = Math.ceil(sourceW) + _texturePadding*2;
			_textureHeight = Math.ceil(sourceH) + _texturePadding*2;
		}
		public function get textureWidth():uint {return _textureWidth;}
		public function get textureHeight():uint {return _textureHeight;}
		public function get texture():Texture {
			if (_texture) return _texture;
			else {
				if (dynamicAtlas) _texture = Texture.fromTexture(dynamicAtlas.texture,this);
				else createTexture();
				return _texture;
			}
		}
		private function createTexture():void {
			getBMD();
			_texture = Texture.fromBitmapData(bitmapData,mipMapping);
		}
		public function getBMD():BitmapData {return null;}
		public function copyPixelsTo(target_BMD:BitmapData):void {}
		/*public function addMapped(quadDemander:QuadDemander):void {
			mappedO[quadDemander.id] = quadDemander;
		}
		public function removeMapped(quadDemander:QuadDemander):void {
			delete mappedO[quadDemander.id];
		}*/
		public function reassignTextures():void {
			for (var id:String in mappedO) mappedO[id].getTexture();
		}
		//Calculate the dimensions of the rectangle to be packed in the atlas.
		public function calcRectangle():void {
			var padding:uint = _texturePadding * 2;
			if (_atlasExtrude) padding += 2;
			if (atlasPadding == 0) padding += 1;
			else if (atlasPadding > 0) padding += atlasPadding * 2;
			width = sourceW + padding;
			height = sourceH + padding;
		}
		internal function assignAtlas(dynamicAtlas:DynamicAtlas):void {
			this.dynamicAtlas = dynamicAtlas;
		}
		public function dispose():void {
			sourceDrawable = null;
			bitmapData.dispose();
			bitmapData = null;
			_texture.dispose();
			_texture = null;
			Utils.deleteObject(mappedO,false);
			mappedO = null;
			dynamicAtlas = null;
		}
	}
	
}
