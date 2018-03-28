unit LatencyBuffer;

interface

uses
  DebugTools, PacketBuffer,
  Classes, SysUtils, SyncObjs;

const
  DEFAULT_DURATION = 500; /// �ʱ� ������ �ð� 500ms
  DEFAULT_DURATION_LIMIT = 32 * 1000; /// �ִ� ������ ���� = 32 ��

type
  TState = (stNormal, stEmpty, stDelayed);

  {*
    ��� �� �����ð�(Duration)�� ���� ä���� ����ϴ� �����̴�.
      - ���۰� Duration ũ�⸸ŭ�� �Ǿ�� Get���� �����Ͱ� ���ϵȴ�.
      - ���۰� Empty ���°� �Ǹ� Duration�� �� �� ũ��� �þ��, ���۰� Duration ũ�� ��ŭ �Ǳ� �������� Get���� false�� �����Ѵ�.
  }
  TLatencyBuffer = class
  private
    FRealDuration : integer;
    FCS : TCriticalSection;
    FState : TState;
    procedure set_State(AValue:TState);
    procedure do_Clear;
    procedure do_Add;
    procedure do_Get;
  private
    FPacketBuffer : TPacketBuffer;
  private
    FRealTime: boolean;
    FDelayedTime: integer;
    FDuration: integer;
    FDurationLimit: integer;
    function GetIsDelayed: boolean;
    procedure SetDuration(const Value: integer);
    procedure SetRealTime(const Value: boolean);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    {*
      �ԷµǴ� �����Ͱ� ������ �ð��� ũ���, ��, ��� �ð�, �Բ� �����͸� �Է��Ѵ�.
      @param AData
      @param ASize
      @param APlayTime �ԷµǴ� �������� �ð� ũ��.  �ð��� ���þ��� �����ʹ� 0���� �Է��Ѵ�.
    }
    procedure Add(AData:pointer; ASize,APlayTime:integer);

    function Get(var AData:pointer; var ASize:integer):boolean;
  public
    property RealTime : boolean read FRealTime write SetRealTime;  /// �������� �ǽð����� ó���ؾ� �ϴ� ��?

    property IsDelayed : boolean read GetIsDelayed;
    property Duration : integer read FDuration write SetDuration;  /// �����̰� ���Ǵ� ������ �ð� ũ�� (ms ����)
    property DurationLimit : integer read FDurationLimit write FDurationLimit;  /// �����̰� �þ� �� �� �ִ� �ִ� �ð� ũ�� (ms ����)
    property DelayedTime : integer read FDelayedTime;  /// ������ �� �ð� = ���� ���� �������� �ð� ũ�� �� �� (ms ����)
  end;

implementation

uses
  TypInfo;

{ TLatencyBuffer }

procedure TLatencyBuffer.Add(AData: pointer; ASize,APlayTime: integer);
begin
  FCS.Acquire;
  try
    FPacketBuffer.Add(AData, ASize, Pointer(APlayTime));
    FDelayedTime := FDelayedTime + APlayTime;
    do_Add;
  finally
    FCS.Release;
  end;
end;

procedure TLatencyBuffer.Clear;
begin
  FCS.Acquire;
  try
    FPacketBuffer.Clear;
    do_Clear;
  finally
    FCS.Release;
  end;
end;

constructor TLatencyBuffer.Create;
begin
  inherited;

  FRealTime := false;

  FDuration := DEFAULT_DURATION;
  FDurationLimit := DEFAULT_DURATION_LIMIT;

  do_Clear;

  FCS := TCriticalSection.Create;
  FPacketBuffer := TPacketBuffer.Create;
end;

destructor TLatencyBuffer.Destroy;
begin
  FreeAndNil(FCS);
  FreeAndNil(FPacketBuffer);

  inherited;
end;

procedure TLatencyBuffer.do_Add;
begin
  if FRealTime then Exit;

  case FState of
    // 'FDelayedTime > FDuration' ������ ����ϸ� ��輱���� ��� ���� �ߵ��� ���°� ����Ǹ鼭 ������ �� ������ �� �ִ�.
    stNormal: if FDelayedTime >= (FRealDuration + (FRealDuration div 2)) then set_State(stDelayed);

    stEmpty: if FDelayedTime >= FRealDuration then set_State(stNormal);

    stDelayed: ;
  end;
end;

procedure TLatencyBuffer.do_Clear;
begin
  FRealDuration := FDuration;
  FDelayedTime := 0;

  set_State(stEmpty);
end;

procedure TLatencyBuffer.do_Get;
begin
  if FRealTime then Exit;

  case FState of
    stNormal: if FDelayedTime = 0 then begin
      FRealDuration := FRealDuration * 2;
      if FRealDuration > DEFAULT_DURATION_LIMIT then FRealDuration := DEFAULT_DURATION_LIMIT;

      set_State(stEmpty);
    end;

    stEmpty: ;

    stDelayed: if FDelayedTime <= FRealDuration then set_State(stNormal);
  end;
end;

function TLatencyBuffer.Get(var AData: pointer; var ASize: integer): boolean;
var
  pPlayTime : pointer;
begin
  Result := false;
  AData := nil;
  ASize := 0;

  FCS.Acquire;
  try
    if (FRealTime = false) and (FState = stEmpty) then Exit;

    Result := FPacketBuffer.GetPacket(AData, ASize, pPlayTime);

    if not Result then Exit;

    FDelayedTime := FDelayedTime - Integer(pPlayTime);

    do_Get;
  finally
    FCS.Release;
  end;
end;

function TLatencyBuffer.GetIsDelayed: boolean;
begin
  Result := (FState = stDelayed) and (FRealTime = false);
end;

procedure TLatencyBuffer.SetDuration(const Value: integer);
begin
  FDuration := Value;
  FRealDuration := Value;
end;

procedure TLatencyBuffer.SetRealTime(const Value: boolean);
begin
  FRealTime := Value;
  if Value then Clear;
end;

procedure TLatencyBuffer.set_State(AValue: TState);
begin
  FState := AValue;

  Trace(
    Format(
      'TMainBuffer.set_State - FState: %s, FDelayedTime: %d, FRealDuration: %d, FDuration: %d',
      [GetEnumName(TypeInfo(TState), Integer(FState)), FDelayedTime, FRealDuration, FDuration]
    )
  );
end;

end.
