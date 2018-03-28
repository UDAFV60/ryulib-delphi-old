unit MemoryRing;

interface

uses
  LazyRelease, MemoryPool,
  Classes, SysUtils;

type
  {*
    ������ ũ���� ���� ť�� �̿��ؼ� �޸𸮸� Ȯ���ϰ� ����� ����
    �ٷ� �������� �ʰ�, ť�� ũ�⸸ŭ ��ٷȴٰ� �����Ѵ�.  ��Ƽ ������ ��Ȳ����
    �޸��� ������ ����Ŭ�� ��������� ���ð� ���� �پ� ����ϰ�, �Ӱ迵����
    ������� ��������, ������ �����Ѵ�.
  }
  TMemoryRing = class
  private
    FQueueSize : integer;
    FMemoryPool : TMemoryPool;
  private
    FLazyRelease : TLazyRelease;
    procedure on_Release(Sender:TObject; AObject:pointer);
  private
    function GetSize: integer;
  public
    constructor Create(AQueueSize:integer; ANeedThreadSafe:boolean); reintroduce;
    destructor Destroy; override;

    function GetMem(ASize:integer):TMemoryPage;

    property Size : integer read GetSize;
  end;

implementation

{ TMemoryRing }

constructor TMemoryRing.Create(AQueueSize:integer; ANeedThreadSafe:boolean);
begin
  inherited Create;

  FQueueSize := AQueueSize;

  FLazyRelease := TLazyRelease.Create(AQueueSize);
  FLazyRelease.OnRelease := on_Release;

  FMemoryPool := TMemoryPool.Create(ANeedThreadSafe);
end;

destructor TMemoryRing.Destroy;
begin
  FreeAndNil(FLazyRelease);
  FreeAndNil(FMemoryPool);

  inherited;
end;

function TMemoryRing.GetMem(ASize: integer): TMemoryPage;
begin
  Result := FMemoryPool.GetMem(ASize);
  FLazyRelease.Release(Result);
end;

function TMemoryRing.GetSize: integer;
begin
  Result := FMemoryPool.Size;
end;

procedure TMemoryRing.on_Release(Sender: TObject; AObject: pointer);
begin
  FMemoryPool.FreeMem(Pointer(AObject));
end;

end.
