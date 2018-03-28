///  ��Ŷ�� ���� ���Ϸ� �߶� ����Ѵ�.
unit PacketSlice;

interface

uses
  DebugTools, RyuLibBase,
  Classes, SysUtils;

const
  /// ��Ŷ�� Seq ��ȣ�� �������� �з��ؼ� �����ۿ� ��� ���´�.  �ش� �������� ũ��.
  RING_SIZE = 64;

  /// ������ ���� �� �ִ� �ִ� ũ�� ����
  MAX_SLICE_SIZE = 2 * 1024;

type
  TPacketHeader = packed record
    Seq : word;
    Index : byte;
    Size : integer;
  end;

  TPacketUnit = packed record
    Header : TPacketHeader;
    Data : packed array [0..MAX_SLICE_SIZE] of byte;
  end;
  PPacket = ^TPacketUnit;

  TPacket = class
  private
    FSliceSize : integer;

    FSeq: integer;

    // ������� ����� ũ��
    FSize : integer;

    FIsPerfect : boolean;

    // TODO: Heap �޸𸮻��, TList �� ��ȯ
    FList : array [0..512] of TPacketUnit;
  public
    constructor Create(ASliceSize:integer); reintroduce;

    procedure Add(AData:pointer; ASize:integer);

    function Get(var AData:pointer; var ASize:integer):boolean;
  public
    property Seq : integer read FSeq;
  end;

  /// �߶��� ��Ŷ�� ��ģ��.
  TPacketSliceMerge = class
  private
    FIndex : integer;
    FList : array [0..RING_SIZE-1] of TPacket;
    function find_Seq(ASeq:integer):integer;
    function add_Seq(ASeq:integer):TPacket;
  private
    FSliceSize : integer;
  public
    constructor Create(ASliceSize:integer); reintroduce;
    destructor Destroy; override;

    procedure Clear;
    function GetPacket(AData:pointer; ASize:integer):TPacket;
  end;

  TIterateProcedure = reference to procedure(AData:pointer; ASize:integer);

  /// ��Ŷ�� ���� ũ�� ���Ϸ� �߶󳽴�.
  TPacketSlice = class
  private
    FSeq : integer;
    FSliceSize : integer;
    FOnData: TDataEvent;
  public
    constructor Create(ASliceSize:integer); reintroduce;

    procedure Execute(AData:pointer; ASize:integer); overload;
    procedure Execute(AData:pointer; ASize:integer; AProcedure:TIterateProcedure); overload;
  public
    property OnData : TDataEvent read FOnData write FOnData;
  end;

implementation

{ TPacket }

procedure TPacket.Add(AData: pointer; ASize: integer);
var
  pPacket : ^TPacketUnit absolute AData;
begin
  Move(AData^, FList[pPacket^.Header.Index], ASize);

  FSize := FSize + ASize - SizeOf(TPacketHeader);

  FIsPerfect := FSize = pPacket^.Header.Size;

  {$IFDEF DEBUG}
//  Trace( Format('pPacket^.Header.Index: %d, pPacket^.Header.Size: %d, ASize: %d, FSize: %d', [Packet^.Header.Index, Packet^.Header.Size, ASize, FSize]) );
//  if FIsPerfect then Trace( 'TPacketSlice.Add - FIsPerfect = true' );
  {$ENDIF}
end;

constructor TPacket.Create(ASliceSize:integer);
begin
  inherited Create;

  FSliceSize := ASliceSize;

  FSeq := 0;
  FSize := 0;
  FIsPerfect := false;

  FillChar(FList, SizeOf(FList), 0);
end;

function TPacket.Get(var AData: pointer; var ASize: integer): boolean;
var
  Loop: Integer;
  pDst : PByte;
  BytesToSend : integer;
begin
  AData := nil;
  ASize := 0;

  Result := FIsPerfect;
  if not Result then Exit;

  // FSliceSize�� ���ؼ� ������ �迭 ���ҿ� �󸶳� �����͸� ������ �� �� �Ű� ���� �ʾƵ� �ȴ�.  (��踦 �Ѿ�� ���� ����)
  GetMem(AData, FSize + FSliceSize);
  ASize := FSize;

  pDst := AData;
  BytesToSend := ASize;

  for Loop := Low(FList) to High(FList) do begin
    if BytesToSend <= 0 then Exit;

    Move(FList[Loop].Data, pDst^, FSliceSize);

    Inc(pDst, FSliceSize);
    BytesToSend := BytesToSend - FSliceSize;
  end;

  FreeMem(AData);
  AData := nil;

  ASize := 0;

  Result := false;
end;

{ TPacketSliceMerge }

function TPacketSliceMerge.add_Seq(ASeq: integer): TPacket;
begin
  Result := TPacket.Create(FSliceSize);
  Result.FSeq := ASeq;

  FIndex := (FIndex + 1) mod RING_SIZE;

  if FList[FIndex] <> nil then FList[FIndex].Free;

  FList[FIndex] := Result;
end;

function TPacketSliceMerge.find_Seq(ASeq: integer): integer;
var
  Loop, index : integer;
begin
  Result := -1;

  index := FIndex;
  for Loop := Low(FList) to High(FList) do begin
    if (FList[index] <> nil) and (FList[index].Seq = ASeq) then begin
      Result := index;
      Exit;
    end;

   index := (index + 1) mod RING_SIZE;
  end;
end;

procedure TPacketSliceMerge.Clear;
begin
  // TODO:
end;

constructor TPacketSliceMerge.Create(ASliceSize:integer);
begin
  inherited Create;

  if ASliceSize > MAX_SLICE_SIZE then
    raise Exception.Create('TPacketSliceMerge.Create - ASliceSize > MAX_SLICE_SIZE');

  FSliceSize := ASliceSize;

  FIndex := 0;
  FillChar(FList, SizeOf(FList), 0);
end;

destructor TPacketSliceMerge.Destroy;
var
  Loop: Integer;
begin
  for Loop := Low(FList) to High(FList) do
    if FList[Loop] <> nil then begin
      FList[Loop].Free;
      FList[Loop] := nil
    end;

  inherited;
end;

function TPacketSliceMerge.GetPacket(AData: pointer; ASize: integer): TPacket;
var
  index : integer;
  pPacket : ^TPacketUnit absolute AData;
begin
  index := find_Seq(pPacket^.Header.Seq);

  if index = -1 then begin
    Result := add_Seq(pPacket^.Header.Seq);
  end else begin
    Result := FList[index];
  end;

  Result.Add(AData, ASize);
end;

{ TPacketSlice }

constructor TPacketSlice.Create(ASliceSize: integer);
begin
  inherited Create;

  if ASliceSize > MAX_SLICE_SIZE then
    raise Exception.Create('TPacketSlice.Create - ASliceSize > MAX_SLICE_SIZE');

  FSliceSize := ASliceSize;

  FSeq := 0;
end;

procedure TPacketSlice.Execute(AData: pointer; ASize: integer);
var
  pData : pbyte;
  iSize, iSizeOfSlice : integer;
  PacketUnit : TPacketUnit;
begin
  FSeq := FSeq + 1;

  PacketUnit.Header.Seq := FSeq;
  PacketUnit.Header.Index := 0;
  PacketUnit.Header.Size := ASize;

  pData := AData;

  iSize := ASize;

  while iSize > 0 do begin
    if iSize >= FSliceSize  then iSizeOfSlice := FSliceSize
    else iSizeOfSlice := iSize;

    iSize := iSize - FSliceSize;

    Move(pData^, PacketUnit.Data[0], iSizeOfSlice);

    Inc(pData, iSizeOfSlice);

    if Assigned(FOnData) then FOnData(Self, @PacketUnit, SizeOF(TPacketHeader) + iSizeOfSlice);

    PacketUnit.Header.Index := PacketUnit.Header.Index + 1;
  end;
end;

procedure TPacketSlice.Execute(AData: pointer; ASize: integer;
  AProcedure: TIterateProcedure);
var
  pData : pbyte;
  iSize, iSizeOfSlice : integer;
  PacketUnit : TPacketUnit;
begin
  FSeq := FSeq + 1;

  PacketUnit.Header.Seq := FSeq;
  PacketUnit.Header.Index := 0;
  PacketUnit.Header.Size := ASize;

  pData := AData;

  iSize := ASize;

  while iSize > 0 do begin
    if iSize >= FSliceSize  then iSizeOfSlice := FSliceSize
    else iSizeOfSlice := iSize;

    iSize := iSize - FSliceSize;

    Move(pData^, PacketUnit.Data[0], iSizeOfSlice);

    Inc(pData, iSizeOfSlice);

    AProcedure(@PacketUnit, SizeOF(TPacketHeader) + iSizeOfSlice);

    PacketUnit.Header.Index := PacketUnit.Header.Index + 1;
  end;
end;

end.
