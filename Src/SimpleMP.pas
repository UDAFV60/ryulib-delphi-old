unit SimpleMP;

interface

uses
  DebugTools, CountLock, ThreadPool,
  Windows, SysUtils, Classes;

type
  {*
    ������ ���� �� ���� ȣ���Ѵ�.
    @param Context Execute �޼ҵ��� AContext ���ڰ� �״�� ���� �˴ϴ�.
    @param ThreadNo ���� TSimpleProcedureSingle �Լ��� �����ϴ� �������� ������ ���� �˴ϴ�.
           �̸� ���ؼ� �����带 ���� �� �� �ֽ��ϴ�.
    @param ThreadCount ���� ��� ���� ��ü �������� ���ڸ� �˷��ݴϴ�.
           Execute �Լ��� ȣ�� �� �� ������ AThreadCount�� ������ ���� �����ϴ�.
  }
  TSimpleProcedureSingle = reference to procedure(Context:pointer; ThreadNo,ThreadCount:integer);

  {*
    ������ ���ο��� �͸�޼ҵ带 �ʿ��� Ƚ����ŭ �ݺ��Ѵ�.  (��ü Task�� ������ �ش� �����尡 �� �ʿ��� Ƚ�� ��ŭ)
    @param Context Execute �޼ҵ��� AContext ���ڰ� �״�� ���� �˴ϴ�.
    @param ThreadNo ���� TSimpleProcedureSingle �Լ��� �����ϴ� �������� ������ ���� �˴ϴ�.
           �̸� ���ؼ� �����带 ���� �� �� �ֽ��ϴ�.
    @param Index Execute �޼ҵ��� ATaskCount Ƚ ����ŭ �ݺ��ؼ� TSimpleProcedureRepeat�� ������ ��, ���� �ݺ��ϰ� �ִ� �����Դϴ�.
           ����ó���̱� ������ Index�� ������� ����ȴٴ� ������ �����ϴ�.
  }
  TSimpleProcedureRepeat = reference to procedure(Context:pointer; ThreadNo,Index:integer);

  TSimpleMP = class
  private
  public
    {*
       AThreadCount ���ڸ�ŭ �����带 ����, ������ �����尡 ASimpleProcedure�� ���ķ� �����մϴ�.
       ������� ASimpleProcedure�� 1:1�� ��Ī �˴ϴ�.

       AContext�� ASimpleProcedure ���ο��� ����ϰ� ���� ��ü(������)�� ������ �Ѱ��ְ� ���� �� ����մϴ�.
    }
    class procedure Execute(AContext:pointer; AThreadCount:integer; ASimpleProcedure:TSimpleProcedureSingle); overload;

    {*
      �ݺ� Ƚ��(ATaskCount)�� ������ �ִ� ��� ����մϴ�.

      ���� "for i:= 1 to 10 do ..."�� ����ó���Ѵٸ�, �Ʒ�ó�� ����ϰ� �˴ϴ�.
      AThreadCount�� ����ϰ� ���� ������ �����Դϴ�.
        TSimpleMP.Execute( nil, 10, AThreadCount,
          procedure(Context:pointer; ThreadNo,Index:integer)
          begin
            ...
          end
        );
    }
    class procedure Execute(AContext:pointer; ATaskCount,AThreadCount:integer; ASimpleProcedure:TSimpleProcedureRepeat); overload;
  end;

implementation

type
  TThreadSingleInfo = class
  private
    FLock : TCountLock;
    FThreadNo : integer;
    FThreadCount : integer;
    FContext : pointer;
    FSimpleProcedure : TSimpleProcedureSingle;
  public
    constructor Create(
      AThreadNo,AThreadCount:integer;
      ALock:TCountLock;
      AContext:pointer;
      ASimpleProcedure:TSimpleProcedureSingle); reintroduce;
  end;

  TThreadRepeatInfo = class
  private
    FLock : TCountLock;
    FThreadNo : integer;
    FContext : pointer;
    FIndex : integer;
    FCount : integer;
    FSimpleProcedure : TSimpleProcedureRepeat;
  public
    constructor Create(
      AThreadNo:integer;
      ALock:TCountLock;
      AContext:pointer;
      AIndex,ACount:integer;
      ASimpleProcedure:TSimpleProcedureRepeat); reintroduce;
  end;

{ TThreadSingleInfo }

constructor TThreadSingleInfo.Create(AThreadNo,AThreadCount: integer;
  ALock: TCountLock;
  AContext: pointer;
  ASimpleProcedure: TSimpleProcedureSingle);
begin
  inherited Create;

  FThreadNo := AThreadNo;
  FThreadCount := AThreadCount;
  FLock := ALock;
  FContext := AContext;
  FSimpleProcedure := ASimpleProcedure;
end;

{ TThreadRepeatInfo }

constructor TThreadRepeatInfo.Create(
  AThreadNo:integer;
  ALock:TCountLock;
  AContext:pointer;
  AIndex,ACount:integer;
  ASimpleProcedure:TSimpleProcedureRepeat);
begin
  inherited Create;

  FThreadNo := AThreadNo;
  FLock := ALock;
  FContext := AContext;
  FIndex := AIndex;
  FCount := ACount;
  FSimpleProcedure := ASimpleProcedure;
end;

{ TSimpleMP }

function ThreadFunction_Single(lpThreadParameter:pointer):integer; stdcall;
var
  ThreadSingleInfo : TThreadSingleInfo ABSOLUTE lpThreadParameter;
begin
  Result := 0;

  try
    try
      ThreadSingleInfo.FSimpleProcedure(ThreadSingleInfo.FContext, ThreadSingleInfo.FThreadNo, ThreadSingleInfo.FThreadCount );
    finally
      ThreadSingleInfo.FLock.Dec;
    end;
  except
    on E : Exception do Trace( Format('TSimpleMP.ThreadFunction_Repeat - %s', [E.Message]) );
  end;

  ThreadSingleInfo.Free;
end;

class procedure TSimpleMP.Execute(AContext: pointer; AThreadCount: integer;
  ASimpleProcedure: TSimpleProcedureSingle);
var
  Lock : TCountLock;
  Loop: Integer;
begin
  Lock := TCountLock.Create;
  try
    for Loop := 0 to AThreadCount-1 do begin
      Lock.Inc;
      QueueWorkItem( ThreadFunction_Single, TThreadSingleInfo.Create(Loop, AThreadCount, Lock, AContext, ASimpleProcedure) );
    end;

    Lock.WaitFor;
  finally
    Lock.Free;
  end;
end;

function ThreadFunction_Repeat(lpThreadParameter:pointer):integer; stdcall;
var
  Loop: Integer;
  ThreadRepeatInfo : TThreadRepeatInfo ABSOLUTE lpThreadParameter;
begin
  Result := 0;

  try
    try
      for Loop := 0 to ThreadRepeatInfo.FCount-1 do begin
        ThreadRepeatInfo.FSimpleProcedure(ThreadRepeatInfo.FContext, ThreadRepeatInfo.FThreadNo, ThreadRepeatInfo.FIndex + Loop );
      end;
    finally
      ThreadRepeatInfo.FLock.Dec;
    end;
  except
    on E : Exception do Trace( Format('TSimpleMP.ThreadFunction_Repeat - %s', [E.Message]) );
  end;

  ThreadRepeatInfo.Free;
end;

class procedure TSimpleMP.Execute(AContext:pointer; ATaskCount,AThreadCount: integer;
  ASimpleProcedure: TSimpleProcedureRepeat);
var
  Lock : TCountLock;
  iIndex, iTaskCount : integer;
  Loop: Integer;
begin
  iTaskCount := ATaskCount div AThreadCount;
  if iTaskCount = 0 then iTaskCount := 1;

  iIndex := 0;

  Lock := TCountLock.Create;
  try
    for Loop := 0 to AThreadCount-1 do begin
      if ATaskCount < iTaskCount then iTaskCount := ATaskCount;

      if Loop = (AThreadCount-1) then iTaskCount := ATaskCount;

      Lock.Inc;

      QueueWorkItem( ThreadFunction_Repeat, TThreadRepeatInfo.Create(Loop, Lock, AContext, iIndex, iTaskCount, ASimpleProcedure) );

      iIndex := iIndex + iTaskCount;

      ATaskCount := ATaskCount - iTaskCount;
    end;

    Lock.WaitFor;
  finally
    Lock.Free;
  end;
end;

end.
