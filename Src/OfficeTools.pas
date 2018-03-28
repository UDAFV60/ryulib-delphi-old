unit OfficeTools;

interface

uses
  Windows, SysUtils, Classes, ComObj, ActiveX;

procedure PPT2JPG(ASrc,ADst:string);
procedure PPT2PNG(ASrc,ADst:string);

implementation

const
  ppSaveAsPresentation = $00000001;
  ppSaveAsPowerPoint7 = $00000002;
  ppSaveAsPowerPoint4 = $00000003;
  ppSaveAsPowerPoint3 = $00000004;
  ppSaveAsTemplate = $00000005;
  ppSaveAsRTF = $00000006;
  ppSaveAsShow = $00000007;
  ppSaveAsAddIn = $00000008;
  ppSaveAsWizard = $00000009;
  ppSaveAsPowerPoint4FarEast = $0000000A;
  ppSaveAsDefault = $0000000B;
  ppSaveAsHtml = $0000000C;
  ppSaveAsJPG  = 17;
  ppSaveAsPNG  = 18;

  ppWindowMinimized = 2;

  msoFalse = TOleEnum(False);
  msoTrue = TOleEnum(True);

procedure PPT2JPG(ASrc,ADst:string);
var
  PPT : variant;
begin
  try
    PPT:= GetActiveOleObject('Powerpoint.Application');
  except
    PPT:= CreateOleObject('Powerpoint.Application');
  end;

  PPT.Visible := True;
  PPT.Presentations.open(ASrc);
  PPT.ActivePresentation.SaveAs(ADst, ppSaveAsJPG, false);
  PPT.Quit;
end;

procedure PPT2PNG(ASrc,ADst:string);
var
  PPT : variant;
begin
  try
    PPT:= GetActiveOleObject('Powerpoint.Application');
  except
    PPT:= CreateOleObject('Powerpoint.Application');
  end;

  PPT.Visible := True;
  PPT.Presentations.open(ASrc);
  PPT.ActivePresentation.SaveAs(ADst, ppSaveAsPNG, false);
  PPT.Quit;
end;

initialization
  CoInitialize(nil);
finalization
  CoUninitialize;
end.

�⺻���� 96dpi���� ���� �ػ��� �׸����� �����̵带 ���������� ������Ʈ�� ���� �߰��ؾ� �մϴ�. ���� �ܰ迡 ���� ������Ʈ�� ���� �߰��Ͻʽÿ�.

��� ������Ʈ�� �����⸦ �߸� ����ϸ� �ɰ��� ������ �߻��� �� ������ ������ �ذ��ϱ� ���� � ü���� �ٽ� ��ġ�ؾ� �� ���� �ֽ��ϴ�. Microsoft�� ������Ʈ�� �����⸦ �߸� ����Ͽ� �߻��ϴ� ������ ���� �ذ��� �������� �ʽ��ϴ�. ������Ʈ�� ������ ��뿡 ���� ��� å���� ����ڿ��� �ֽ��ϴ�.
1.	Microsoft Windows ���α׷��� �����մϴ�.
2.	������ ������ ������ �����ϴ�.
3.	���� ���ڿ� regedit�� �Է��� ���� Ȯ���� �����ϴ�.
4.	������Ʈ���� Ȯ���Ͽ� ���� Ű�� ã���ϴ�.
HKEY_CURRENT_USER\Software\Microsoft\Office\14.0\PowerPoint\Options
5.	Options Ű�� ������ ���¿��� ���� �޴��� ���� ����⸦ ����Ų ���� DWORD ���� �����ϴ�.
6.	ExportBitmapResolution�� �Է��� ���� Enter Ű�� �����ϴ�.
7.	ExportBitmapResolution�� ������ ���¿��� ���� �޴��� ������ �����ϴ�.
8.	���� ǥ�� �����Ͽ� �� ������ ���ڿ� ���ϴ� �ػ� ���� �Է��մϴ�.

���� PowerPoint ���� ������ �� �ִ� �ִ� �ػ� ������ 307dpi�Դϴ�.

10���� ��	�ȼ�(���� x ����)	dpi(���� �� ����)
50	500 x 375	50dpi
96(�⺻��)	960 x 720	96dpi
100	1000 x 750	100dpi
150	1500 x 1125	150dpi
200	2000 x 1500	200dpi
250	2500 x 1875	250dpi
300	3000 x 2250	300dpi
9.	10������ ���� ���� Ȯ���� �����ϴ�.
10.	���� �޴����� �����⸦ ���� ������Ʈ�� �����⸦ �����մϴ�.

{
Constant Value
ppSaveAsAddIn  8
ppSaveAsBMP  19
ppSaveAsDefault  11
ppSaveAsEMF  23
ppSaveAsGIF  16
ppSaveAsHTML  12
ppSaveAsHTMLDual  14
ppSaveAsHTMLv3  13
ppSaveAsJPG  17
ppSaveAsMetaFile  15
ppSaveAsPNG  18
ppSaveAsPowerPoint3  4
ppSaveAsPowerPoint4  3
ppSaveAsPowerPoint4FarEast  10
ppSaveAsPowerPoint7  2
ppSaveAsPresentation  1
ppSaveAsPresForReview  22
ppSaveAsRTF  6
ppSaveAsShow  7
ppSaveAsTemplate  5
ppSaveAsTIF  21
ppSaveAsWebArchive  20

Constant Value
ppWindowMaximized  3
ppWindowMinimized  2
ppWindowNormal  1
//}

