// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.text {

	import starlingEx.display.ApertureQuad;
	import starlingEx.display.ApertureSprite;
	import starlingEx.display.ButtonEx;
	import starlingEx.text.CharLocation;

	/* Clickable TextLinks are created when parsing link tags in an ApertureTextField. */
	public class TextLink extends ButtonEx {
		static private const defaultNormalHex:uint = 0x0077cc,
			defaultHoverHex:uint = 0x0095ff;
		static public var defaultNormalTopLeft:uint = defaultNormalHex,
			defaultNormalTopRight:uint = defaultNormalHex,
			defaultNormalBottomLeft:uint = defaultNormalHex,
			defaultNormalBottomRight:uint = defaultNormalHex,
			defaultNormalOutlineColor:uint = defaultNormalHex,
			defaultHoverTopLeft:uint = defaultHoverHex,
			defaultHoverTopRight:uint = defaultHoverHex,
			defaultHoverBottomLeft:uint = defaultHoverHex,
			defaultHoverBottomRight:uint = defaultHoverHex,
			defaultHoverOutlineColor:uint = defaultHoverHex;
		static public var defaultNormalWidth:Number = 0,
			defaultHoverWidth:Number = 0;
		static private const textLinkV:Vector.<TextLink> = new <TextLink>[];
		static public function getInstance(size:Number,underlineProportion:Number,normalTopLeft:int=-1,normalTopRight:int=-1,normalBottomLeft:int=-1,normalBottomRight:int=-1,normalOutlineColor:int=-1,hoverTopLeft:int=-1,hoverTopRight:int=-1,hoverBottomLeft:int=-1,hoverBottomRight:int=-1,hoverOutlineColor:int=-1,normalOutlineWidth:Number=-1,hoverOutlineWidth:Number=-1):TextLink {
			var textLink:TextLink;
			if (textLinkV.length == 0) textLink = new TextLink(size,underlineProportion,normalTopLeft,normalTopRight,normalBottomLeft,normalBottomRight,normalOutlineColor,hoverTopLeft,hoverTopRight,hoverBottomLeft,hoverBottomRight,hoverOutlineColor,normalOutlineWidth,hoverOutlineWidth);
			else {
				textLink = textLinkV.pop();
				textLink.init(size,underlineProportion,normalTopLeft,normalTopRight,normalBottomLeft,normalBottomRight,normalOutlineColor,hoverTopLeft,hoverTopRight,hoverBottomLeft,hoverBottomRight,hoverOutlineColor,normalOutlineWidth,hoverOutlineWidth);
			}
			return textLink;
		}
		static public function putInstance(textLink:TextLink):void {
			if (textLink) {
				textLink.reset();
				textLinkV[textLinkV.length] = textLink;
			}
		}
		static private const vectorPool:Array = [];
		static public function getVector():Vector.<TextLink> {
			var vector:Vector.<TextLink>;
			if (vectorPool.length == 0) vector = new <TextLink>[];
			else vector = vectorPool.pop();
			return vector;
		}
		static public function putVector(vector:Vector.<TextLink>):void {
			if (vector) {
				vector.length = 0;
				vectorPool[vectorPool.length] = vector;
			}
		}
		static private const hitboxV:Vector.<ApertureQuad> = new <ApertureQuad>[];
		static private function getHitbox(w:Number,h:Number):ApertureQuad {
			var hitbox_AQ:ApertureQuad;
			if (hitboxV.length == 0) hitbox_AQ = new ApertureQuad(w,h);
			else {
				hitbox_AQ = hitboxV.pop();
				hitbox_AQ.readjustSize(w,h);
			}
			return hitbox_AQ;
		}
		static public function putHitbox(hitbox_AQ:ApertureQuad):void {
			if (hitbox_AQ) hitboxV[hitboxV.length] = hitbox_AQ;
		}
		static private const NORMAL:String = "normal",
			HOVER:String = "hover";
		
		public var charLocationV:Vector.<CharLocation>;
		public var getTextLineQuad:Function, putTextLineQuad:Function;
		public var multiChannel:Boolean;
		private var aboveLineH:Number, normalOutlineWidth:Number, hoverOutlineWidth:Number;
		private var normalTopLeft:uint, normalTopRight:uint, normalBottomLeft:uint, normalBottomRight:uint,
			hoverTopLeft:uint, hoverTopRight:uint, hoverBottomLeft:uint, hoverBottomRight:uint,
			normalOutlineColor:uint, hoverOutlineColor:uint;
		private var hitbox_AS:ApertureSprite;
		public function TextLink(size:Number,underlineProportion:Number,normalTopLeft:int=-1,normalTopRight:int=-1,normalBottomLeft:int=-1,normalBottomRight:int=-1,normalOutlineColor:int=-1,hoverTopLeft:int=-1,hoverTopRight:int=-1,hoverBottomLeft:int=-1,hoverBottomRight:int=-1,hoverOutlineColor:int=-1,normalOutlineWidth:Number=-1,hoverOutlineWidth:Number=-1) {
			init(size,underlineProportion,normalTopLeft,normalTopRight,normalBottomLeft,normalBottomRight,normalOutlineColor,hoverTopLeft,hoverTopRight,hoverBottomLeft,hoverBottomRight,hoverOutlineColor,normalOutlineWidth,hoverOutlineWidth);
			hitbox_AS = new ApertureSprite();
			hitbox_AS.alpha = 0;
			super(hitbox_AS,null);
			disableOnClick = false;
		}
		private function init(size:Number,underlineProportion:Number,normalTopLeft:int,normalTopRight:int,normalBottomLeft:int,normalBottomRight:int,normalOutlineColor:int,hoverTopLeft:int,hoverTopRight:int,hoverBottomLeft:int,hoverBottomRight:int,hoverOutlineColor:int,normalOutlineWidth:Number,hoverOutlineWidth:Number):void {
			aboveLineH = size * underlineProportion;
			this.normalTopLeft = normalTopLeft >= 0 ? normalTopLeft : defaultNormalTopLeft;
			this.normalTopRight = normalTopRight >= 0 ? normalTopRight : defaultNormalTopRight;
			this.normalBottomLeft = normalBottomLeft >= 0 ? normalBottomLeft : defaultNormalBottomLeft;
			this.normalBottomRight = normalBottomRight >= 0 ? normalBottomRight : defaultNormalBottomRight;
			this.normalOutlineColor = normalOutlineColor >= 0 ? normalOutlineColor : defaultNormalOutlineColor;
			this.hoverTopLeft = hoverTopLeft >= 0 ? hoverTopLeft : defaultHoverTopLeft;
			this.hoverTopRight = hoverTopRight >= 0 ? hoverTopRight : defaultHoverTopRight;
			this.hoverBottomLeft = hoverBottomLeft >= 0 ? hoverBottomLeft : defaultHoverBottomLeft;
			this.hoverBottomRight = hoverBottomRight >= 0 ? hoverBottomRight : defaultHoverBottomRight;
			this.hoverOutlineColor = hoverOutlineColor >= 0 ? hoverOutlineColor : defaultHoverOutlineColor;
			this.normalOutlineWidth = normalOutlineWidth >= 0 ? normalOutlineWidth : defaultNormalWidth;
			this.hoverOutlineWidth = hoverOutlineWidth >= 0 ? hoverOutlineWidth : defaultHoverWidth;
			charLocationV = CharLocation.getVector();
		}
		public function addCharLocation(charLocation:CharLocation,lastChar:Boolean=false):void {
			charLocationV[charLocationV.length] = charLocation;
			if (lastChar) {
				resizeHitbox();
				setColor(NORMAL);
				setOutline(NORMAL);
			}
		}
		private function resizeHitbox():void {
			const charLocation:CharLocation = charLocationV[0];
			const innerLinkA:Array = charLocation.innerLinkA;
			const l:uint = innerLinkA.length;
			for (var i:uint=0; i<l; i++) {
				const line_AQ:ApertureQuad = innerLinkA[i];
				const hitbox_AQ:ApertureQuad = getHitbox(line_AQ.quadW,aboveLineH+line_AQ.quadH);
				hitbox_AQ.x = line_AQ.x;
				hitbox_AQ.y = line_AQ.y - aboveLineH;
				hitbox_AS.addChild(hitbox_AQ);
			}
		}
		public function setColor(linkStatus:String):void {
			var topLeft:uint, topRight:uint, bottomLeft:uint, bottomRight:uint;
			if (linkStatus == NORMAL) {
				topLeft = normalTopLeft;
				topRight = normalTopRight;
				bottomLeft = normalBottomLeft;
				bottomRight = normalBottomRight;
			} else if (linkStatus == HOVER) {
				topLeft = hoverTopLeft;
				topRight = hoverTopRight;
				bottomLeft = hoverBottomLeft;
				bottomRight = hoverBottomRight;
			}
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				charLocation.updateColor(topLeft,topRight,bottomLeft,bottomRight,true);
			}
		}
		private function setOutline(linkStatus:String):void {
			var outlineColor:uint;
			var outlineWidth:Number;
			if (linkStatus == NORMAL) {
				outlineColor = normalOutlineColor;
				outlineWidth = normalOutlineWidth;
			} else if (linkStatus == HOVER) {
				outlineColor = hoverOutlineColor;
				outlineWidth = hoverOutlineWidth;
			}
			var changeColor:Boolean,
				changeWidth:Boolean;
			if (normalOutlineColor != hoverOutlineColor) changeColor = true;
			if (normalOutlineWidth != hoverOutlineWidth) changeWidth = true;
			if (changeColor && !changeWidth) updateOutlineColor(outlineColor);
			else if (!changeColor && changeWidth) updateOutlineWidth(outlineWidth);
			else if (changeColor && changeWidth) setupOutline(outlineColor,outlineWidth);
			
		}
		private function updateOutlineColor(outlineColor:uint):void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				charLocation.updateOutlineColor(outlineColor,true);
			}
		}
		private function updateOutlineWidth(outlineWidth:Number):void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				charLocation.updateOutlineWidth(outlineWidth);
			}
		}
		private function setupOutline(outlineColor:uint,outlineWidth:Number):void {
			const l:uint = charLocationV.length;
			for (var i:uint=0; i<l; i++) {
				const charLocation:CharLocation = charLocationV[i];
				charLocation.setupOutline(outlineColor,outlineWidth);
			}
		}
		override protected function mouseOutMethod():void {
			setColor(NORMAL);
			setOutline(NORMAL);
		}
		override protected function mouseOverMethod():void {
			setColor(HOVER);
			setOutline(HOVER);
		}
		public function reset():void {
			CharLocation.putVector(charLocationV);
			charLocationV = null;
			while (hitbox_AS.numChildren > 0) {
				const hitbox_AQ:ApertureQuad = hitbox_AS.getChildAt(0) as ApertureQuad;
				hitbox_AS.removeChild(hitbox_AQ);
				putHitbox(hitbox_AQ);
			}
			getTextLineQuad = putTextLineQuad = null;
		}
		override public function dispose():void {
			reset();
			hitbox_AS.dispose();
			hitbox_AS = null;
			super.dispose();
		}
	}

}
