module LCD12864 (clk, rs, rw, en,dat);  
input clk;  
 output [7:0] dat; 
 output  rs,rw,en; 
 //tri en; 
 reg e; 
 reg [7:0] dat; 
 reg rs;   
 reg  [15:0] counter; 
 reg [5:0] current,next; 
 reg clkr; 
 reg [1:0] cnt; 

 reg [7:0] mem [0:1023];
 reg [10:0] mem_index;
 
 
 parameter  set0=6'h0; 
 parameter  set1=6'h1; 
 parameter  set2=6'h2; 
 parameter  set3=6'h3; 
 parameter  set4=6'h4; 
 parameter  set5=6'h5;
 parameter  set6=6'h6;  

 
 parameter address_vertical = 7, address_horizontal=8;
 parameter data0=9, data1=10, data2=11, data3=12;
 
 parameter  row0=6'h7; 
 parameter  row1=6'h8; 
 parameter  row2=6'h9; 
 parameter  row3=6'hA;
 
 parameter  loop=6'h2F; 
 parameter  nul=6'h3F;  
 
 task write_pixels;
	input [5:0] next_state;
	
	begin
		rs <= 1;
		dat <= mem[mem_index];
		mem_index <= mem_index + 1;
		if(mem_index == 1023) begin
			next <= next_state;
		end
 endtask;
 
 task write_row;
	input [2:0] mem_row;
	input [5:0] next_state;

	begin
		rs <= 1;
		dat <= mem[mem_row*16 + mem_index];
		mem_index <= mem_index + 1;
		if(mem_index == 15) begin
			next <= next_state;
		end
	end
 endtask
 
 initial begin;
	$readmemb("rom.txt", mem);
 end
 
always @(posedge clk)        
 begin 
  counter=counter+1; 
  if(counter==16'h000f)  
  clkr=~clkr; 
end 
always @(posedge clkr) 
begin 
 current=next; 
  case(current) 
    set0:   begin  rs<=0; dat<=8'b00110110; next<=set1; end //00110000 - set 8-bit interface, extended instruction set, graphic on
    set1:   begin  rs<=0; dat<=8'h0c; next<=set2; end //00001100 - display on, cursor off, blink off
    set2:   begin  rs<=0; dat<=8'h6; next<=set3; end  //00000110 - set cursor position and display shift?
    set3:   begin  rs<=0; dat<=8'h1; next<=address_vertical; mem_index <= 0; end  //CLEAR
	 
	 //GDRAM address is set by writing 2 consecutive bytes for vertical address and horizontal address. Two-bytes data write to GDRAM for one address. Address counter will automatically increase by one for the next two-byte data. The procedure is as followings. 
	 //set GDRAM address 0,0
	 //write 0101001100011100
	 
	 address_vertical: begin rs <= 0;   dat <= 8'b10000000; next<=address_horizontal; end
	 address_horizontal: begin rs <= 0; dat <= 8'b10000000; next<=data0; end
	 
	 data0: begin rs <= 1; dat <= 8'b01010011; next<=data1; end
	 data1: begin rs <= 1; dat <= 8'b00011100; next<=data2; end
	 data2: begin rs <= 1; dat <= 8'b00111100; next<=data3; end
	 data3: begin rs <= 1; dat <= 8'b00011111; next<=loop; end
	 
	  
//	 row0: begin
//		write_row(0, set4);
//	 end
//
	  loop: begin rs <= 0; dat<=8'h00000001; /*standby*/  next <= loop; end

	 //reset?
//     nul:   begin rs<=0;  dat<=8'h00;                    //???
//              if(cnt!=2'h2)  
//                  begin  
//                       e<=0;next<=set0;cnt<=cnt+1;  
//                  end  
//                   else  
//                     begin next<=nul; e<=1; 
//                    end    
//              end 
   default:   next=set0; 
    endcase 
 end 
assign en=clkr|e; 
assign rw=0; 
endmodule  