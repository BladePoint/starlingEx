// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.styles {

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import starling.rendering.MeshEffect;
	import starling.rendering.Program;
	import starling.rendering.VertexDataFormat;
	import starling.utils.StringUtil;
	import starlingEx.styles.ApertureDistanceFieldStyle;

	/** This class is appropriated from the bottom of starling.styles.DistanceFieldStyle where DistanceFieldEffect is defined. **/
	public class DistanceFieldEffect extends MeshEffect {
		static public const VERTEX_FORMAT:VertexDataFormat = ApertureDistanceFieldStyle.VERTEX_FORMAT;
		static public const MAX_OUTER_OFFSET:int = 8,
			MAX_SCALE:int = 8;
		static private const sVector:Vector.<Number> = new Vector.<Number>(4, true);
		static private function step(inOutReg:String,minReg:String,maxReg:String,tmpReg:String="ft6"):String {
			return [
				StringUtil.format("sub {0}, {1}, {2}", tmpReg, maxReg, minReg), // tmpReg = range
				StringUtil.format("rcp {0}, {0}", tmpReg),						// tmpReg = scale
				StringUtil.format("sub {0}, {0}, {1}", inOutReg, minReg),		// inOut -= minimum
				StringUtil.format("mul {0}, {0}, {1}", inOutReg, tmpReg),		// inOut *= scale
				StringUtil.format("sat {0}, {0}", inOutReg)						// clamp to 0-1
			].join("\n");
		}
		static private function median(inOutReg:String):String {
			return [
				StringUtil.format("max {0}.xyz, {0}.xxy, {0}.yzz", inOutReg),
				StringUtil.format("min {0}.x, {0}.x, {0}.y", inOutReg),
				StringUtil.format("min {0}, {0}.xxxx, {0}.zzzz", inOutReg)
			].join("\n");
		}

		private var _mode:String;
		private var _scale:Number;
		private var _multiChannel:Boolean;
		public function DistanceFieldEffect() {
			_scale = 1.0;
			_mode = ApertureDistanceFieldStyle.MODE_BASIC;
		}
		override protected function createProgram():Program {
			if (texture) {
				// va0 - position
				// va1 - tex coords
				// va2 - color
				// va3 - basic settings (threshold, alpha, softness, local scale [encoded])
				// va4 - outer settings (outerThreshold, outerAlphaEnd, outerOffsetX/Y)
				// va5 - outer color (rgb, outerAlphaStart)
				// vc5 - shadow offset multiplier (x, y), max local scale (z), global scale (w)
				const isBasicMode:Boolean  = _mode == ApertureDistanceFieldStyle.MODE_BASIC;
				const isShadowMode:Boolean = _mode == ApertureDistanceFieldStyle.MODE_SHADOW;
				/// *** VERTEX SHADER ***
				const vertexShader:Vector.<String> = new <String>[
					"m44 op, va0, vc0",       // 4x4 matrix transform to output clip-space
					"mov v0, va1",            // pass texture coordinates to fragment program
					"mul vt4, va3.yyyy, vc4", // multiply inner alpha (va3.y) with state alpha (vc4)
					"mul v1, va2, vt4",       // multiply vertex color (va2) with combined alpha (vt4)
					"mov v3, va3",
					"mov v4, va4",
					"mov v5, va5",
					// multiply outerAlphaStart and outerAlphaEnd with state alpha and vertex alpha
					"mul vt4.w, vc4.w, va2.w", // state alpha (vc4) * vertex alpha (va2.w)
					"mul v4.y, va4.y, vt4.w",  // v4.x = outerAlphaEnd
					"mul v5.w, va5.w, vt4.w",  // v5.w = outerAlphaStart
					// update softness to take current scale into account
					"mul vt0.x, va3.w, vc5.z", // vt0.x = local scale [decoded]
					"mul vt0.x, vt0.x, vc5.w", // vt0.x *= global scale
					"div vt0.x, va3.z, vt0.x", // vt0.x = softness / total scale
					// calculate min-max of threshold
					"mov vt1, vc4",             // initialize vt1 with something (anything)
					"sub vt1.x, va3.x, vt0.x",  // vt1.x = thresholdMin
					"add vt1.y, va3.x, vt0.x"   // vt1.y = thresholdMax
				];
				if (!isBasicMode) {
					vertexShader.push(
						// calculate min-max of outer threshold
						"sub vt1.z, va4.x, vt0.x",     // vt1.z = outerThresholdMin
						"add vt1.w, va4.x, vt0.x"      // vt1.w = outerThresholdMax
					);
				}
				vertexShader.push("sat v6, vt1"); // v6.xyzw = thresholdMin/Max, outerThresholdMin/Max
				if (isShadowMode) {
					vertexShader.push(
						// calculate shadow offset
						"mul vt0.xy, va4.zw, vc6.zz", // vt0.x/y = outerOffsetX/Y * 2
						"sub vt0.xy, vt0.xy, vc6.yy", // vt0.x/y -= 1   -> range -1, 1
						"mul vt0.xy, vt0.xy, vc5.xy", // vt0.x/y = outerOffsetX/Y in point size
						"sub v7, va1, vt0.xyxy",      // v7.xy = shadow tex coords
						// on shadows, the inner threshold is further inside than on glow & outline
						"sub vt0.z, va3.x, va4.x",    // get delta between threshold and outer threshold
						"add v7.z, va3.x, vt0.z"      // v7.z = inner threshold of shadow
					);
				}
				/// *** FRAGMENT SHADER ***
				const fragmentShader:Vector.<String> = new <String>[
					// create basic inner area
					tex("ft0", "v0", 0, texture),     // ft0 = texture color
					_multiChannel ? median("ft0") : "mov ft0, ft0.xxxx",
					"mov ft1, ft0",                   // ft1 = texture color
					step("ft1.w", "v6.x", "v6.y"),    // make soft inner mask
					"mov ft3, ft1",                   // store copy of inner mask in ft3 (for outline)
					"mul ft1, v1, ft1.wwww"           // multiply with color
				];
				if (isShadowMode) {
					fragmentShader.push(
						tex("ft0", "v7", 0, texture), // sample at shadow tex coords
						_multiChannel ? median("ft0") : "mov ft0, ft0.xxxx",
						"mov ft5.x, v7.z"             // ft5.x = inner threshold of shadow
					);
				}
				else if (!isBasicMode) {
					fragmentShader.push(
						"mov ft5.x, v6.x"             // ft5.x = inner threshold of outer area
					);
				}
				if (!isBasicMode) {
					fragmentShader.push(
						// outer area
						"mov ft2, ft0",                 // ft2 = texture color
						step("ft2.w", "v6.z", "v6.w"),  // make soft outer mask
						"sub ft2.w, ft2.w, ft3.w",      // subtract inner area
						"sat ft2.w, ft2.w",             // but stay within 0-1
						// add alpha gradient to outer area
						"mov ft4, ft0",                 // ft4 = texture color
						step("ft4.w", "v6.z", "ft5.x"), // make soft mask ranging between thresholds
						"sub ft6.w, v5.w, v4.y",        // ft6.w  = alpha range (outerAlphaStart - End)
						"mul ft4.w, ft4.w, ft6.w",      // ft4.w *= alpha range
						"add ft4.w, ft4.w, v4.y",       // ft4.w += alpha end
						// colorize outer area
						"mul ft2.w, ft2.w, ft4.w",      // get final outline alpha at this position
						"mul ft2.xyz, v5.xyz, ft2.www"  // multiply with outerColor
					);
				}
				if (isBasicMode) fragmentShader.push("mov oc, ft1");
				else             fragmentShader.push("add oc, ft1, ft2");
				return Program.fromSource(vertexShader.join("\n"), fragmentShader.join("\n"));
			}
			else return super.createProgram();
		}
		override protected function beforeDraw(context:Context3D):void {
			super.beforeDraw(context);
			if (texture) {
				vertexFormat.setVertexBufferAt(3, vertexBuffer, "basic");
				vertexFormat.setVertexBufferAt(4, vertexBuffer, "extended");
				vertexFormat.setVertexBufferAt(5, vertexBuffer, "outerColor");
				const pixelWidth:Number  = 1.0 / (texture.root.nativeWidth  / texture.scale),
					pixelHeight:Number = 1.0 / (texture.root.nativeHeight / texture.scale);
				sVector[0] = MAX_OUTER_OFFSET * pixelWidth;
				sVector[1] = MAX_OUTER_OFFSET * pixelHeight;
				sVector[2] = MAX_SCALE;
				sVector[3] = _scale;
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, sVector);
				sVector[0] = 0.0;
				sVector[1] = 1.0;
				sVector[2] = 2.0;
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 6, sVector);
			}
		}
		override protected function afterDraw(context:Context3D):void {
			if (texture) {
				context.setVertexBufferAt(3, null);
				context.setVertexBufferAt(4, null);
				context.setVertexBufferAt(5, null);
			}
			super.afterDraw(context);
		}
		override public function get vertexFormat():VertexDataFormat {
			return VERTEX_FORMAT;
		}
		override protected function get programVariantName():uint {
			var modeBits:uint;
			switch (_mode) {
				case ApertureDistanceFieldStyle.MODE_SHADOW:  modeBits = 3; break;
				case ApertureDistanceFieldStyle.MODE_GLOW:    modeBits = 2; break;
				case ApertureDistanceFieldStyle.MODE_OUTLINE: modeBits = 1; break;
				default:                              modeBits = 0;
			}
			if (_multiChannel) modeBits |= (1 << 2);
			return super.programVariantName | (modeBits << 8);
		}
		public function get scale():Number { return _scale; }
		public function set scale(value:Number):void { _scale = value; }
		public function get mode():String { return _mode; }
		public function set mode(value:String):void { _mode = value; }
		public function get multiChannel():Boolean { return _multiChannel; }
		public function set multiChannel(value:Boolean):void { _multiChannel = value; }
	}

}
