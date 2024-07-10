// Generated by alg3
`timescale 1ns/10ps

`include "remuldefs_ref.svh"

typedef reg [31:0] Raddr_ref;
typedef reg signed [31:0] Rdata_ref;
reg reset;

Raddr_ref PC_ref;
Rdata_ref mem_ref[Raddr_ref];
reg signed [31:0] Reg_ref[31:0];
iunion_ref inst_ref;
reg [63:0] icnt_ref;
Rdata_ref finishedcode_ref;


function Rdata_ref MEM_ref(Raddr_ref r);
    if ( (!(^r===1'bX)) && mem_ref.exists(r&32'hffff_fffc))
    return mem_ref[r&32'hffff_fffc];
    return 32'hXXXX_XXXX;
endfunction : MEM_ref

task WMEM_ref(Raddr_ref r,Rdata_ref d);
    $display(r);
    if(r==32'h8000_0018) begin
        finishedcode_ref=d;
    	$display(finishedcode_ref);
    end
    mem_ref[r&32'hffff_fffc]=d;
endtask : WMEM_ref

task unsupported_ref();
    $error("invalid instruction code %h",inst_ref.I.opcode5);
    $finish;
endtask : unsupported_ref

task wreg_ref(input reg [4:0] ra,Rdata_ref rd);
    if(ra != 0) Reg_ref[ra]=rd;
endtask : wreg_ref

function Rdata_ref REG_ref(reg [4:0] rix);
    if(rix==0) return 0;
    return Reg_ref[rix];
endfunction : REG_ref

function Rdata_ref SE8_ref(input reg [7:0] bd);
    return {((bd[7])?24'hFFFF_FF:24'h0),bd};
endfunction : SE8_ref

function Rdata_ref SE16_ref(input reg [15:0] bd);
    return {((bd[15])?16'hFF:16'h0),bd};
endfunction : SE16_ref

function Rdata_ref SE12_ref(input reg [11:0] bd);
    return {((bd[11])?20'hFFFFF:20'h00000),bd};
endfunction : SE12_ref

function Raddr_ref eaI_ref();
    Raddr_ref wa,se;
    se=SE12_ref(inst_ref.I.imm12);
    //$display("inst_ref %h imm12 %h of eaI_ref %h and reg is %0h",
        //inst_ref.raw,inst_ref.I.imm12,se,inst_ref.I.rs1);
    wa=REG_ref(inst_ref.I.rs1)+SE12_ref(inst_ref.I.imm12);
    
	//$display("wa = %0h reg addr is %0h",wa,inst_ref.I.rs1);
    return wa;
endfunction : eaI_ref

task LB_ref();
    Raddr_ref ma;
    Rdata_ref rd;
    ma=eaI_ref();
    rd=SE8_ref(32'hff&(MEM_ref(ma&32'hffff_fffe)>>((ma&3)*8)));
    //$display("rd = %0h and reg is %0h",rd,inst_ref.I.rd);
    wreg_ref(inst_ref.I.rd,rd);
endtask : LB_ref

task LBU_ref();
    Rdata_ref rd;
    Raddr_ref ma;
    ma=eaI_ref();
    rd=32'hff&(MEM_ref(ma&32'hffff_fffe)>>((ma&3)*8));
    wreg_ref(inst_ref.I.rd,rd);
endtask : LBU_ref

task LH_ref();
    Rdata_ref res;
    reg [63:0] rd;
    Raddr_ref ma;
    ma=eaI_ref();
    rd = {MEM_ref((ma&32'hFFFF_FFFF)+4),MEM_ref(ma&32'hFFFF_FFFF)};
    res = (rd>>((ma&1)*16))&32'hFFFF;
    res=SE16_ref(res);
    wreg_ref(inst_ref.I.rd,res);
endtask : LH_ref

task LHU_ref();
    Raddr_ref ma;
    Rdata_ref res;
    reg [63:0] rd;
    ma=eaI_ref();
    rd = {MEM_ref((ma&32'hFFFF_FFFF)+4),MEM_ref(ma&32'hFFFF_FFFF)};
    res = (rd>>((ma&1)*16))&32'hFFFF;
    wreg_ref(inst_ref.I.rd,res);
endtask : LHU_ref

task LW_ref();
    Raddr_ref ma;
    Rdata_ref res;
    reg [63:0] rd;
    ma=eaI_ref();
    //$display("LW_ref inst_ref %h Fetching word from %h",inst_ref.raw,ma);
    rd = {MEM_ref(ma+4),MEM_ref(ma)};
    //$display("selected from %h",rd);
    res = (rd>>((ma&3)*8)) & 32'hFFFFffff;
    //$display("Results are %h",res);
    wreg_ref(inst_ref.I.rd,res);
endtask : LW_ref

task nextIns_ref();
    PC_ref=PC_ref+4;
endtask : nextIns_ref

function Raddr_ref SE13_ref(Raddr_ref v);
    if (v[12]) begin
        return {19'h7ffff,v[12:0]};
    end
    return v;
endfunction : SE13_ref

function Raddr_ref Btar_ref();
    Raddr_ref rn;
    rn=(inst_ref.B.imm4_1_11)&32'h1e;
    rn|=((inst_ref.B.imm12_10_5)&32'h1f)<<5;
    rn|=((inst_ref.B.imm4_1_11)&1)<<11;
    rn|=(inst_ref.B.imm12_10_5[5:0])<<5;
    rn|=(inst_ref.B.imm12_10_5[6])<<12;
    //$display("PC_ref %h rn %h se13 %d",PC_ref,rn,$signed(SE13_ref(rn)));
    return SE13_ref(rn)+PC_ref;
endfunction : Btar_ref

task BEQ_ref();
    if (REG_ref(inst_ref.B.rs1)==REG_ref(inst_ref.B.rs2)) begin
        PC_ref=Btar_ref();
    end else begin
        nextIns_ref;
    end
endtask : BEQ_ref

task BNE_ref();
    if (REG_ref(inst_ref.B.rs1)!=REG_ref(inst_ref.B.rs2)) begin
        PC_ref=Btar_ref();
    end else begin
        nextIns_ref;
    end
endtask : BNE_ref

task BLT_ref();
    if (REG_ref(inst_ref.B.rs1)<REG_ref(inst_ref.B.rs2)) begin
//        //$display("BLT_ref taking branch");
        PC_ref=Btar_ref();
//        //$display("New PC_ref is %h",PC_ref);
    end else begin
        nextIns_ref;
    end
endtask : BLT_ref

task BLTU_ref();
    if ($unsigned(Reg_ref[inst_ref.B.rs1])<$unsigned(Reg_ref[inst_ref.B.rs2]) ) begin
        PC_ref=Btar_ref();
    end else begin
        nextIns_ref;
    end
endtask : BLTU_ref

task BGE_ref();
    if (Reg_ref[inst_ref.B.rs1]>=Reg_ref[inst_ref.B.rs2]) begin
        PC_ref=Btar_ref();
    end else begin
        nextIns_ref;
    end
endtask : BGE_ref

task BGEU_ref();
    if ($unsigned(Reg_ref[inst_ref.B.rs1])>=$unsigned(Reg_ref[inst_ref.B.rs2]) ) begin
        PC_ref=Btar_ref();
    end else begin
        nextIns_ref;
    end
endtask : BGEU_ref

task ADDI_ref();
    wreg_ref(inst_ref.I.rd,eaI_ref());
endtask : ADDI_ref

task XORI_ref();
    wreg_ref(inst_ref.I.rd,SE12_ref(inst_ref.I.imm12)^REG_ref(inst_ref.I.rs1));
endtask : XORI_ref

task ORI_ref();
    wreg_ref(inst_ref.I.rd,SE12_ref(inst_ref.I.imm12)|REG_ref(inst_ref.I.rs1));
endtask : ORI_ref

task ANDI_ref();
    wreg_ref(inst_ref.I.rd,SE12_ref(inst_ref.I.imm12)&REG_ref(inst_ref.I.rs1));
endtask : ANDI_ref

task SLLI_ref();
    Rdata_ref w;
    w=REG_ref(inst_ref.R.rs1);
    w=w<<inst_ref.R.rs2;
    wreg_ref(inst_ref.R.rd,w);
endtask : SLLI_ref

task SRLI_ref();
    Rdata_ref w;
    w=REG_ref(inst_ref.R.rs1);
    w=$unsigned(w)>>inst_ref.R.rs2;
    wreg_ref(inst_ref.R.rd,w);
endtask : SRLI_ref

task SRAI_ref();
    Rdata_ref w;
    w=REG_ref(inst_ref.R.rs1);
    w=w>>>inst_ref.R.rs2;
    wreg_ref(inst_ref.R.rd,w);
endtask : SRAI_ref

task SLTI_ref();
    Rdata_ref w;
    w=SE12_ref(inst_ref.I.imm12);
    wreg_ref(inst_ref.I.rd,(REG_ref(inst_ref.I.rs1)<w)?32'h1:32'h0);
endtask : SLTI_ref

task SLTIU_ref();
    Rdata_ref w;
    w=SE12_ref(inst_ref.I.imm12);
    wreg_ref(inst_ref.I.rd,($unsigned(REG_ref(inst_ref.I.rs1))<$unsigned(w))?32'h1:32'h0);
endtask : SLTIU_ref

function Raddr_ref eaS_ref();
    Raddr_ref rv,indx;
    rv=REG_ref(inst_ref.S.rs1);
    indx={(inst_ref.S.imm11_5[6])?20'hffff:20'h0,inst_ref.S.imm11_5,inst_ref.S.imm4_0};
    //$display("What is dont care %0x %0x %0x",rv+indx,rv,indx);
    return rv+indx;
endfunction : eaS_ref

task SB_ref();
    Rdata_ref td;
    reg [31:0] mask;
    Raddr_ref wa;
    reg [1:0] low2;
    wa=eaS_ref();
//    $display("storing a byte %h to %h",REG_ref(inst_ref.S.rs2),wa);
    low2=wa&32'h3;
    mask=32'hff<<(low2*8);
    td=MEM_ref(wa);  // does a read/modify write
    td=(td& ~mask)| ((REG_ref(inst_ref.S.rs2)<<(low2*8))&mask);
//    $display("New memory data will be %h",td);
    WMEM_ref(wa,td);
endtask : SB_ref

task SH_ref();
    Rdata_ref [1:0] td;
    reg [63:0] wd;
    Raddr_ref ra;
    reg [63:0] mask;
    reg [1:0] low2;
    mask=64'hffff<<(low2*8);
    ra=eaS_ref();
    td[0]=MEM_ref(ra);
    td[1]=MEM_ref(ra+4);
    wd=REG_ref(inst_ref.S.rs2);
    td= (td& ~mask) | ((wd<<(low2*8))&mask);
    WMEM_ref(ra,td[0]);
    WMEM_ref(ra+4,td[1]);
endtask : SH_ref

task SW_ref();
    Rdata_ref [1:0] td;
    reg [63:0] wd;
    Raddr_ref ra;
    reg [63:0] mask;
    reg [1:0] low2;
    mask=64'hffffFFFF<<(low2*8);
    ra=eaS_ref();
    td[0]=MEM_ref(ra);
    td[1]=MEM_ref(ra+4);
    wd=REG_ref(inst_ref.S.rs2);
    td= (td& ~mask) | ((wd<<(low2*8))&mask);
    WMEM_ref(ra,td[0]);
    WMEM_ref(ra+4,td[1]);
endtask : SW_ref

task LUI_ref();
    Rdata_ref rv;
    rv={inst_ref.U.imm31_12,12'h0};
    wreg_ref(inst_ref.U.rd,rv);
endtask : LUI_ref

task AUIPC_ref();
    Rdata_ref rv;
    rv={inst_ref.U.imm31_12,12'h0}+PC_ref;
    wreg_ref(inst_ref.U.rd,rv);
endtask : AUIPC_ref

task JAL_ref();
    Raddr_ref ta;
    ta={(inst_ref.J.imm20_10_1_11_19_12[19])?12'hfff:12'h0,
        inst_ref.J.imm20_10_1_11_19_12[19],
        inst_ref.J.imm20_10_1_11_19_12[7:0],
        inst_ref.J.imm20_10_1_11_19_12[8],
        inst_ref.J.imm20_10_1_11_19_12[18:9],1'b0};
    ta+=PC_ref;
    wreg_ref(inst_ref.J.rd,PC_ref+4);
    PC_ref=ta;
endtask : JAL_ref

task JALR_ref();
    Raddr_ref ta;
    ta=eaI_ref();
    wreg_ref(inst_ref.I.rd,PC_ref+4);
    PC_ref=ta;
endtask : JALR_ref

task SLL_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a<<b[4:0];
    wreg_ref(inst_ref.R.rd,r);
endtask : SLL_ref

task SRL_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a>>b[4:0];
    wreg_ref(inst_ref.R.rd,r);
endtask : SRL_ref

task SRA_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a>>>b[4:0];
    wreg_ref(inst_ref.R.rd,r);
endtask : SRA_ref

task ADD_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a+b;
    wreg_ref(inst_ref.R.rd,r);
endtask : ADD_ref

task SUB_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a-b;
    wreg_ref(inst_ref.R.rd,r);
endtask : SUB_ref

task SLT_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=(a<b)?1:0;
    wreg_ref(inst_ref.R.rd,r);
endtask : SLT_ref

task SLTU_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=($unsigned(a)<$unsigned(b))?1:0;
    wreg_ref(inst_ref.R.rd,r);
endtask : SLTU_ref

task XOR_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a^b;
    wreg_ref(inst_ref.R.rd,r);
endtask : XOR_ref

task OR_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a|b;
    wreg_ref(inst_ref.R.rd,r);
endtask : OR_ref

task AND_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a&b;
    wreg_ref(inst_ref.R.rd,r);
endtask : AND_ref

task MUL_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a*b;
    wreg_ref(inst_ref.R.rd,r);
endtask : MUL_ref

task MULU_ref();
    reg [31:0] a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a*b;
    wreg_ref(inst_ref.R.rd,r);
endtask : MULU_ref

task MULH_ref();
    Rdata_ref a,b;
    reg signed [63:0] r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a*b;
    wreg_ref(inst_ref.R.rd,r[63:32]);
endtask : MULH_ref

task MULHU_ref();
    reg [31:0] a,b;
    reg [63:0] r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a*b;
    wreg_ref(inst_ref.R.rd,r[63:32]);
endtask : MULHU_ref

task MULHSU_ref();
    reg [31:0] b;
    Rdata_ref a;
    reg [63:0] r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a*b;
    wreg_ref(inst_ref.R.rd,r[63:32]);
endtask : MULHSU_ref

task DIV_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a/b;
    wreg_ref(inst_ref.R.rd,r);
endtask : DIV_ref

task DIVU_ref();
    reg [31:0] a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a/b;
    wreg_ref(inst_ref.R.rd,r);
endtask : DIVU_ref

task REM_ref();
    Rdata_ref a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a%b;
    wreg_ref(inst_ref.R.rd,r);
endtask : REM_ref

task REMU_ref();
    reg [31:0] a,b,r;
    a=REG_ref(inst_ref.R.rs1);
    b=REG_ref(inst_ref.R.rs2);
    r=a%b;
    wreg_ref(inst_ref.R.rd,r);
endtask : REMU_ref


// A nop for this model
task FENCE_ref();

endtask : FENCE_ref

// A nop for this model
task FENCEI_ref();

endtask : FENCEI_ref


// Need to set up for the ECALL_ref and EBREAK_ref instructions
// Place holders for now
task ECALL_ref();

endtask : ECALL_ref

task EBREAK_ref();

endtask : EBREAK_ref

// CSR are a to do item.

task CSRRW_ref();
    nextIns_ref;
endtask : CSRRW_ref

task CSRRS_ref();
    nextIns_ref;
endtask : CSRRS_ref

task CSRRC_ref();
    nextIns_ref;
endtask : CSRRC_ref

task CSRRWI_ref();
    nextIns_ref;
endtask : CSRRWI_ref

task CSRRSI_ref();
    nextIns_ref;
endtask : CSRRSI_ref

task CSRRCI_ref();
    nextIns_ref;
endtask : CSRRCI_ref

task REMUL_REF();
    icnt_ref+=1;
    finishedcode_ref=0;
    if(reset) begin
        PC_ref=32'h8000_0000;
        icnt_ref=0;
        for(int ix=0; ix < 32; ix+=1) Reg_ref[ix]=ix;
    end else begin
        inst_ref.raw=MEM_ref(PC_ref);
        #5;
//        $display("%d %h (inst_ref) @ %h ",cnt,inst_ref.raw,PC_ref);
        if (inst_ref.R.ones!=2'b11) begin
            unsupported_ref;
			nextIns_ref;
        end else case (inst_ref.R.opcode5)
            5'b00000: begin
                case (inst_ref.I.funct3)
                    3'b000: LB_ref;
                    3'b001: LH_ref;
                    3'b010: LW_ref;
                    3'b100: LBU_ref;
                    3'b101: LHU_ref;
                    default:
                        unsupported_ref;
                endcase
                nextIns_ref;
            end
            5'b00011: begin
                case(inst_ref.R.funct3)
                    3'b000: FENCE_ref;
                    3'b001: FENCEI_ref;
                    default:
                        unsupported_ref;
                endcase
                nextIns_ref;
            end
            5'b00100: begin
                case (inst_ref.I.funct3)
                    3'b000: ADDI_ref;
                    3'b001: begin
                        if(inst_ref.R.funct7==0) SLLI_ref;
                        else unsupported_ref;
                    end
                    3'b010: SLTI_ref;
                    3'b011: SLTIU_ref;
                    3'b100: XORI_ref;
                    3'b101: case(inst_ref.R.funct7)
                        0: SRLI_ref;
                        7'h20 : SRAI_ref;
                        default:
                            unsupported_ref;
                    endcase
                    3'b110: ORI_ref;
                    3'b111: ANDI_ref;
                    default:
                        unsupported_ref;
                endcase
                nextIns_ref;
            end
            5'b00101: begin
                AUIPC_ref;
                nextIns_ref;
            end
            5'b01000: begin
                case(inst_ref.I.funct3)
                    3'b000: SB_ref;
                    3'b001: SH_ref;
                    3'b010: SW_ref;
                    default: unsupported_ref;
                endcase
                nextIns_ref;
            end
            5'b01100: begin
                case(inst_ref.R.funct3)
                    3'b000: case(inst_ref.R.funct7)
                        0: ADD_ref;
                        7'b0100000: SUB_ref;
                        7'b0000001: MUL_ref;
                        default: unsupported_ref;
                    endcase
                    3'b001: case(inst_ref.R.funct7)
                        0: SLL_ref;
                        7'b0000001: MULH_ref;
                        default: unsupported_ref;
                    endcase
                    3'b010: case(inst_ref.R.funct7)
                        0: SLT_ref;
                        7'b0000001: MULHSU_ref;
                        default: unsupported_ref;
                    endcase
                    3'b011: case(inst_ref.R.funct7)
                        0: SLTU_ref;
                        1: MULHU_ref;
                        default: unsupported_ref;
                    endcase
                    3'b100: case(inst_ref.R.funct7)
                        0: XOR_ref;
                        1: DIV_ref;
                        default: unsupported_ref;
                    endcase
                    3'b101: case (inst_ref.R.funct7)
                        0: SRL_ref;
                        1: DIVU_ref;
                        7'b0100000: SRA_ref;
                        default: unsupported_ref;
                    endcase
                    3'b110: case(inst_ref.R.funct7)
                        0: OR_ref;
                        1: REM_ref;
                        default: unsupported_ref;
                    endcase
                    3'b111: case(inst_ref.R.funct7)
                        0: AND_ref;
                        1: REMU_ref;
                        default: unsupported_ref;
                    endcase
                endcase
                nextIns_ref;
            end
            5'b01101: begin
                LUI_ref;
                nextIns_ref;
            end
            5'b11000: begin
                case (inst_ref.B.funct3)
                    3'b000: BEQ_ref;
                    3'b001: BNE_ref;
                    3'b100: BLT_ref;
                    3'b101: BGE_ref;
                    3'b110: BLTU_ref;
                    3'b111: BGEU_ref;
                    default:
                        unsupported_ref;
                endcase
            end
            5'b11001: begin
                if(inst_ref.I.funct3==0) JALR_ref;
                    else unsupported_ref;
            end
            5'b11011: begin
                JAL_ref;
            end
            5'b11100: begin
                case(inst_ref.I.funct3)
                    3'b000: begin
                        case(inst_ref[31:7])
                            0: ECALL_ref;
                            'b000000000001_00000_000_00000: EBREAK_ref;
                            default:
                                unsupported_ref;
                        endcase
                    end
                    3'b001: CSRRW_ref;
                    3'b010: CSRRS_ref;
                    3'b011: CSRRC_ref;
                    3'b101: CSRRWI_ref;
                    3'b110: CSRRSI_ref;
                    3'b111: CSRRCI_ref;
                endcase
            end
            default:
              unsupported_ref;
        endcase
    end
endtask : REMUL_REF



