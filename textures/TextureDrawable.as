// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.textures {

	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.textures.Texture;
	import starling.utils.Pool;
	import starlingEx.textures.DynamicAtlas;
	import starlingEx.textures.ITextureEx;

	public class TextureDrawable extends EventDispatcher implements ITextureEx {
		static public const DRAWABLE_CHANGED_SIZE:String = "drawableChangedSize",
			DRAWABLE_CHANGED_CONTENTS:String = "drawableChangedContents";
		static public const transparentGreenHex:uint = 0x0000ff00;
		static public function newBitmapData(w:uint,h:uint):BitmapData {
			return new BitmapData(w,h,true,transparentGreenHex);
		}
		static private var whiteTransform:ColorTransform;
		static public function applyWhiteTransform(bitmapData:BitmapData,targetRect:Rectangle):void {
			if (whiteTransform == null) whiteTransform = new ColorTransform(0,0,0,1,255,255,255,0);
			bitmapData.colorTransform(targetRect,whiteTransform);
		}
		static public const sourceAreaError:String = "Source area cannot be outside original area.";

		public var whiteFill:Boolean, //Create a white silhouette version.
			mipMapping:Boolean; //If a dynamic atlas is in use, the atlas's mipmap settings will be used
		internal var atlasRect:Rectangle, textureRect:Rectangle;
		protected var _sourceX:Number, _sourceY:Number, cropW:Number, cropH:Number, originalW:Number, originalH:Number,
			_textureMultiplier:Number;
		protected var textureOffset:uint;
		protected var bitmapData:BitmapData;
		private var _texturePadding:uint, _textureWidth:uint, _textureHeight:uint;
		private var _atlasPadding:int; //Width of transparent padding to be added around the texture in the atlas. An atlasPadding is necessary to prevent textures from bleeding into one another. Default value of 0 pads the bottom and right sides by one pixel. Set to -1 to remove atlas padding.
		private var _atlasExtrude:Boolean;
		private var drawnTexture:Texture, dynamicAtlasTexture:Texture;
		private var dynamicAtlas:DynamicAtlas;
		public function TextureDrawable(iBitmapDrawable:IBitmapDrawable,textureMultiplier:Number=1) {
			init(iBitmapDrawable,textureMultiplier);
		}
		internal function init(iBitmapDrawable:IBitmapDrawable,textureMultiplier):void {
			_sourceX = _sourceY = cropW = cropH = 0;
			setOriginalDimensions(iBitmapDrawable);
			this._textureMultiplier = textureMultiplier;
			atlasRect = Pool.getRectangle();
			textureRect = Pool.getRectangle();
		}
		protected function setOriginalDimensions(iBitmapDrawable:IBitmapDrawable):void {
			calcTextureDimensions();
		}
		public function setSourceArea(x:Number,y:Number,w:Number,h:Number):void {
			if (isNaN(x)) x = 0;
			if (isNaN(y)) y = 0;
			if (isNaN(w)) w = originalW;
			if (isNaN(h)) h = originalH;
			if (x+w > originalW || y+h > originalH) throw new ArgumentError(sourceAreaError);
			else {
				_sourceX = x;
				_sourceY = y;
				cropW = originalW - w;
				cropH = originalH - h;
				calcTextureDimensions();
			}
		}
		public function get sourceX():Number {return _sourceX;}
		public function get sourceY():Number {return _sourceY;}
		public function get sourceW():Number {return originalW - cropW;}
		public function get sourceH():Number {return originalH - cropH;}
		public function get textureMultiplier():Number {return _textureMultiplier;}
		/* The width of transparent padding to go around and be included in texture. Padding is necessary when a rounded texture touches the edge.
		   Setting texturePadding to a value greater than 0 sets atlasExtrude to false. */
		public function set texturePadding(padding:uint):void {
			if (padding > 0) _atlasExtrude = false;
			_texturePadding = padding;
			calcTextureDimensions();
		}
		public function get texturePadding():uint {return _texturePadding;}
		public function set atlasPadding(value:uint):void {
			_atlasPadding = value;
			calcTextureOffset();
		}
		public function get atlasPadding():uint {
			return _atlasPadding;
		}
		/* Adds a 1 pixel extrusion around the texture that is colored to match the nearest pixel in the atlas. Set atlasExtrude to true if the
		edge of the texture incorrectly appears transparent. */
		public function set atlasExtrude(boolean:Boolean):void {
			if (boolean) _texturePadding = 0;
			_atlasExtrude = boolean;
			calcTextureOffset();
		}
		public function get atlasExtrude():Boolean {return _atlasExtrude;}
		private function calcTextureOffset():void {
			if (_atlasPadding > 0) textureOffset = atlasPadding;
			else textureOffset = 0;
			if (_atlasExtrude) textureOffset += 1;
		}
		private function calcTextureDimensions():void {
			_textureWidth = Math.ceil(sourceW) + _texturePadding*2;
			_textureHeight = Math.ceil(sourceH) + _texturePadding*2;
		}
		public function get textureWidth():uint {return _textureWidth;}
		public function get textureHeight():uint {return _textureHeight;}
		public function get texture():Texture {
			var returnTexture:Texture;
			if (dynamicAtlas) {
				if (dynamicAtlasTexture) returnTexture = dynamicAtlasTexture;
				else dynamicAtlasTexture = returnTexture = Texture.fromTexture(dynamicAtlas.texture,textureRect);
			} else {
				if (drawnTexture == null) drawTexture();
				returnTexture = drawnTexture;
			}
			return returnTexture;
		}
		private function drawTexture():void {
			generateBitmapData();
			drawnTexture = Texture.fromBitmapData(bitmapData,mipMapping);
		}
		protected function generateBitmapData():void {}
		internal function copyPixelsTo(target_BMD:BitmapData):void {}
		//Calculate the dimensions of the rectangle to be packed in the atlas.
		public function calcRectangle():void {
			var padding:uint = _texturePadding * 2;
			if (_atlasExtrude) padding += 2;
			if (atlasPadding == 0) padding += 1;
			else if (atlasPadding > 0) padding += atlasPadding * 2;
			atlasRect.width = sourceW + padding;
			atlasRect.height = sourceH + padding;
		}
		internal function assignAtlas(dynamicAtlas:DynamicAtlas):void {
			if (dynamicAtlas) {
				if (dynamicAtlasTexture || drawnTexture && this.dynamicAtlas != dynamicAtlas) atlasChanged();
				this.dynamicAtlas = dynamicAtlas;
				disposeBitmapData();
				disposeDrawnTexture();
				dynamicAtlas.addEventListener(Event.CHANGE,atlasChanged);
			} else {
				this.dynamicAtlas = null;
				if (dynamicAtlasTexture) {
					dynamicAtlasTexture.dispose();
					dynamicAtlasTexture = null;
				}
			}
		}
		private function atlasChanged(evt:Event=null):void {
			if (dynamicAtlasTexture) {
				dynamicAtlasTexture.dispose();
				dynamicAtlasTexture = null;
				dispatchEventWith(Event.CHANGE);
			}
		}
		public function get quadW():Number {
			return textureWidth * textureMultiplier;
		}
		public function get quadH():Number {
			return textureHeight * textureMultiplier;
		}
		internal function reset():void {
			atlasPadding = 0;
			whiteFill = mipMapping = _atlasExtrude = false;
			Pool.putRectangle(atlasRect);
			Pool.putRectangle(textureRect);
			atlasRect = textureRect = null;
			_sourceX = _sourceY = 0;
			disposeBitmapData();
			_texturePadding = textureOffset = _textureWidth = _textureHeight = 0;
			disposeDrawnTexture();
			if (dynamicAtlasTexture) {
				dynamicAtlasTexture.dispose();
				dynamicAtlasTexture = null;
			}
			if (dynamicAtlas) {
				dynamicAtlas.removeDrawable(this);
				dynamicAtlas = null;
			}
		}
		protected function disposeBitmapData():void {
			if (bitmapData) {
				bitmapData.dispose();
				bitmapData = null;
			}
		}
		private function disposeDrawnTexture():void {
			if (drawnTexture) {
				drawnTexture.dispose();
				drawnTexture = null;
			}
		}
		public function dispose():void {
			reset();
		}
	}

}
