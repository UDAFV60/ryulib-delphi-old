{$I-}
Unit Prt;

Interface

Type
    CodeStr = String[20];

Const
     KSSM : Packed Array [1..48] of CodeStr
              = (
                 'KSSM', '46',
                 '#���ǵ�',   #12,
                 '#�ʱ�ȭ',   #27+'@',
                 '#1/180',    #27+'J'+#1,
                 '#2/180',    #27+'J'+#2,
                 '#5/180',    #27+'J'+#5,
                 '#10/180',   #27+'J'+#10,
                 '#18/180',   #27+'J'+#18,
                 '#�ϼ���',   #27+'@'+#28+'&'+#28+'t0',
                 '#������',   #27+'@'+#28+'&'+#28+'t1',
                 '#���Ÿ�ü����', #27+'4',
                 '#���Ÿ�ü���', #27+'5',
                 '#����ü����',   #27+'E',
                 '#����ü���',   #27+'F',
                 '#�Ϲݹ���',     #27+'q'+#0,
                 '#��������',     #27+'q'+#1,
                 '#������',     #27+'q'+#2,
                 '#��������',     #27+'q'+#3,
                 '#�ι�Ȯ��',     #28+'W1',
                 '#�ι����',     #28+'W0',
                 '#���ει�����', #27+'W'+#1,
                 '#���ει����', #27+'W'+#0,
                 '#���ει�����', #27+'y'+#1,
                 '#���ει����', #27+'y'+#0
              );
     KS : Packed Array [1..48] of CodeStr
              = (
                 'KS', '46',
                 '#���ǵ�',   #12,
                 '#�ʱ�ȭ',   #27+'@',
                 '#1/180',    #27+'J'+#1,
                 '#2/180',    #27+'J'+#2,
                 '#5/180',    #27+'J'+#5,
                 '#10/180',   #27+'J'+#10,
                 '#18/180',   #27+'J'+#18,
                 '#���ü',       #27+'m'+#1,
                 '#����ü',       #27+'m'+#0,
                 '#���Ÿ�ü����', #27+'4',
                 '#���Ÿ�ü���', #27+'5',
                 '#����ü����',   #27+'E',
                 '#����ü���',   #27+'F',
                 '#��������',     #27+'r'+#1,
                 '#�������',     #27+'r'+#0,
                 '#��������',     #27+'z'+#1,
                 '#�������',     #27+'z'+#0,
                 '#1.5������',    #27+'s'+#1,
                 '#1.5�����',    #27+'s'+#0,
                 '#���ει�����', #27+'W'+#1,
                 '#���ει����', #27+'W'+#0,
                 '#���ει�����', #27+'y'+#1,
                 '#���ει����', #27+'y'+#0
              );

Var
   PrtFile                   : TextFile;
   TimeOut, PrtError         : Byte;
   PrintPage                 : Boolean;
   PrintFileName             : String;

procedure SetDefaultPrinter;
Procedure OpenPrinter;
Procedure PrintStr(Strg:String);
Procedure PrintLnStr(Strg:String);
Procedure CRLF(Lines:Word);
Procedure FormFeed;
Procedure ClosePrinter;

Implementation

Uses
  Windows, SysUtils, Forms, Dialogs, Printers, Strg;

// �湮�̰� ��ģ��  
procedure SetDefaultPrinter;
var
  aDevice, aDriver, aPort: PChar;
  aHandle: THandle;
begin
  GetMem(aDevice, 50); // 50�� ����� ū ��
  GetMem(aDriver, 50);
  GetMem(aPort, 50);
  Printer.GetPrinter(aDevice, aDriver, aPort, aHandle);
  PrintFileName:= StrPas(aPort);
  FreeMem(aDevice);
  FreeMem(aDriver);
  FreeMem(aPort);
end;

Procedure OpenPrinter;
Begin
     PrtError:= 0;
     AssignFile(PrtFile, PrintFileName);
     ReWrite(PrtFile);
     If IOResult <> 0 then
        Begin
             PrtError:= 1;
             ShowMessage('�����͸� �����Ͽ� �ֽʽÿ�. ');
        End;
End;

Procedure PrintStr(Strg:String);
Begin
     Write(PrtFile, Strg);
End;

Procedure PrintLnStr(Strg:String);
Begin
     WriteLn(PrtFile, Strg);
End;

Procedure CRLF(Lines:Word);
Var
   Loop : Word;
Begin
     For Loop:= 1 to Lines Do WriteLn(PrtFile);
End;

Procedure FormFeed;
Begin
     Write(PrtFile, #12);
End;

Procedure ClosePrinter;
Begin
     CloseFile(PrtFile);
End;

End.


