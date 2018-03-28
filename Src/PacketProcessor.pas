unit PacketProcessor;

interface

uses
  RyuLibBase, ThreadUtils, SimpleThread, DynamicQueue,
  Windows, SysUtils, Classes, SyncObjs;

type
  // TODO: TPacketProcessor, TaskQueue, TWorker, TScheduler ������ ���� �Ǵ� ����
  // TODO: Bandwidth �� ���缭 �̺�Ʈ�� �߻��ϵ��� �Ӽ� �߰�

  TPacketProcessor = class
  private
    FSize : int64;
    FCS : TCriticalSection;
    FQueue : TDynamicQueue;
    function get_Packet(var APacket:pointer):boolean;
  private
    FSimpleThread : TSimpleThread;
    procedure on_Repeat(ASimpleThread:TSimpleThread);
  private
    FOnData: TDataEvent;
    FOnDataAndTag: TDataAndTagEvent;
    FSeamlessProcessor: boolean;
    FOnTerminate: TNotifyEvent;
    function GetCount: integer;
    function GetIsEmpty: boolean;
    function GetSize: int64;
    procedure SetSeamlessProcessor(const Value: boolean);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    procedure Add(AData:pointer; ASize:integer); overload;
    procedure Add(AData:pointer; ASize:integer; ATag:pointer); overload;
    procedure Add(AStream:TStream); overload;
    procedure Add(AStream:TStream; ATag:pointer); overload;
  public
    property IsEmpty : boolean read GetIsEmpty;

    /// �����Ͱ� ��� �־ 1ms ���� ����� �ٷ� ���� �� �� �ֵ��� �غ��Ѵ�. �����̶� �� ���� ������ �ʿ��� ��� ����Ѵ�.
    property SeamlessProcessor : boolean read FSeamlessProcessor write SetSeamlessProcessor;

    property Count : integer read GetCount;
    property Size : int64 read GetSize;
    property OnData : TDataEvent read FOnData write FOnData;
    property OnDataAndTag : TDataAndTagEvent read FOnDataAndTag write FOnDataAndTag;
    property OnTerminate : TNotifyEvent read FOnTerminate write FOnTerminate;
  end;

implementation

type
  TPacket = class
  private
  public
    Data : pointer;
    Size : integer;
    Tag : pointer;
    constructor Create(AData:pointer; ASize:integer; ATag:pointer); reintroduce; overload;
    constructor Create(AStream:TStream; ATag:pointer); reintroduce; overload;
  end;

{ TPacket }

constructor TPacket.Create(AData: pointer; ASize: integer; ATag: pointer);
begin
  inherited Create;

  Size := ASize;
  if Size <= 0 then begin
    Data := nil;
  end else begin
    GetMem(Data, Size);
    Move(AData^, Data^, Size);
  end;

  Tag := ATag;
end;

constructor TPacket.Create(AStream: TStream; ATag: pointer);
begin
  inherited Create;

  Size := AStream.Size;
  if Size <= 0 then begin
    Data := nil;
  end else begin
    GetMem( Data, Size );
    AStream.Position := 0;
    AStream.Write( Data^, Size );
  end;

  Tag := ATag;
end;

{ TPacketProcessor }

procedure TPacketProcessor.Add(AData: pointer; ASize: integer);
begin
  FCS.Acquire;
  try
    FQueue.Push( TPacket.Create(AData, ASize, nil) );
    FSize := FSize + ASize;
  finally
    FCS.Release;
  end;

  FSimpleThread.WakeUp;
end;

procedure TPacketProcessor.Add(AData: pointer; ASize: integer; ATag: pointer);
begin
  FCS.Acquire;
  try
    FQueue.Push( TPacket.Create(AData, ASize, ATag) );
    FSize := FSize + ASize;
  finally
    FCS.Release;
  end;

  FSimpleThread.WakeUp;
end;

procedure TPacketProcessor.Add(AStream: TStream);
begin
  FCS.Acquire;
  try
    FQueue.Push( TPacket.Create(AStream, nil) );
    FSize := FSize + AStream.Size;
  finally
    FCS.Release;
  end;

  FSimpleThread.WakeUp;
end;

procedure TPacketProcessor.Add(AStream: TStream; ATag: pointer);
begin
  FCS.Acquire;
  try
    FQueue.Push( TPacket.Create(AStream, ATag) );
    FSize := FSize + AStream.Size;
  finally
    FCS.Release;
  end;

  FSimpleThread.WakeUp;
end;

procedure TPacketProcessor.Clear;
var
  Packet : TPacket;
begin
  FCS.Acquire;
  try
    FQueue.SimpleIterate(
      procedure(AItem:pointer) begin
        Packet := Pointer( AItem );
        if Packet.Data <> nil then FreeMem(Packet.Data);
      end
    );

    FQueue.Clear;

    FSize := 0;
  finally
    FCS.Release;
  end;
end;

constructor TPacketProcessor.Create;
begin
  inherited;

  FSize := 0;
  FSeamlessProcessor := false;

  FCS := TCriticalSection.Create;
  FQueue := TDynamicQueue.Create(false);

  FSimpleThread := TSimpleThread.Create('TPacketProcessor', on_Repeat);

  RemoveThreadObject(FSimpleThread.Handle);
  SetThreadPriority(FSimpleThread.Handle, THREAD_PRIORITY_HIGHEST);
end;

destructor TPacketProcessor.Destroy;
begin
  Clear;

  FSimpleThread.Terminate;
  FSimpleThread.WakeUp;

  inherited;
end;

function TPacketProcessor.GetCount: integer;
begin
  FCS.Acquire;
  try
    Result := FQueue.Count;
  finally
    FCS.Release;
  end;
end;

function TPacketProcessor.GetIsEmpty: boolean;
begin
  FCS.Acquire;
  try
    Result := FQueue.Count = 0;
  finally
    FCS.Release;
  end;
end;

function TPacketProcessor.GetSize: int64;
begin
  FCS.Acquire;
  try
    Result := FSize;
  finally
    FCS.Release;
  end;
end;

function TPacketProcessor.get_Packet(var APacket: pointer): boolean;
begin
  Result := false;

  FCS.Acquire;
  try
    if FQueue.Count = 0 then Exit;

    FQueue.Pop( APacket );

    Result := true;
  finally
    FCS.Release;
  end;
end;

procedure TPacketProcessor.on_Repeat(ASimpleThread:TSimpleThread);
var
  Packet : TPacket;
begin
  while not ASimpleThread.Terminated do begin
    while get_Packet(Pointer(Packet)) do begin
      try
        if Assigned(FOnData) then FOnData(Self, Packet.Data, Packet.Size);
        if Assigned(FOnDataAndTag) then FOnDataAndTag(Self, Packet.Data, Packet.Size, Packet.Tag);
      finally
        if Packet.Data <> nil then FreeMem(Packet.Data);
        Packet.Free;
      end;
    end;

    if not ASimpleThread.Terminated then begin
      if FSeamlessProcessor then ASimpleThread.Sleep(1)
      else ASimpleThread.SleepTight;
    end;
  end;

  if Assigned(FOnTerminate) then FOnTerminate(Self);

//  FreeAndNil(FCS);
//  FreeAndNil(FList);
end;

procedure TPacketProcessor.SetSeamlessProcessor(const Value: boolean);
begin
  FSeamlessProcessor := Value;
end;

end.
