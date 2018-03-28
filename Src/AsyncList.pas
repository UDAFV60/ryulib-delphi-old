unit AsyncList;

interface

uses
  RyuLibBase, DebugTools,
  SysUtils, Classes;

type
  IAsyncListObject = interface
    ['{C9CCDEF3-128D-4649-8D71-78F5ECDC19B0}']

    function IsDeleted:boolean;
    procedure SetDeleted(AValue:boolean);

    function CompareAsyncListObject(AObject:TObject):boolean;

    procedure AsyncListObjectAdded;
    procedure AsyncListObjectRemoved;
    procedure AsyncListObjectDuplicated;

    procedure SetLeftAsyncListObject(AObject:TObject; AInterface:IAsyncListObject);
    function GetLeftAsyncListObject:TObject;
    function GetLeftAsyncListInterface:IAsyncListObject;

    procedure SetRightAsyncListObject(AObject:TObject; AInterface:IAsyncListObject);
    function GetRightAsyncListObject:TObject;
    function GetRightAsyncListInterface:IAsyncListObject;
  end;

  TAsyncListObject = class (TInterfaceBase, IAsyncListObject)
  strict private
    FIsDeleted : boolean;
    function IsDeleted:boolean;
    procedure SetDeleted(AValue:boolean);
  strict private
    FObjectLeft : TObject;
    FObjectRight : TObject;

    FInterfaceLeft : IAsyncListObject;
    FInterfaceRight : IAsyncListObject;

    procedure SetLeftAsyncListObject(AObject:TObject; AInterface:IAsyncListObject);
    function GetLeftAsyncListObject:TObject;
    function GetLeftAsyncListInterface:IAsyncListObject;

    procedure SetRightAsyncListObject(AObject:TObject; AInterface:IAsyncListObject);
    function GetRightAsyncListObject:TObject;
    function GetRightAsyncListInterface:IAsyncListObject;
  protected
    function CompareAsyncListObject(AObject:TObject):boolean; virtual;

    procedure AsyncListObjectAdded; virtual;
    procedure AsyncListObjectRemoved; virtual;
    procedure AsyncListObjectDuplicated; virtual;
  public
    constructor Create; virtual;
  end;

  TSimpleIterateProcedure = reference to procedure(AObject:IAsyncListObject);
  TIterateProcedure = reference to procedure(AObject:IAsyncListObject; var ANeedStop:boolean);

  TAsyncList = class
  private
    FCount: integer;
    function GetIsEmpty: boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure Add(AObject:IAsyncListObject);
    procedure Remove(AObject:IAsyncListObject);

    function GetFirst:IAsyncListObject;

    /// ���� ���� �ʰ� Ž���� �Ѵ�. �߰��� ���� �� ����.
    procedure Iterate(AProcedure:TSimpleIterateProcedure); overload;

    /// ���� ���� �ʰ� Ž���� �Ѵ�.  �߰��� ���� �� �ִ�.
    procedure Iterate(AProcedure:TIterateProcedure); overload;

    {*
      ����Ʈ�� ������ ������ �����忡���� �����Ͽ� ������ ó���ϰ� �ִ�.
      ����, �������� ������ �ش� �����忡 �����ؾ� �Ѵ�.
      Synchronize�� Iterate�� �޸� ���� �ɰ� Ž���� �Ѵ�.  �߰��� ���� �� ����.
    }
    procedure Synchronize(AProcedure:TSimpleIterateProcedure); overload;

    /// ���� �ɰ� Ž���� �Ѵ�.  �߰��� ���� �� ����.
    procedure Synchronize(AProcedure:TIterateProcedure); overload;

    property IsEmpty : boolean read GetIsEmpty;
    property Count : integer read FCount;
  end;

implementation


{ TAsyncListObject }

procedure TAsyncListObject.AsyncListObjectAdded;
begin

end;

procedure TAsyncListObject.AsyncListObjectDuplicated;
begin

end;

procedure TAsyncListObject.AsyncListObjectRemoved;
begin

end;

function TAsyncListObject.CompareAsyncListObject(AObject: TObject): boolean;
begin

end;

constructor TAsyncListObject.Create;
begin

end;

function TAsyncListObject.GetLeftAsyncListInterface: IAsyncListObject;
begin

end;

function TAsyncListObject.GetLeftAsyncListObject: TObject;
begin

end;

function TAsyncListObject.GetRightAsyncListInterface: IAsyncListObject;
begin

end;

function TAsyncListObject.GetRightAsyncListObject: TObject;
begin

end;

function TAsyncListObject.IsDeleted: boolean;
begin

end;

procedure TAsyncListObject.SetDeleted(AValue: boolean);
begin

end;

procedure TAsyncListObject.SetLeftAsyncListObject(AObject: TObject;
  AInterface: IAsyncListObject);
begin

end;

procedure TAsyncListObject.SetRightAsyncListObject(AObject: TObject;
  AInterface: IAsyncListObject);
begin

end;

{ TAsyncList }

procedure TAsyncList.Add(AObject: IAsyncListObject);
begin

end;

procedure TAsyncList.Clear;
begin

end;

constructor TAsyncList.Create;
begin

end;

destructor TAsyncList.Destroy;
begin

  inherited;
end;

function TAsyncList.GetFirst: IAsyncListObject;
begin

end;

function TAsyncList.GetIsEmpty: boolean;
begin

end;

procedure TAsyncList.Iterate(AProcedure: TIterateProcedure);
begin

end;

procedure TAsyncList.Iterate(AProcedure: TSimpleIterateProcedure);
begin

end;

procedure TAsyncList.Remove(AObject: IAsyncListObject);
begin

end;

procedure TAsyncList.Synchronize(AProcedure: TIterateProcedure);
begin

end;

procedure TAsyncList.Synchronize(AProcedure: TSimpleIterateProcedure);
begin

end;

end.
