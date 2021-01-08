// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.styles {

	import flash.geom.Matrix;
	import starling.core.Starling;
	import starling.display.Mesh;
	import starling.rendering.MeshEffect;
	import starling.rendering.RenderState;
	import starling.rendering.VertexData;
	import starling.rendering.VertexDataFormat;
	import starling.styles.MeshStyle;
	import starling.utils.MathUtil;
	import starlingEx.display.ApertureObject;
	import starlingEx.display.ApertureUtils;
	import starlingEx.display.IAperture;
	import starlingEx.styles.DistanceFieldEffect;
	import starlingEx.utils.PoolEx;

	/** Much of this code is appropriated from starling.styles.DistanceFieldStyle, which was not extended because of its private updateVertices method. */
	public class ApertureDistanceFieldStyle extends MeshStyle implements IAperture {
		static public const VERTEX_FORMAT:VertexDataFormat = MeshStyle.VERTEX_FORMAT.extend("basic:bytes4, extended:bytes4, outerColor:bytes4");
		static public const MODE_BASIC:String = "basic",
			MODE_OUTLINE:String = "outline",
			MODE_GLOW:String = "glow",
			MODE_SHADOW:String = "shadow";

		private var _mode:String;
		private var _multiChannel:Boolean;
		private var _threshold:Number,		// basic
			_alpha:Number,
			_softness:Number,
			_outerThreshold:Number,			// extended
			_outerAlphaEnd:Number,
			_shadowOffsetX:Number,
			_shadowOffsetY:Number,
			_outerAlphaStart:Number;		// outerColor
		private var outerTrue_AO:ApertureObject, outerMult_AO:ApertureObject;
		private var _apertureLock:Boolean;
		public function ApertureDistanceFieldStyle(softness:Number=.125,threshold:Number=.5) {
			_mode = MODE_BASIC;
			_threshold = threshold;
			_softness = softness;
			_alpha = 1.0;
			_outerThreshold = _outerAlphaEnd = 0;
			_shadowOffsetX = _shadowOffsetY = 0;
			_outerAlphaStart = 0;
			outerTrue_AO = ApertureObject.getInstance(0x000000);
			outerMult_AO = ApertureObject.getInstance(0x000000);
		}
		override public function copyFrom(meshStyle:MeshStyle):void {
			const otherStyle:ApertureDistanceFieldStyle = meshStyle as ApertureDistanceFieldStyle;
			if (otherStyle) {
				_mode = otherStyle._mode;
				_multiChannel = otherStyle._multiChannel;
				_threshold = otherStyle._threshold;
				_softness = otherStyle._softness;
				_alpha = otherStyle._alpha;
				_outerThreshold = otherStyle._outerThreshold;
				_outerAlphaEnd  = otherStyle._outerAlphaEnd;
				_shadowOffsetX  = otherStyle._shadowOffsetX;
				_shadowOffsetY  = otherStyle._shadowOffsetY;
				_outerAlphaStart = otherStyle._outerAlphaStart;
				outerTrue_AO.hex = otherStyle.outerTrue_AO.hex;
				outerMult_AO.hex = otherStyle.outerMult_AO.hex;
			}
			super.copyFrom(meshStyle);
		}
		override public function createEffect():MeshEffect {
			return new DistanceFieldEffect();
		}
		override public function get vertexFormat():VertexDataFormat {
			return VERTEX_FORMAT;
		}
		override protected function onTargetAssigned(target:Mesh):void {
			updateVertices();
		}
		public function setHex(colorHex:uint=0xffffff,apply:Boolean=true):void {
			if (outerTrue_AO.hex != colorHex) {
				outerTrue_AO.hex = colorHex;
				if (apply) multiplyColor();
			}
		}
		public function getHex(index:uint=0):uint {return outerTrue_AO.hex;}
		public function setRGB(r:uint=255,g:uint=255,b:uint=255,apply:Boolean=true):void {
			if (outerTrue_AO.r != r && outerTrue_AO.g != g && outerTrue_AO.b != b) {
				outerTrue_AO.rgb(r,g,b);
				if (apply) multiplyColor();
			}
		}
		public function getRGB(index:uint=0):Array {
			var returnA:Array = PoolEx.getArray();
			returnA[0] = outerTrue_AO.r;
			returnA[1] = outerTrue_AO.g;
			returnA[2] = outerTrue_AO.b;
			return returnA;
		}
		public function setAperture(decimal:Number,apply:Boolean=true):void {
			if (decimal < 0 || decimal > 1) return;
			const roundInt:uint = Math.round(decimal*255);
			setRGB(roundInt,roundInt,roundInt,apply);
		}
		public function set apertureLock(boolean:Boolean):void {_apertureLock = boolean;}
		public function get apertureLock():Boolean {return _apertureLock;}
		public function multiplyColor():void {
			ApertureUtils.multiplyStyle(this);
			updateVertices();
		}
		public function calcMult(parentMult_AO:ApertureObject,index:uint=0):void {
			if (parentMult_AO) outerMult_AO.hex = ApertureObject.multiply(outerTrue_AO,parentMult_AO);
			else outerMult_AO.hex = outerTrue_AO.hex;
		}
		private function updateVertices():void {
			if (vertexData == null) return;
			const numVertices:int = vertexData.numVertices;
			const maxScale:int = DistanceFieldEffect.MAX_SCALE;
			const maxOuterOffset:int = DistanceFieldEffect.MAX_OUTER_OFFSET;
			const encodedOuterOffsetX:Number = (_shadowOffsetX + maxOuterOffset) / (2 * maxOuterOffset);
			const encodedOuterOffsetY:Number = (_shadowOffsetY + maxOuterOffset) / (2 * maxOuterOffset);
			const basic:uint = (uint(_threshold      * 255)      ) |
							 (uint(_alpha          * 255) <<  8) |
							 (uint(_softness / 2.0 * 255) << 16) |
							 (uint(1.0 / maxScale  * 255) << 24);
			const extended:uint = (uint(_outerThreshold     * 255)      ) |
								(uint(_outerAlphaEnd      * 255) <<  8) |
								(uint(encodedOuterOffsetX * 255) << 16) |
								(uint(encodedOuterOffsetY * 255) << 24);
			const outerColor:uint = (outerMult_AO.r			  ) |
								  (outerMult_AO.g		 <<  8) |
								  (outerMult_AO.b		 << 16) |
								  (uint(_outerAlphaStart * 255) << 24);
			for (var i:int=0; i<numVertices; ++i) {
				vertexData.setUnsignedInt(i,"basic",basic);
				vertexData.setUnsignedInt(i,"extended",extended);
				vertexData.setUnsignedInt(i,"outerColor",outerColor);
			}
			setVertexDataChanged();
		}
		override public function batchVertexData(targetStyle:MeshStyle,targetVertexID:int=0,matrix:Matrix=null,vertexID:int=0,numVertices:int=-1):void {
			super.batchVertexData(targetStyle,targetVertexID,matrix,vertexID,numVertices);
			if (matrix) {
				const scale:Number = Math.sqrt(matrix.a*matrix.a + matrix.c*matrix.c);
				if (!MathUtil.isEquivalent(scale,1.0,0.01)) {
					const targetVertexData:VertexData = (targetStyle as ApertureDistanceFieldStyle).vertexData;
					const maxScale:Number = DistanceFieldEffect.MAX_SCALE;
					const minScale:Number = maxScale / 255;
					if (numVertices < 0) numVertices = vertexData.numVertices - vertexID;
					for (var i:int=0; i<numVertices; ++i) {
						const srcAttr:uint = vertexData.getUnsignedInt(vertexID+i,"basic");
						const srcScale:Number = ((srcAttr >> 24) & 0xff) / 255.0 * maxScale;
						const tgtScale:Number = MathUtil.clamp(srcScale*scale,minScale,maxScale);
						const tgtAttr:uint = (srcAttr & 0x00ffffff) | (uint(tgtScale/maxScale*255) << 24);
                        targetVertexData.setUnsignedInt(targetVertexID+i,"basic",tgtAttr);
					}
				}
			}
		}
		override public function updateEffect(effect:MeshEffect,state:RenderState):void {
			const dfEffect:DistanceFieldEffect = effect as DistanceFieldEffect;
			dfEffect.mode = _mode;
			dfEffect.multiChannel = _multiChannel;
			if (state.is3D) dfEffect.scale = 1.0;
			else {
				const matrix:Matrix = state.modelviewMatrix;
				const scale:Number = Math.sqrt(matrix.a*matrix.a + matrix.c*matrix.c);
				dfEffect.scale = scale * Starling.contentScaleFactor;
			}
			super.updateEffect(effect, state);
		}
		override public function canBatchWith(meshStyle:MeshStyle):Boolean {
			const adfStyle:ApertureDistanceFieldStyle = meshStyle as ApertureDistanceFieldStyle;
			if (adfStyle && super.canBatchWith(meshStyle)) return adfStyle._mode == _mode && adfStyle._multiChannel == _multiChannel;
			else return false;
		}
		public function setupBasic():void {
			_mode = MODE_BASIC;
			setRequiresRedraw();
		}
		public function setupOutline(width:Number=.25,color:uint=0x000000,alpha:Number=1,apply:Boolean=true):void {
			_mode = MODE_OUTLINE;
			_outerThreshold = MathUtil.clamp(_threshold-width,0,_threshold);
			_outerAlphaStart = _outerAlphaEnd = MathUtil.clamp(alpha,0,1);
			_shadowOffsetX = _shadowOffsetY = 0.0;
			outerTrue_AO.hex = color;
			if (apply) multiplyColor();
		}
		public function setupGlow(blur:Number=0.2,color:uint=0xffff00,alpha:Number=0.5,apply:Boolean=true):void {
			_mode = MODE_GLOW;
			_outerThreshold = MathUtil.clamp(_threshold-blur,0,_threshold);
			_outerAlphaStart = MathUtil.clamp(alpha,0,1);
			_outerAlphaEnd = 0.0;
			_shadowOffsetX = _shadowOffsetY = 0.0;
			outerTrue_AO.hex = color;
			if (apply) multiplyColor();
		}
		public function setupDropShadow(blur:Number=0.2,offsetX:Number=2,offsetY:Number=2,color:uint=0x0,alpha:Number=0.5,apply:Boolean=true):void {
			const maxOffset:Number = DistanceFieldEffect.MAX_OUTER_OFFSET;
			_mode = MODE_SHADOW;
			_outerThreshold = MathUtil.clamp(_threshold-blur,0,_threshold);
			_outerAlphaStart = MathUtil.clamp(alpha, 0, 1);
			_outerAlphaEnd = 0.0;
			_shadowOffsetX = MathUtil.clamp(offsetX, -maxOffset, maxOffset);
			_shadowOffsetY = MathUtil.clamp(offsetY, -maxOffset, maxOffset);
			outerTrue_AO.hex = color;
			if (apply) multiplyColor();
		}
		public function get mode():String {return _mode;}
		public function set mode(value:String):void {
			_mode = value;
			setRequiresRedraw();
		}
		public function get multiChannel():Boolean {return _multiChannel;}
		public function set multiChannel(value:Boolean):void {
			_multiChannel = value;
			setRequiresRedraw();
		}
		public function get threshold():Number {return _threshold;}
		public function set threshold(value:Number):void {
			value = MathUtil.clamp(value, 0, 1);
			if (_threshold != value) {
				_threshold = value;
				updateVertices();
			}
		}
		public function get softness():Number {return _softness;}
		public function set softness(value:Number):void {
			value = MathUtil.clamp(value, 0, 1);
			if (_softness != value) {
				_softness = value;
				updateVertices();
			}
		}
		public function get alpha():Number {return _alpha;}
		public function set alpha(value:Number):void {
			value = MathUtil.clamp(value,0,1);
			if (_alpha != value) {
				_alpha = value;
				updateVertices();
			}
		}
		public function get outerThreshold():Number {return _outerThreshold;}
		public function set outerThreshold(value:Number):void {
			value = MathUtil.clamp(value,0,1);
			if (_outerThreshold != value) {
				_outerThreshold = value;
				updateVertices();
			}
		}
		public function get outerAlphaStart():Number {return _outerAlphaStart;}
		public function set outerAlphaStart(value:Number):void {
			value = MathUtil.clamp(value, 0, 1);
			if (_outerAlphaStart != value) {
				_outerAlphaStart = value;
				updateVertices();
			}
		}
		public function get outerAlphaEnd():Number {return _outerAlphaEnd;}
		public function set outerAlphaEnd(value:Number):void {
			value = MathUtil.clamp(value,0,1);
			if (_outerAlphaEnd != value) {
				_outerAlphaEnd = value;
				updateVertices();
			}
		}
		public function get shadowOffsetX():Number {return _shadowOffsetX;}
		public function set shadowOffsetX(value:Number):void {
			const max:Number = DistanceFieldEffect.MAX_OUTER_OFFSET;
			value = MathUtil.clamp(value, -max, max);
			if (_shadowOffsetX != value) {
				_shadowOffsetX = value;
				updateVertices();
			}
		}
		public function get shadowOffsetY():Number {return _shadowOffsetY;}
		public function set shadowOffsetY(value:Number):void {
			const max:Number = DistanceFieldEffect.MAX_OUTER_OFFSET;
			value = MathUtil.clamp(value, -max, max);
			if (_shadowOffsetY != value) {
				_shadowOffsetY = value;
				updateVertices();
			}
		}
		public function dispose():void {
			ApertureObject.putInstance(outerTrue_AO);
			ApertureObject.putInstance(outerMult_AO);
			outerTrue_AO = outerMult_AO = null;
		}

	}

}
