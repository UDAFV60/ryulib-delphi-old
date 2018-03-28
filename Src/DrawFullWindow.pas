{*
  ������ â���� �巡�׵� ��, ��ü ȭ���� ��� �׸����� �ƴϸ� �ܰ��� �׸�����?
  ���α׷� ���� �� ��, Disable�� �ϰ�, ���α׷� ���� �ÿ� Restore�ϸ�,
  ���α׷� ���� ���Ĵ� �ܰ��� �׸��ٰ�, ���� ���Ŀ��� ������ ����� �ɼ����� �ǵ��� ����.
}
unit DrawFullWindow;

interface

uses
  Windows, SysUtils, Classes;

procedure EnableDrawFullWindow;
procedure DisableDrawFullWindow;
procedure RestoreDrawFullWindow;

implementation

var
  OldState : LongBool = false;

procedure EnableDrawFullWindow;
begin
  SystemParametersInfo(SPI_SETDRAGFULLWINDOWS, Ord(true), nil, 0);
end;

procedure DisableDrawFullWindow;
begin
  SystemParametersInfo(SPI_SETDRAGFULLWINDOWS, Ord(false), nil, 0);
end;

procedure RestoreDrawFullWindow;
begin
  SystemParametersInfo(SPI_SETDRAGFULLWINDOWS, Ord(OldState), nil, 0);
end;

initialization
  SystemParametersInfo( SPI_GETDRAGFULLWINDOWS, 0, @OldState, 0 );
finalization
  RestoreDrawFullWindow;
end.
