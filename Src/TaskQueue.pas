unit TaskQueue;

interface

uses
  RyuLibBase, SimpleThread, DynamicQueue,
  SysUtils, Classes, SyncObjs;

type
  // TODO: TPacketProcessor, TaskQueue, TWorker, TScheduler ������ ���� �Ǵ� ����

  {*
    ó���ؾ� �� �۾��� ť�� �ְ� ���ʷ� �����Ѵ�.
    �۾��� ������ ������ �����带 �̿��ؼ� �񵿱�� �����Ѵ�.
    �۾� ��û�� �پ��� �����忡�� ����Ǵµ�, �������� ������ �ʿ� �� �� ����Ѵ�.
    ��û �� �۾��� ��û�� ������� ������ �����忡�� ����Ǿ�� �� �� ����Ѵ�.  (�񵿱� ����)
  }
  TTaskQueue = class
  private
    FCS : TCriticalSection;
    FTasks : TDynamicQueue;
    procedure do_Tasks;
    function get_Task:TObject;
  private
    FSimpleThread : TSimpleThread;
    procedure on_Repeat(Sender:TSimpleThread);
  private
    FOnTask: TDataAndTagEvent;
    FOnTerminate: TNotifyEvent;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Terminate;

    procedure Clear;

    procedure Add(AData:pointer; ASize:integer); overload;
    procedure Add(AData:pointer; ASize:integer; ATag:pointer); overload;
    procedure Add(ATag:pointer); overload;
  public
    property OnTask : TDataAndTagEvent read FOnTask write FOnTask;
    property OnTerminate : TNotifyEvent read FOnTerminate write FOnTerminate;
  end;

implementation

type
  TTask = class
  private
    FData : pointer;
    FSize : integer;
    FTag : pointer;
  public
    constructor Create(AData:pointer; ASize:integer; ATag:pointer); reintroduce;
    destructor Destroy; override;
  end;

{ TTask }

constructor TTask.Create(AData: pointer; ASize: integer; ATag: pointer);
begin
  inherited Create;

  FSize := ASize;

  if FSize <= 0 then begin
    FData := nil;
  end else begin
    GetMem(FData, FSize);
    Move(AData^, FData^, FSize);
  end;

  FTag := ATag;
end;

destructor TTask.Destroy;
begin
  if FData <> nil then FreeMem(FData);

  inherited;
end;

{ TTaskQueue }

procedure TTaskQueue.Add(AData: pointer; ASize: integer);
begin
  FCS.Acquire;
  try
    FTasks.Push( TTask.Create( AData, ASize, nil) );
    FSimpleThread.WakeUp;
  finally
    FCS.Release;
  end;
end;

procedure TTaskQueue.Add(AData: pointer; ASize: integer; ATag: pointer);
begin
  FCS.Acquire;
  try
    FTasks.Push( TTask.Create( AData, ASize, ATag) );
    FSimpleThread.WakeUp;
  finally
    FCS.Release;
  end;
end;

procedure TTaskQueue.Add(ATag: pointer);
begin
  FCS.Acquire;
  try
    FTasks.Push( TTask.Create( nil, 0, ATag) );
    FSimpleThread.WakeUp;
  finally
    FCS.Release;
  end;
end;

procedure TTaskQueue.Clear;
var
  Task : TTask;
begin
  FCS.Acquire;
  try
    while FTasks.Pop(Pointer(Task)) do Task.Free;
  finally
    FCS.Release;
  end;
end;

constructor TTaskQueue.Create;
begin
  inherited;

  FCS := TCriticalSection.Create;
  FTasks := TDynamicQueue.Create(false);

  FSimpleThread := TSimpleThread.Create('', on_Repeat);
end;

destructor TTaskQueue.Destroy;
begin
  Clear;

  FSimpleThread.Terminate;

  inherited;
end;

procedure TTaskQueue.do_Tasks;
var
  Task : TTask;
begin
  Task := Pointer( get_Task );

  while Task <> nil do begin
    try
      if Assigned(FOnTask) then FOnTask(Self, Task.FData, Task.FSize, Task.FTag);
    finally
      Task.Free;
    end;

    Task := Pointer( get_Task );
  end;
end;

function TTaskQueue.get_Task: TObject;
begin
  Result := nil;

  FCS.Acquire;
  try
    FTasks.Pop(Pointer(Result));
  finally
    FCS.Release;
  end;
end;

procedure TTaskQueue.on_Repeat(Sender: TSimpleThread);
var
  SimpleThread : TSimpleThread absolute Sender;
begin
  while not SimpleThread.Terminated do begin
    do_Tasks;

    SimpleThread.SleepTight;
  end;

  Clear;

  if Assigned(FOnTerminate) then FOnTerminate(Self);  

//  FreeAndNil(FCS);
//  FreeAndNil(FTasks);
end;

procedure TTaskQueue.Terminate;
begin
  FSimpleThread.Terminate;
end;

end.
