unit ObjectPool;

interface

uses
  SysUtils, Classes, SyncObjs;

type
  TObjectClass = class of TObject;

  TObjectEvent = procedure (Sender:TObject; AObject:TObject) of object;

  {*
    ��Ư�� Client�� �߻��Ͽ� ��ü�� �䱸�� ��, ��ü�� �����ϱ� ���� �ڵ带 ĸ��ȭ �Ѵ�.
    ����Ʈ(�迭) ���·� ũ���� �Ѱ�� ������ ������, ����ϱ� ������ �������� �ʴ´�.

    ID�� Client�� �����ϱ� ���ؼ� ���ȴ�.

    ����ä�ÿ��� Ȱ��Ǿ���.
    ��Ư�� ����ڰ� ������ ������ �� ����� �������� ���� �� �� �ִ� ID�� �ִ�.
    ���ÿ� ���ϴ� ����ڸ��� ���� ��� ��ü�� �ʿ��ѵ�,
    ���� �����Ǿ��� ���� �� �ʿ䵵 ���� �Ʒ��� ���� ����Ѵ�.
      TSpeaker(TObjectPool.Objecs[ID]).Play( ���� ������ );
    �̹� ���� �Ǿ��� ��쿡�� �ش� ��ü�� ��� ����ϰ�,
    ó������ ��� �� ID�� ��쿡�� ���ο� ��ü�� �����Ѵ�.
  }
  TObjectPool = class
  private
    FObjectClass: TObjectClass;
    FCS : TCriticalSection;
    FList : TList;
    FObjects : array [0..$FFFF] of TObject;
  private
    FOnObjectCreated: TObjectEvent;
    FOnObjectReleased: TObjectEvent;
    function GetCount: integer;
    function GetObjects(ID: word): TObject;
    function GetObjectByIndex(Index: integer): TObject;
  public
    constructor Create(AObjectClass:TObjectClass); reintroduce;
    destructor Destroy; override;

    procedure Clear;
    procedure Remove(AObject:TObject; AID:word);
  public
    property Objects[ID:word] : TObject read GetObjects;
    property ObjectByIndex[Index:integer] : TObject read GetObjectByIndex;
    property Count : integer read GetCount;
    property OnObjectCreated : TObjectEvent read FOnObjectCreated write FOnObjectCreated;
    property OnObjectReleased : TObjectEvent read FOnObjectReleased write FOnObjectReleased;
  end;

implementation

{ TObjectPool }

procedure TObjectPool.Clear;
var
  Loop: Integer;
begin
  FCS.Acquire;
  try
    for Loop := 0 to FList.Count-1 do begin
      if Assigned(FOnObjectReleased) then FOnObjectReleased(Self, TObject(FList[Loop]));
      TObject(FList[Loop]).Free;
    end;

    FList.Clear;

    FillChar( FObjects, SizeOf(FObjects), 0 );
  finally
    FCS.Release;
  end;
end;

constructor TObjectPool.Create(AObjectClass:TObjectClass);
begin
  inherited Create;

  FObjectClass := AObjectClass;

  FCS := TCriticalSection.Create;
  FList := TList.Create;

  Clear;
end;

destructor TObjectPool.Destroy;
begin
  Clear;

  FreeAndNil(FCS);
  FreeAndNil(FList);

  inherited;
end;

function TObjectPool.GetCount: integer;
begin
  FCS.Acquire;
  try
    Result := FList.Count;
  finally
    FCS.Release;
  end;
end;

function TObjectPool.GetObjectByIndex(Index: integer): TObject;
begin
  FCS.Acquire;
  try
    Result := TObject(FList[Index]);
  finally
    FCS.Release;
  end;
end;

function TObjectPool.GetObjects(ID: word): TObject;
var
  Instance: TComponent;
begin
  FCS.Acquire;
  try
    if FObjects[ID] = nil then begin
      {$IF DEFINED(CLR)}
      FObjects[ID] := FObjectClass.NewInstance;
      FObjects[ID].Create;
      {$ELSE}
      Instance := TComponent(FObjectClass.NewInstance);
      TComponent(FObjects[ID]) := Instance;
      try
        Instance.Create(nil);
      except
        TComponent(FObjects[ID]) := nil;
        Instance := nil;
        raise;
      end;
      {$IFEND}

      FList.Add(FObjects[ID]);

      if Assigned(FOnObjectCreated) then FOnObjectCreated(Self, FObjects[ID]);
    end;

    Result := FObjects[ID];
  finally
    FCS.Release;
  end;
end;

procedure TObjectPool.Remove(AObject: TObject; AID: word);
begin
  if AObject = nil then Exit;

  FCS.Acquire;
  try
    FList.Remove(AObject);
    FObjects[AID] := nil;

    if Assigned(FOnObjectReleased) then FOnObjectReleased(Self, AObject);

    AObject.Free;
  finally
    FCS.Release;
  end;
end;

end.
