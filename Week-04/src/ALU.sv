typedef enum logic [2:0]{
	ADD = 0, SUB = 1, AND = 2, OR = 3, XOR = 4, SHIFT_LEFT = 5, SHIFT_RIGHT = 6
}alu_op_t;


module ALU # (parameter N = 16)(
	input logic [N-1:0] A, B,
	input alu_op_t OP,
	output logic [N-1:0] Result,
	output logic Carry, Zero 
);

always_comb begin 
	case (OP)
		ADD: begin
			{Carry, Result} = A + B;
		end
		SUB: begin
			Carry = (A<B);
			Result = A - B;
		end
		AND: begin
			Result = A & B;
			Carry = 1'b0;
		end
		OR: begin
			Result = A | B;
			Carry = 1'b0;
		end
		XOR: begin
			Result = A ^ B;
			Carry = 1'b0;
		end
		SHIFT_LEFT: begin
			Carry = A[N-1];
			Result = A << B;   
		end
		SHIFT_RIGHT: begin
			Carry = A[0];
			Result = A >> B;  
		end
	endcase
	
	Zero = (Result == 0);
end
endmodule
