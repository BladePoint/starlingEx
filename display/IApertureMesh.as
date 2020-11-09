// StarlingEx - https://github.com/BladePoint/StarlingEx
// Copyright Doublehead Games, LLC. All rights reserved.
// This code is open source under the MIT License - https://github.com/BladePoint/StarlingEx/blob/master/docs/LICENSE
// Use in conjunction with Starling - https://gamua.com/starling/

package starlingEx.display {

	public interface IApertureMesh {

		function applyVertexMult(vertexID:uint):void;
		function set color(value:uint):void;
		function get color():uint;
		function setVertexColor(vertexID:int,colorHex:uint):void;

	}

}
