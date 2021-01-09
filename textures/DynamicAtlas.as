package starlingEx.textures {

	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import starling.textures.Texture;
	import starling.utils.Pool;
	import starlingEx.textures.TextureBitmapData;
	import starlingEx.textures.TextureDrawable;
	import starlingEx.utils.RectanglePacker;
	import flash.geom.Point;

	public class DynamicAtlas extends RectanglePacker {
		static private var white_BMD:BitmapData;
		static private function initWhite():void {
			white_BMD = new BitmapData(1,1,false,0xffffff);
		}

		public var texture:Texture;
		public var mipMapping:Boolean;
		public var white_TB:TextureBitmapData;
		private var bitmapData:BitmapData;
		public function DynamicAtlas(addWhiteTexture:Boolean=true) {
			super(Texture.maxSize);
			if (addWhiteTexture) addWhite();
		}
		public function addWhite():void {
			if (white_BMD == null) initWhite();
			if (white_TB == null) {
				white_TB = new TextureBitmapData(white_BMD);
				white_TB.atlasExtrude = true;
			}
			addRectangle(white_TB);
		}
		override public function addRectangle(rect:Rectangle):void {
			if (rect is TextureBitmapData) {
				const textureBitmapData:TextureBitmapData = rect as TextureBitmapData;
				textureBitmapData.calcRectangle();
			}
			super.addRectangle(rect);
		}
		override protected function dispatchPackResult(packResult:Boolean):void {
			if (packResult) {
				initBitmap();
				drawRectangles();
				initTexture();
				//registerAtlas();
			}
			super.dispatchPackResult(packResult);
		}
		private function initBitmap():void {
			if (bitmapData) bitmapData.dispose();
			bitmapData = TextureDrawable.newBitmapData(bounds.width,bounds.height);
		}
		private function drawRectangles():void {
			const l:uint = packedA.length;
			for (var i:uint=0; i<l; i++) {
				const rect:Rectangle = packedA[i];
				if (rect is TextureBitmapData) {
					const textureBitmapData:TextureBitmapData = rect as TextureBitmapData;
					copyTextureBitmap(textureBitmapData);
				}
			}
		}
		private function copyTextureBitmap(textureBitmapData:TextureBitmapData,cleanTargetArea:Boolean=false):void {
			if (cleanTargetArea) bitmapData.fillRect(textureBitmapData,TextureDrawable.transparentGreenHex);
			textureBitmapData.copyPixelsTo(bitmapData);
			if (textureBitmapData.whiteFill) TextureDrawable.applyWhiteTransform(bitmapData,textureBitmapData);
			if (textureBitmapData.atlasExtrude) extrude(textureBitmapData);
			textureBitmapData.assignAtlas(this);
		}
		private function extrude(targetRect:Rectangle):void {
			const copyRect:Rectangle = Pool.getRectangle(targetRect.left,targetRect.top,targetRect.width,1);
			const copyPoint:Point = Pool.getPoint(copyRect.left,copyRect.top-1);
			bitmapData.copyPixels(bitmapData,copyRect,copyPoint);
			copyRect.y = targetRect.bottom - 1;
			copyPoint.y = targetRect.bottom;
			bitmapData.copyPixels(bitmapData,copyRect,copyPoint);
			copyRect.y = targetRect.top;
			copyRect.width = 1;
			copyRect.height = targetRect.height;
			copyPoint.x = copyRect.left - 1;
			copyPoint.y = copyRect.top;
			bitmapData.copyPixels(bitmapData,copyRect,copyPoint);
			copyRect.x = targetRect.right - 1;
			copyPoint.x = targetRect.right;
			bitmapData.copyPixels(bitmapData,copyRect,copyPoint);
			bitmapData.setPixel32(targetRect.left-1,targetRect.top-1,bitmapData.getPixel32(targetRect.left,targetRect.top));
			bitmapData.setPixel32(targetRect.right,targetRect.top-1,bitmapData.getPixel32(targetRect.right-1,targetRect.top));
			bitmapData.setPixel32(targetRect.left-1,targetRect.bottom,bitmapData.getPixel32(targetRect.left,targetRect.bottom-1));
			bitmapData.setPixel32(targetRect.right,targetRect.bottom,bitmapData.getPixel32(targetRect.right-1,targetRect.bottom-1));
			Pool.putRectangle(copyRect);
			Pool.putPoint(copyPoint);
		}
		private function initTexture():void {
			if (texture) texture.dispose();
			texture = Texture.fromBitmapData(bitmapData,mipMapping);
		}
		override protected function resetPackArrays():void {} //Do not put contents of pack arrays into Pool.putRectangle.
		override public function dispose():void {
			if (texture) {
				texture.dispose();
				texture = null;
			}
			if (white_TB) {
				white_TB.dispose();
				white_TB = null;
			}
			if (bitmapData) {
				bitmapData.dispose();
				bitmapData = null;
			}
			super.dispose();
		}
	}
	
}
