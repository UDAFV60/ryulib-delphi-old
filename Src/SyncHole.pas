unit SyncHole;

interface

uses
  RyuLibBase, SimpleThread, DynamicQueue,
  SysUtils, Classes, SyncObjs;

type
  TSyncDataEvent = procedure (Sender:TObject; ALayout:integer; AData:pointer; ASize:integer; ATag:pointer) of object;

  {*
    �� �뵵�� ��Ʈ��ũ�� ���� �� ������ ���� �����͸� ��ũ�ϴ� ���̴�.
    Ư�� ������ ó�� �ð��� �������� �ٸ� �����͸� Ư�� �����Ϳ� ���缭 �̺�Ʈ�� �߻���Ų��.
  }
  TSyncHole = class
  private
    FCS : TCriticalSection;
    FWorks : TDynamicQueue;
  private
    FSimpleThread : TSimpleThread;
    procedure on_Repeat(Sender:TObject);
    procedure do_Work;
    function get_Work(var AWork:pointer):boolean;
  private
    FOnAskBaseIsBusy: TBooleanResultEvent;
    FOnData: TSyncDataEvent;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    {*
      ��ũ�Ǿ�� �� ������ �Է�
      @param ALayer ��ũ�� ������ �Ǵ� �����͸� �����Ѵ�.  �̿��� �����͸� ���� �� ���� ���ȴ�.
      @param AData �ԷµǴ� �������� ������ �ּ�
      @param ASize �ԷµǴ� �������� ����Ʈ ũ��
      @param ATag ���������� ��� �Ѵ�.
    }
    procedure Add(ALayer:integer; AData:pointer; ASize:integer; ATag:pointer = nil);
  public
    /// ������ �Ǵ� ������ ó���� �Ϸ�Ǿ��� �� Ȯ���Ѵ�.
    property OnAskBaseIsBusy : TBooleanResultEvent read FOnAskBaseIsBusy write FOnAskBaseIsBusy;

    property OnData : TSyncDataEvent read FOnData write FOnData;
  end;

implementation

type
  TWork = class
  private
    FIsBase : boolean;
    FLayer : integer;
    FData : pointer;
    FSize : integer;
    FTag : pointer;
  public
    constructor Create(AIsBase:boolean; ALayout:integer; AData:pointer; ASize:integer; ATag:pointer); reintroduce;
    destructor Destroy; override;
  end;

{ TWork }

constructor TWork.Create(AIsBase: boolean; ALayout: integer; AData: pointer;
  ASize: integer; ATag: pointer);
begin
  inherited Create;

  FIsBase := AIsBase;
  FLayer := ALayout;
  FSize := ASize;

  if FSize <= 0 then begin
    FData := nil;
  end else begin
    GetMem(FData, FSize);
    Move(AData^, FData^, FSize);
  end;

  FTag := ATag;
end;

destructor TWork.Destroy;
begin
  if FData <> nil then FreeMem(FData);

  inherited;
end;

{ TSyncHole }

procedure TSyncHole.Add(ALayer: integer; AData: pointer; ASize: integer;
  ATag: pointer);
begin
  FCS.Acquire;
  try
    FWorks.Push( TWork.Create( false, ALayer, AData, ASize, ATag) );
    FSimpleThread.WakeUp;
  finally
    FCS.Release;
  end;
end;

procedure TSyncHole.Clear;
var
  Work : TWork;
begin
  FCS.Acquire;
  try
    while FWorks.Pop( Pointer(Work)) do Work.Free;
  finally
    FCS.Release;
  end;
end;

constructor TSyncHole.Create;
begin
  inherited;

  FCS := TCriticalSection.Create;
  FWorks := TDynamicQueue.Create(false);

  FSimpleThread := TSimpleThread.Create(on_Repeat);
end;

destructor TSyncHole.Destroy;
begin
  Clear;

  FSimpleThread.Terminate(1000);

  inherited;
end;

procedure TSyncHole.do_Work;
var
  Work : TWork;
begin
  while get_Work(Pointer(Work)) do begin
    try
      if Assigned(FOnData) then FOnData(Self, Work.FLayer, Work.FData, Work.FSize, Work.FTag);
    finally
      if Work <> nil then Work.Free;
    end;

    if FOnAskBaseIsBusy(Self) then Break;
  end;
end;

function TSyncHole.get_Work(var AWork: pointer): boolean;
begin
  FCS.Acquire;
  try
    Result := FWorks.Pop( AWork );
  finally
    FCS.Release;
  end;
end;

procedure TSyncHole.on_Repeat(Sender: TObject);
var
  SimpleThread : TSimpleThread absolute Sender;
begin
  while not SimpleThread.Terminated do begin
    // �̺�Ʈ�� �����Ǿ� ���� �ʰų�, Base �� �ٻ��� �ʴٸ�, ���� �� �۾��� �����Ѵ�.
    if (not Assigned(FOnAskBaseIsBusy)) or (not FOnAskBaseIsBusy(Self)) then do_Work;

    SimpleThread.Sleep(1);
  end;

  Clear;

//  FreeAndNil(FCS);
//  FreeAndNil(FWorks);
end;

end.
