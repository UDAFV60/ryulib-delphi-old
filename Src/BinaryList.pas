unit BinaryList;

interface

uses
  Classes, SysUtils;

type
  /// ���� �˻��� ���� ����Ʈ Ŭ����
  TBinaryList = class
  private
    function GetCount: integer;
    function GetItems(Index: integer): pointer;
    procedure SetItems(Index: integer; const Value: pointer);
    function GetCapacity: Integer;
    procedure SetCapacity(const Value: Integer);
  protected
    FLastIndex : Integer;
    FList: TList;
  public
    constructor Create;
    destructor Destroy; override;

    /// ����Ʈ�� ����.
    procedure Clear;

    {*
      ������� ���ο� ��Ҹ� �����Ѵ�.
      @param Item �߰��� ����� ������
      @param Compare �Լ� ���۷����� ���ؼ� ����� ������ ���Ѵ�.
      @param Unique �ߺ� ��� ����
      @return ��Ұ� ����Ʈ�� ���� �Ǿ��� �� ����
    }
    function InsertByOrder(const Item:pointer; Compare:TListSortCompare; Unique:boolean=false):boolean;

    /// Index�� �ش��ϴ� ��Ҹ� �����Ѵ�.
    procedure Delete(const Index:integer);

    /// Item�� ���� ������ ��Ҹ� ã�Ƽ� Index�� ��ȯ�Ѵ�.
    function Search(const Item:pointer; Compare:TListSortCompare):integer;

    /// Item�� �� ���� �ʴ��� ���� ����� ��ҿ� ���� Index�� ��ȯ�Ѵ�.
    function FindNear(const Item:pointer; Compare:TListSortCompare):integer;
  public
    property Items[Index:integer] : pointer read GetItems write SetItems;
    property Count : integer read GetCount;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property LastIndex : integer read FLastIndex;
  end;

implementation

function DefaultCompareLogic(Item1, Item2: Pointer): Integer;
begin
  if Integer(Item1) > Integer(Item2) then Result := 1
  else if Integer(Item1) < Integer(Item2) then Result := -1
  else Result := 0;
end;

constructor TBinaryList.Create;
begin
  inherited Create;

  FLastIndex := -1;

  FList := TList.Create;
end;

destructor TBinaryList.Destroy;
begin
  FList.Free;

  inherited Destroy;
end;

procedure TBinaryList.Clear;
begin
  FList.Clear;
  FLastIndex := -1;
end;

procedure TBinaryList.Delete(const Index: Integer);
begin
  FList.Delete(Index);
end;

function TBinaryList.Search(const Item: Pointer; Compare: TListSortCompare): Integer;
var
  pItem: Pointer;
  iStart, iEnd, iMiddle: Integer;
begin
  // Can't Find
  Result := -1;

  if FList.Count = 0 then Exit
  else if (FList.Count = 1) and (Compare(Item, FList.Items[0]) = 0) then begin
    Result := 0;
    Exit;
  end;

  iStart := 0;
  iEnd := FList.Count - 1;
  while iStart <= iEnd do begin
    iMiddle := (iStart + iEnd) div 2;
    pItem := FList.Items[iMiddle];
    case Compare(Item, pItem) of
      0: begin
          Result := iMiddle;
          Exit;
        end;
      1: iStart := iMiddle + 1;
      -1: iEnd := iMiddle - 1;
    end;
  end;

  if iStart = iEnd then begin
    pItem := FList.Items[iStart];
    if Compare(Item, pItem) = 0 then Result := iStart;
  end;
end;

procedure TBinaryList.SetCapacity(const Value: Integer);
begin
  FList.Capacity := Value;
end;

procedure TBinaryList.SetItems(Index: integer; const Value: pointer);
begin
  FList[Index] := Value;
end;

function TBinaryList.FindNear(const Item: Pointer; Compare: TListSortCompare): Integer;
var
  pItem: Pointer;
  iStart, iEnd, iMiddle: Integer;
begin
  iStart := 0;
  iEnd := FList.Count - 1;
  while iStart <= iEnd do begin
    iMiddle := (iStart + iEnd) div 2;
    pItem := FList.Items[iMiddle];
    if Compare(Item, pItem) = 0 then begin
      Result := iMiddle;
      Exit;
    end else if Compare(pItem, Item) < 0 then iStart := iMiddle + 1
    else if Compare(pItem, Item) > 0 then iEnd := iMiddle - 1;
  end;

  if iEnd < 0 then iEnd := 0;
  if iStart > iEnd then iStart := iEnd;

  Result := iStart;
end;

function TBinaryList.GetCapacity: Integer;
begin
  Result := FList.Capacity;
end;

function TBinaryList.GetCount: integer;
begin
  Result := FList.Count;
end;

function TBinaryList.GetItems(Index: integer): pointer;
begin
  Result := FList[Index];
end;

function TBinaryList.InsertByOrder(const Item: Pointer; Compare: TListSortCompare;
  Unique: boolean=false): boolean;
var
  pItem : Pointer;
begin
  Result := true;

  if FList.Count = 0 then begin
    FList.Add(Item);
    FLastIndex := 0;
    Exit;
  end;

  FLastIndex := FindNear(Item, Compare);

  pItem := FList.Items[FLastIndex];
  case Compare(pItem, Item) of
    0 : if Unique then begin
      Result := false;
    end else begin
      FList.Insert(FLastIndex, Item);
    end;

   -1 : begin
     if FLastIndex >= FList.Count-1 then begin
       FList.Add(Item);
     end else begin
       FList.Insert(FLastIndex+1, Item);
     end;

     FLastIndex := FLastIndex + 1;
   end;

    1 : if FLastIndex <= 0 then begin
      FList.Insert(0, Item);
      FLastIndex := 0;
    end else begin
      FList.Insert(FLastIndex-1, Item);
      FLastIndex := FLastIndex -1 ;
    end;

    else
      raise Exception.Create(ClassName+'.InsertByOrder: ');
  end;
end;

end.

