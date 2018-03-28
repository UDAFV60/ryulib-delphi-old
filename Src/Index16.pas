unit Index16;

interface

uses
  SRWLock, BinaryList,
  Classes, SysUtils;

type
  /// TIndex16���� �ε����� �ϱ� ���� �� ���ڵ尡 �����ؾ� �� ����
  IIndex16Record = interface
    ['{E23AB1F8-9722-4FEC-B8B3-763100250965}']

    /// Key�� ���� CRC16�� ��.  CRC16���� �ؽ�ó���ؼ� �˻��� ���� �ݺ� �۾��� ���δ�.
    function GetCRC:word;

    /// �ε����� ���ؼ� ���ڵ峢�� ���ϴ� ���� ����.  �ڽ��� �۴�=-1, ����=0, ũ��=1
    function Compare(ACompareTo:IIndex16Record):integer;
  end;

  TIndex = class
  private
    FSRWLock : TSRWLock;
    FBinaryList : TBinaryList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function Add(ARecord16:IIndex16Record):boolean;
    procedure Remove(ARecord16:IIndex16Record);
    function Find(ARecord16:IIndex16Record):IIndex16Record;

    /// Add�� ���� �޼ҵ�������, ���� �ɸ��� ���� �޼ҵ��̴�.
    function _Add(ARecord16:IIndex16Record):boolean;

    /// AItem�� ���� Key�� ���� ���ڵ带 ã�´�.  ���� �ɸ��� ���� �޼ҵ��̴�.
    function _Search(const ARecord16:IIndex16Record):integer;

    /// AIndex�� �ش��ϴ� ���ڵ带 �����´�.  ���� �ɸ��� ���� �޼ҵ��̴�.
    function _GetRecord(AIndex:integer):IIndex16Record;

    property SRWLock: TSRWLock read FSRWLock;
  end;

  TIndex16 = class
  private
    FItems : array [0..$FFFF] of TIndex;
    function GetItems(AIndex: integer): TIndex;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function Add(ARecord16:IIndex16Record):boolean;
    procedure Remove(ARecord16:IIndex16Record);
    function Find(ARecord16:IIndex16Record):IIndex16Record;

    property Items[AIndex:integer]: TIndex read GetItems;
  end;

implementation

function CompareLogic(Item1, Item2: Pointer): Integer;
var
  pItem1 : IIndex16Record absolute Item1;
  pItem2 : IIndex16Record absolute Item2;
begin
  Result := pItem1.Compare(pItem2);
end;

{ TIndex }

function TIndex.Add(ARecord16: IIndex16Record): boolean;
begin
  FSRWLock.AcquireExclusive;
  try
    Result := _Add(ARecord16);
  finally
    FSRWLock.ReleaseExclusive;
  end;
end;

procedure TIndex.Clear;
begin
  FSRWLock.AcquireExclusive;
  try
    FBinaryList.Clear;
  finally
    FSRWLock.ReleaseExclusive;
  end;
end;

constructor TIndex.Create;
begin
  inherited;

  FSRWLock := TSRWLock.Create;
  FBinaryList := TBinaryList.Create;
end;

destructor TIndex.Destroy;
begin
  FreeAndNil(FSRWLock);
  FreeAndNil(FBinaryList);

  inherited;
end;

function TIndex.Find(ARecord16: IIndex16Record): IIndex16Record;
var
  iIndex : integer;
begin
  FSRWLock.AcquireShared;
  try
    iIndex := FBinaryList.Search(Pointer(ARecord16), CompareLogic);
    if iIndex = -1 then Result := nil
    else Result := IIndex16Record(FBinaryList.Items[iIndex]);
  finally
    FSRWLock.ReleaseShared;
  end;
end;

procedure TIndex.Remove(ARecord16: IIndex16Record);
var
  iIndex : integer;
begin
  FSRWLock.AcquireExclusive;
  try
    iIndex := FBinaryList.Search(Pointer(ARecord16), CompareLogic);
    if iIndex > -1 then FBinaryList.Delete(iIndex);
  finally
    FSRWLock.ReleaseExclusive;
  end;
end;

function TIndex._Add(ARecord16: IIndex16Record): boolean;
begin
  Result := FBinaryList.InsertByOrder(Pointer(ARecord16), CompareLogic, true);
end;

function TIndex._GetRecord(AIndex: integer): IIndex16Record;
begin
  Result := IIndex16Record(FBinaryList.Items[AIndex]);
end;

function TIndex._Search(const ARecord16: IIndex16Record): integer;
begin
  Result := FBinaryList.Search(Pointer(ARecord16), CompareLogic);
end;

{ TIndex16 }

function TIndex16.Add(ARecord16: IIndex16Record): boolean;
begin
  Result := FItems[ARecord16.GetCRC].Add(ARecord16);
end;

procedure TIndex16.Clear;
var
  Loop: Integer;
begin
  for Loop := Low(FItems) to High(FItems) do FItems[Loop].Clear;
end;

constructor TIndex16.Create;
var
  Loop: Integer;
begin
  inherited;

  for Loop := Low(FItems) to High(FItems) do FItems[Loop] := TIndex.Create;
end;

destructor TIndex16.Destroy;
var
  Loop : integer;
begin
  for Loop := Low(FItems) to High(FItems) do FreeAndNil(FItems[Loop]);

  inherited;
end;

function TIndex16.Find(ARecord16: IIndex16Record): IIndex16Record;
begin
  Result := FItems[ARecord16.GetCRC].Find(ARecord16);
end;

function TIndex16.GetItems(AIndex: integer): TIndex;
begin
  Result := FItems[AIndex];
end;

procedure TIndex16.Remove(ARecord16: IIndex16Record);
begin
 FItems[ARecord16.GetCRC].Remove(ARecord16);
end;

end.
