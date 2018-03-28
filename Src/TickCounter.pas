unit TickCounter;

interface

uses
  Windows, Classes, SysUtils;

type
  TTickCounter = class
  private
    FOldTick : cardinal;
    FDuration : int64;
  public
    constructor Create;

    procedure Start;

    /// ��� �� ȣ����� �ð� ������ �����Ѵ�.
    function Get:cardinal;

    /// Start ���� ���� �ð��� �����Ѵ�.
    function GetDuration:int64;
  end;

implementation

{ TTickCounter }

constructor TTickCounter.Create;
begin
  inherited;

  Start;
end;

function TTickCounter.Get: cardinal;
var
  Tick : Cardinal;
begin
  Tick := GetTickCount;
  if Tick < FOldTick then begin
    // TickCount�� �� �� �ְ�ġ�� ���� �� ������ Get�� ���ϸ�?  �׳�, ������!
    Result := ($FFFFFFFF - FOldTick) + Tick;
  end else begin
    Result := Tick - FOldTick;
  end;

  FDuration := FDuration + Result;

  FOldTick := Tick;
end;

function TTickCounter.GetDuration: int64;
var
  Tick, Temp : Cardinal;
begin
  Tick := GetTickCount;
  if Tick < FOldTick then begin
    // TickCount�� �� �� �ְ�ġ�� ���� �� ������ Get�� ���ϸ�?  �׳�, ������!
    Temp := ($FFFFFFFF - FOldTick) + Tick;
  end else begin
    Temp := Tick - FOldTick;
  end;

  FDuration := FDuration + Temp;

  FOldTick := Tick;

  Result := FDuration;
end;

procedure TTickCounter.Start;
begin
  FOldTick := GetTickCount;
  FDuration := 0;
end;

end.
