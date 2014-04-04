unit IOPS;

(* Information
   ßßßßßßßßßßß

   Program Title : NASM opcode definitions.
   External name : IOPS.TPU
   Version       : 1.7
   Start date    : 13/04/1997
   Last update   : 18/05/2002
   Author        : Rob Anderton
   Description   : Unit containing names of reserved words (opcodes),
                   registers and conditional instructions used for syntax
                   highlighting.
*)

interface

{******}

function CheckRegName(RegName : string) : boolean;
function CheckOpCode(OpCode : string) : boolean;
function CheckConditional(Cond : string) : boolean;
function CheckDirective(Directive : string) : boolean;
function CheckPreProcDirective(PreProc : string) : boolean;

{******}

implementation

uses IUTILS;

{******}

const Reg_Names : array[1..69] of string[4] =
                  ( 'ah',   'al',   'ax',   'bh',   'bl',   'bp',   'bx',   'ch',
                    'cl',  'cr0',  'cr2',  'cr3',  'cr4',   'cs',   'cx',   'dh',
                    'di',   'dl',  'dr0',  'dr1',  'dr2',  'dr3',  'dr6',  'dr7',
                    'ds',   'dx',  'eax',  'ebp',  'ebx',  'ecx',  'edi',  'edx',
                    'es',  'esi',  'esp',   'fs',   'gs',  'mm0',  'mm1',  'mm2',
                   'mm3',  'mm4',  'mm5',  'mm6',  'mm7',   'si',   'sp',   'ss',
                   'st0',  'st1',  'st2',  'st3',  'st4',  'st5',  'st6',  'st7',
                   'tr3',  'tr4',  'tr5',  'tr6',  'tr7', 'xmm0', 'xmm1', 'xmm2',
                  'xmm3', 'xmm4', 'xmm5', 'xmm6', 'xmm7');

{******}

const Insn_Names : array[1..546] of string[15] =
                   ('aaa', 'aad', 'aam', 'aas', 'adc', 'add', 'addpd',
                    'addps', 'addsd', 'addss', 'and', 'anddpd', 'andnpd',
                    'andnps', 'andps', 'arpl',
                    'bound', 'bsf', 'bsr', 'bswap', 'bt', 'btc', 'btr',
                    'bts',
                    'call', 'cbw', 'cdq', 'clc', 'cld', 'clflush', 'cli',
                    'clts', 'cmc', 'cmp', 'cmpeqpd', 'cmpeqps', 'cmpeqsd',
                    'cmpeqss', 'cmplepd', 'cmpleps', 'cmplesd', 'cmpless',
                    'cmpltpd', 'cmpltps', 'cmpltsd', 'cmpltss', 'cmpneqpd',
                    'cmpneqps', 'cmpneqsd', 'cmpneqss', 'cmpnlepd', 'cmpnleps',
                    'cmpnlesd', 'cmpnless', 'cmpnltpd,', 'cmpnltps', 'cmpnltsd',
                    'cmpnltss', 'cmpordpd', 'cmpordps', 'cmpordsd', 'cmpordss',
                    'cmppd', 'cmpps', 'cmpsb', 'cmpsd', 'cmpss', 'cmpsw',
                    'cmpunordpd', 'cmpunordps', 'cmpunordsd', 'cmpunordss',
                    'cmpxchg', 'cmpxchg486', 'cmpxchg8b', 'comisd',
                    'comiss', 'cpuid', 'cvtdq2pd', 'cvtdq2ps', 'cvtpd2dq',
                    'cvtpd2pi', 'cvtpd2ps', 'cvtpi2pd', 'cvtpi2ps', 'cvtps2dq',
                    'cvtps2pd', 'cvtps2pi', 'cvtsd2si', 'cvtsd2dd', 'cvtsi2sd',
                    'cvtsi2ss', 'cvtss2sd', 'cvtss2si',	'cvttpd2dq',
                    'cvttpd2pi', 'cvttps2dq', 'cvttps2pi', 'cvttsd2si',
                    'cvttss2si', 'cwd', 'cwde',
                    'daa', 'das', 'db', 'dd', 'dec', 'div', 'divpd', 'divps',
                    'divsd', 'divss', 'dq', 'dt', 'dw',
                    'emms', 'enter', 'equ',
                    'f2xm1', 'fabs', 'fadd', 'faddp', 'fbld', 'fbstp',
                    'fchs', 'fclex', 'fcmovb', 'fcmovbe', 'fcmove',
                    'fcmovnb', 'fcmovnbe', 'fcmovne', 'fcmovnu', 'fcmovu',
                    'fcom', 'fcomi', 'fcomip', 'fcomp', 'fcompp', 'fcos',
                    'fdecstp', 'fdisi', 'fdiv', 'fdivp', 'fdivr', 'fdivrp',
                    'femms', 'feni', 'ffree', 'ffreep', 'fiadd', 'ficom',
                    'ficomp', 'fidiv', 'fidivr', 'fild', 'fimul', 'fincstp',
                    'finit', 'fist', 'fistp', 'fisub', 'fisubr', 'fld',
                    'fld1', 'fldcw', 'fldenv', 'fldl2e', 'fldl2t', 'fldlg2',
                    'fldln2', 'fldpi', 'fldz', 'fmul', 'fmulp', 'fnclex',
                    'fndisi', 'fneni', 'fninit', 'fnop', 'fnsave', 'fnstcw',
                    'fnstenv', 'fnstsw', 'fpatan', 'fprem', 'fprem1',
                    'fptan', 'frndint', 'frstor', 'fsave', 'fscale',
                    'fsetpm', 'fsin', 'fsincos', 'fsqrt', 'fst', 'fstcw',
                    'fstenv', 'fstp', 'fstsw', 'fsub', 'fsubp', 'fsubr',
                    'fsubrp', 'ftst', 'fucom', 'fucomi', 'fucomip', 'fucomp',
                    'fucompp', 'fwait', 'fxam', 'fxch', 'fxrstor', 'fxsave',
                    'fxtract', 'fyl2x', 'fyl2xp1',
                    'hlt',
                    'ibts', 'icebp', 'idiv', 'imul', 'in', 'inc', 'incbin',
                    'insb', 'insd', 'insw', 'int', 'int01', 'int03', 'int1',
                    'int3', 'into', 'invd', 'invlpg', 'iret', 'iretd',
                    'iretw',
                    'jcxz', 'jecxz', 'jmp',
                    'lahf', 'lar', 'ldmxcsr', 'lds', 'lea', 'leave', 'les',
                    'lfence', 'lfs', 'lgdt', 'lgs', 'lidt', 'lldt', 'lmsw',
                    'loadall', 'loadall286', 'lodsb', 'lodsd', 'lodsw',
                    'loop', 'loope', 'loopne', 'loopnz', 'loopz', 'lsl',
                    'lss', 'ltr',
                    'maskmovdqu', 'maskmovq', 'maxpd', 'maxps', 'maxsd',
                    'maxss', 'mfence', 'minpd', 'minps','minsd', 'minss',
                    'mov', 'movapd', 'movaps', 'movd', 'movdq2q', 'movdqa',
                    'movdqu', 'movhlps', 'movhpd', 'movhps', 'movlhps',
                    'movlps', 'movmskpd', 'movmskps', 'movntdq', 'movnti',
                    'movntpd', 'movntps', 'movntq', 'movq', 'movq2dq',
                    'movsb', 'movsd', 'movss', 'movsw', 'movsx', 'movupd',
                    'movups', 'movzx', 'mul', 'mulpd', 'mulps', 'mulsd',
                    'mulss',
                    'neg', 'nop', 'not',
                    'or', 'orpd', 'orps', 'out', 'outsb', 'outsd', 'outsw',
                    'packssdw', 'packsswb', 'packuswb', 'paddb',
                    'paddd', 'paddq', 'paddsb', 'paddsiw', 'paddsw',
                    'paddusb', 'paddusw', 'paddw', 'pand', 'pandn', 'pause',
                    'paveb', 'pavgb', 'pavgusb', 'pavgw', 'pcmpeqb',
                    'pcmpeqd', 'pcmpeqw', 'pcmpgtb', 'pcmpgtd', 'pcmpgtw',
                    'pdistib', 'pextrw', 'pf2id', 'pf2iw', 'pfacc', 'pfadd',
                    'pfcmpeq', 'pfcmpge', 'pfcmpgt', 'pfmax', 'pfmin',
                    'pfmul', 'pfnacc', 'pfpnacc', 'pfrcp', 'pfrcpit1',
                    'pfrcpit2', 'pfrsqit1', 'pfrsqrt', 'pfsub', 'pfsubr',
                    'pi2fd', 'pi2fw', 'pinsrw', 'pmachriw', 'pmaddwd',
                    'pmagw', 'pmaxsw', 'pmaxub', 'pminsw', 'pminub',
                    'pmovmskb', 'pmulhriw', 'pmulhrwa', 'pmulhrwc',
                    'pmulhuw', 'pmulhw', 'pmullw', 'pmuludq', 'pmvgezb',
                    'pmvlzb', 'pmvnzb', 'pmvzb', 'pop', 'popa', 'popad',
                    'popaw', 'popf', 'popfd', 'popfw', 'por', 'prefetch',
                    'prefetchnta', 'prefetcht0', 'prefetcht1', 'prefetcht2',
                    'prefetchw', 'psadbw', 'pshufd', 'pshufhw', 'pshuflw',
                    'pshufw', 'pslld', 'pslldq', 'psllq', 'psllw', 'psrad',
                    'psraw', 'psrld', 'psrldq', 'psrlq', 'psrlw', 'psubb',
                    'psubd', 'psubq', 'psubsb', 'psubsiw', 'psubsw',
                    'psubusb', 'psubusw', 'psubw', 'pswapd', 'punpckhbw',
                    'punpckhdq', 'punpckhqdq', 'punpckhwd', 'punpcklbw',
                    'punpckldq', 'punpcklqdq', 'punpcklwd', 'push', 'pusha',
                    'pushad', 'pushaw', 'pushf', 'pushfd', 'pushfw', 'pxor',
                    'rcl', 'rcpps', 'rcpss', 'rcr',
                    'rdmsr', 'rdpmc', 'rdshr', 'rdtsc', 'resb', 'resd',
                    'resq', 'rest', 'resw', 'ret', 'retf', 'retn', 'rol',
                    'ror', 'rsdc', 'rsldt', 'rsm', 'rsqrtps', 'rsqrtss',
                    'rsts',
                    'sahf', 'sal', 'salc', 'sar', 'sbb', 'scasb', 'scasd',
                    'scasw', 'seg', 'sfence', 'sgdt', 'shl', 'shld', 'shr',
                    'shrd', 'shufps', 'sidt', 'sldt', 'smi', 'smint',
                    'smintold', 'smsw', 'sqrtpd', 'sqrtps', 'sqrtsd', 'sqrtss',
                    'stc', 'std', 'sti', 'stmxcsr', 'stosb', 'stosd', 'stosw',
                    'str', 'sub', 'subpd', 'subps', 'subsd', 'subss', 'svdc',
                    'svldt', 'svts', 'syscall', 'sysenter', 'sysexit',
                    'sysret',
                    'test', 'times',
                    'ucomisd', 'ucomiss', 'ud0', 'ud1', 'ud2', 'umov',
                    'unpckhpd', 'unpckhps', 'unpcklpd', 'unpcklps',
                    'verr', 'verw',
                    'wait', 'wbinvd', 'wrmsr', 'wrshr', 'wrt',
                    'xadd', 'xbts', 'xchg', 'xlat', 'xlatb', 'xor', 'xorpd',
                    'xorps');

{******}

const Insn_Conditional : array[1..4] of string[4] = ('cmov', 'j',
                                                     'rep', 'set');

{******}

const Insn_Conditions : array[1..30] of string[3] =
                        (  'a',  'ae',   'b',  'be',   'c',   'e',
                           'g',  'ge',   'l',  'le',  'na', 'nae',  'nb',
                         'nbe',  'nc',  'ne',  'ng', 'nge',  'nl', 'nle',
                          'no',  'np',  'ns',  'nz',   'o',   'p',  'pe',
                          'po',   's',   'z');

{******}

const NASM_Directives : array[1..23] of string[9] =
                        (
                         'ABSOLUTE', 'ALIGN', 'ALIGNB',
                         'AT', 'BITS', 'COMMON', 'CPU',
                         'ENDSTRUC', 'EXPORT', 'EXTERN',
                         'GLOBAL', 'GROUP', 'IEND', 'IMPORT',
                         'INC', 'INCLUDE', 'ISTRUC', 'LIBRARY',
                         'ORG', 'SECTION', 'SEGMENT', 'STRUC',
                         'UPPERCASE');

{******}

const PreProc_Directives : array[1..64] of string[10] =
                           ('arg', 'assign',
                            'clear',
                            'define',
                            'elif', 'elifctx', 'elifdef', 'elifid', 'elifidn',
                            'elifidni', 'elifmacro', 'elifnctx', 'elifndef',
                            'elifnid', 'elifnidn', 'elifnidni', 'elifnmacro',
                            'elifnnum', 'elifnstr', 'elifnum', 'elifstr',
                            'else', 'endif', 'endm', 'endmacro', 'endrep',
                            'error', 'exitrep',
                            'iassign', 'idefine', 'if', 'ifctx', 'ifdef',
                            'ifdifi', 'ifid', 'ifidn', 'ifidni', 'ifmacro',
                            'ifnctx', 'ifndef', 'ifnid', 'ifnidn', 'ifnidni',
                            'ifnmacro', 'ifnnum', 'ifnstr', 'ifnum',
                            'ifstr', 'imacro', 'include', 'ixdefine',
                            'line', 'local',
                            'macro',
                            'pop', 'push',
                            'rep', 'repl', 'rotate',
                            'stacksize', 'strlen', 'substr',
                            'undef',
                            'xdefine');

{******}

function CheckRegName(RegName : string) : boolean;

var Found  : boolean;
    Failed : boolean;
    HighP  : integer;
    LowP   : integer;
    MidP   : integer;

begin
     RegName:= StrLower(RegName);
     Found:= false;
     Failed:= false;
     HighP:= High(Reg_Names);
     LowP:= Low(Reg_Names);

     repeat
           MidP:= (HighP + LowP) div 2;
           if Reg_Names[MidP] = RegName then
               Found:= true
           else
               if LowP >= HighP then
                   Failed:= true
               else
                   if Reg_Names[MidP] < RegName then LowP:= MidP + 1
                                                else HighP:= MidP - 1;
     until Found or Failed;

     CheckRegName:= Found or not Failed;
end;

{******}

function CheckOpCode(OpCode : string) : boolean;

var Found  : boolean;
    Failed : boolean;
    HighP  : integer;
    LowP   : integer;
    MidP   : integer;

begin
     OpCode:= StrLower(OpCode);
     Found:= false;
     Failed:= false;
     HighP:= High(Insn_Names);
     LowP:= Low(Insn_Names);

     repeat
           MidP:= (HighP + LowP) div 2;
           if Insn_Names[MidP] = OpCode then
               Found:= true
           else
               if LowP >= HighP then
                   Failed:= true
               else
                   if Insn_Names[MidP] < OpCode then LowP:= MidP + 1
                                                else HighP:= MidP - 1;
     until Found or Failed;

     CheckOpCode:= Found or not Failed;
end;

{******}

function CheckConditional(Cond : string) : boolean;

var Found  : boolean;
    Failed : boolean;
    HighP  : integer;
    LowP   : integer;
    MidP   : integer;
    PosP   : byte;

begin
     Cond:= StrLower(Cond);
     MidP:= Low(Insn_Conditional) - 1;
     HighP:= High(Insn_Conditional);
     Found:= false;

     repeat
           Inc(MidP);
           PosP:= Pos(Insn_Conditional[MidP], Cond);
           Found:= (PosP <> 0) and (PosP = 1);
     until (Found) or (MidP = HighP);

     if Found then
     begin
          if Cond <> 'rep' then
          begin
               Delete(Cond, PosP, Length(Insn_Conditional[MidP]));

               Found:= false;
               Failed:= false;
               HighP:= High(Insn_Conditions);
               LowP:= Low(Insn_Conditions);

               repeat
                     MidP:= (HighP + LowP) div 2;
                     if Insn_Conditions[MidP] = Cond then
                         Found:= true
                     else
                         if LowP >= HighP then
                             Failed:= true
                         else
                             if Insn_Conditions[MidP] < Cond then
                                 LowP:= MidP + 1
                             else
                                 HighP:= MidP - 1;

               until Found or Failed;
               CheckConditional:= Found or not Failed;
          end
          else CheckConditional:= true;
     end
     else CheckConditional:= false;
end;

{******}

function CheckDirective(Directive : string) : boolean;

var Found  : boolean;
    Failed : boolean;
    HighP  : integer;
    LowP   : integer;
    MidP   : integer;

begin
     Directive:= StrUpper(Directive);
     Found:= false;
     Failed:= false;
     HighP:= High(NASM_Directives);
     LowP:= Low(NASM_Directives);

     repeat
           MidP:= (HighP + LowP) div 2;
           if NASM_Directives[MidP] = Directive then
               Found:= true
           else
               if LowP >= HighP then
                   Failed:= true
               else
                   if NASM_Directives[MidP] < Directive then LowP:= MidP + 1
                                                        else HighP:= MidP - 1;
     until Found or Failed;

     CheckDirective:= Found or not Failed;
end;

{******}

function CheckPreProcDirective(PreProc : string) : boolean;

var Found  : boolean;
    Failed : boolean;
    HighP  : integer;
    LowP   : integer;
    MidP   : integer;

begin
     PreProc:= StrLower(PreProc);
     Found:= false;
     Failed:= false;
     HighP:= High(PreProc_Directives);
     LowP:= Low(PreProc_Directives);

     repeat
           MidP:= (HighP + LowP) div 2;
           if PreProc_Directives[MidP] = PreProc then
               Found:= true
           else
               if LowP >= HighP then
                   Failed:= true
               else
                   if PreProc_Directives[MidP] < PreProc then LowP:= MidP + 1
                                                         else HighP:= MidP - 1;
     until Found or Failed;

     CheckPreProcDirective:= Found or not Failed;
end;

{******}

end.