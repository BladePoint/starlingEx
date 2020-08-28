package starlingEx.display {

	public interface IApertureMesh {

		function applyVertexMult(vertexID:uint):void;
		function set color(value:uint):void;
		function get color():uint;
		function setVertexColor(vertexID:int,colorHex:uint):void;

	}

}
