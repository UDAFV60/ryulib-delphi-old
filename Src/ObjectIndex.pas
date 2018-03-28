unit ObjectIndex;

interface

uses
  LazyRelease, BinaryList,
  SysUtils, Classes, SyncObjs;

type
  TObjectKey = class
  private
  public
    Key : string;
    Value : TObject;
  end;

  TFunctionCreateObject = reference to function:TObject;

  /// ���ڿ��� Ű ������ �ϴ� ��ü�� ���� Index
  TObjectIndex<T: class> = class
  private
    FCS : TCriticalSection;
    FBinaryList : TBinaryList;
    FLazyDestroy : TLazyDestroy;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    /// AKey�� �ش��ϴ� ��ü�� �߰��Ѵ�.  �̹� �ִ� ��ü�̸� ���� ��ü���� ��ȯ�Ѵ�.
    function Add(AKey:string; AFunctionCreateObject:TFunctionCreateObject):T;

    /// AKey�� �ش��ϴ� ��ü�� ã�´�.
    function Find(AKey:string):T;

    /// AKey�� �ش��ϴ� ��ü�� �����Ѵ�.
    procedure Remove(AKey:string);
  end;

function CompareLogic(Item1, Item2: Pointer): Integer;

implementation

function CompareLogic(Item1, Item2: Pointer): Integer;
var
  pItem1, pItem2 : TObjectKey;
begin
  pItem1 := TObjectKey(Item1);
  pItem2 := TObjectKey(Item2);

  if pItem1.Key > pItem2.Key then Result := 1
  else if pItem1.Key < pItem2.Key then Result := -1
  else Result := 0;
end;

{ TObjectIndex }

function TObjectIndex<T>.Add(AKey: string; AFunctionCreateObject:TFunctionCreateObject): T;
var
  iIndex : integer;
  Src, Dst : TObjectKey;
begin
  Src := TObjectKey.Create;
  Src.Key := AKey;

  FCS.Acquire;
  try
    iIndex := FBinaryList.Search( Src, CompareLogic );

    if iIndex > -1 then begin
      Dst := FBinaryList.Items[iIndex];
      Result := Pointer(Dst.Value);
    end else begin
      Result := Pointer(AFunctionCreateObject);

      Dst := TObjectKey.Create;
      Dst.Key := AKey;
      Dst.Value := Result;

      FBinaryList.InsertByOrder( Dst, CompareLogic, true );
    end;
  finally
    FCS.Release;

    Src.Free;
  end;
end;

procedure TObjectIndex<T>.Clear;
var
  Loop: Integer;
begin
  FCS.Acquire;
  try
    for Loop := 0 to FBinaryList.Count-1 do TObject(FBinaryList.Items[Loop]).Free;
    FBinaryList.Clear;
  finally
    FCS.Release;
  end;
end;

constructor TObjectIndex<T>.Create;
const
  LAZYDESTROY_SIZE = 1024;
begin
  inherited;

  FCS := TCriticalSection.Create;
  FBinaryList := TBinaryList.Create;
  FLazyDestroy := TLazyDestroy.Create(LAZYDESTROY_SIZE);
end;

destructor TObjectIndex<T>.Destroy;
begin
  Clear;

  FreeAndNil(FCS);
  FreeAndNil(FBinaryList);
  FreeAndNil(FLazyDestroy);

  inherited;
end;

function TObjectIndex<T>.Find(AKey: string): T;
var
  iIndex : integer;
  Src, Dst : TObjectKey;
begin
  Src := TObjectKey.Create;
  Src.Key := AKey;

  FCS.Acquire;
  try
    iIndex := FBinaryList.Search( Src, CompareLogic );

    if iIndex > -1 then begin
      Dst := FBinaryList.Items[iIndex];
      Result := Pointer(Dst.Value);
    end else begin
      Result := nil
    end;
  finally
    FCS.Release;

    Src.Free;
  end;
end;

procedure TObjectIndex<T>.Remove(AKey: string);
var
  iIndex : integer;
  Src, Dst : TObjectKey;
begin
  Src := TObjectKey.Create;
  Src.Key := AKey;

  FCS.Acquire;
  try
    iIndex := FBinaryList.Search( Src, CompareLogic );

    if iIndex > -1 then begin
      Dst := FBinaryList.Items[iIndex];
      FLazyDestroy.Release( Dst.Value );
      Dst.Free;

      FBinaryList.Delete( iIndex );
    end;
  finally
    FCS.Release;

    Src.Free;
  end;
end;

end.
