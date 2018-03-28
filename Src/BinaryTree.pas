unit BinaryTree;

interface

uses
  RyuLibBase, DebugTools,
  Classes, SysUtils, SyncObjs;

type
  TNode = class;

  {*
    Ʈ���� ��忡 ����Ǵ� �ܺ� ��ü�̴�.
    ���� ���� �������� ���� ������, ���� �����ʹ� �ܺ� ��ü�� �ִ�.
  }
  IGusetObject = interface
    ['{7627E48B-7A92-427A-AD5D-41C578C5AEE3}']

    function GetNode:TNode;
    procedure SetNode(AValue:TNode);
  end;

  TNode = class
  {$IFDEF DEBUG}
  public
  {$ELSE}
  private
  {$ENDIF}
    FParent, FLeft, FRight : TNode;
    FGuestObject : IGusetObject;
  public
    constructor Create(AGuestObject:IGusetObject); reintroduce;

    function isFull:boolean;
    function isEmpty:boolean;
  end;

  /// Test�� �Խ�Ʈ Ŭ����
  TGusetObject = class (TInterfaceBase, IGusetObject)
  private
    FName : string;
  private
    function GetNode:TNode;
    procedure SetNode(AValue:TNode);
  public
    Node : TNode;
  public
    constructor Create(AName:string); reintroduce; virtual;
  end;

  {*
    ��� ���� ������ �ٲ���� ��� �ڽ��� �θ� ��尡 ��� �ٲ���� ���� �˷��ش�.
    ����, ��尡 �߰��Ǹ� �̺�Ʈ�� �� ���� �߻��Ѵ�.
    ����, ��� �ϳ��� �����Ǹ� ��� �ؿ� �޷� �ִ� �ڽ� ��� ���� ��ŭ �̺�Ʈ�� �߻��Ѵ�.
    @param Sender �̺�Ʈ�� �߻���Ų ��ü
    @param AParant ���� �� �θ�
    @param AChild ���� �� �θ� ���� �޴� �ڽ� ���
  }
  TNodeChangedEvent = procedure (Sender:TObject; AParent,AChild:pointer) of object;

  {*
    ���ĵ��� ���� ������ ����Ʈ�� �����̴�.
    P2P ������ �л� ó���� ���ؼ� ���������.
    ����Ʈ���� BTree.pas ������ �����϶�.
  }
  TBinaryTree = class
  private
    FHead : TNode;
    FList : TList;

    // �ڽ� ��尡 �� ä������ ���� ���
    FVacancyList : TList;

    FCS : TCriticalSection;

    procedure add_Node(AParent,AChild:TNode);
    procedure remove_Node(ANode:TNode);

    // �ڽ� ��尡 �� ä������ ���� ��带 ã�´�.
    function get_VacancyNode:TNode;

    // �ڽ� ��尡 �ϳ��� ���� ��带 ã�´�.
    function get_EmptyNode:TNode;
  private
    FOnChanged: TNodeChangedEvent;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure Add(AGusetObject:IGusetObject);
    procedure Remove(AGusetObject:IGusetObject);

  {$IFDEF DEBUG}
    /// Unit Test�� ���� �޼ҵ�
    function GetText:string;
  {$ENDIF}
  public
    property OnChanged : TNodeChangedEvent read FOnChanged write FOnChanged;
  end;

implementation

{ TNode }

constructor TNode.Create(AGuestObject: IGusetObject);
begin
  inherited Create;

  FParent := nil;
  FLeft   := nil;
  FRight  := nil;

  FGuestObject := AGuestObject;

  if AGuestObject <> nil then AGuestObject.SetNode(Self);
end;

function TNode.isEmpty: boolean;
begin
  Result := (FLeft = nil) and (FRight = nil);
end;

function TNode.isFull: boolean;
begin
  Result := (FLeft <> nil) and (FRight <> nil);
end;

{ TGusetObject }

constructor TGusetObject.Create(AName:string);
begin
  inherited Create;

  FName := AName;
end;

function TGusetObject.GetNode: TNode;
begin
  Result := Node;
end;

procedure TGusetObject.SetNode(AValue: TNode);
begin
  Node := AValue
end;

{ TBinaryTree }

procedure TBinaryTree.Add(AGusetObject: IGusetObject);
var
  NewNode, VacancyNode : TNode;
begin
  FCS.Acquire;
  try
    VacancyNode := get_VacancyNode;

    if VacancyNode = nil then
      raise Exception.Create('TBinaryTree.Add - VacancyNode = nil');

    NewNode := TNode.Create(AGusetObject);

    add_Node(VacancyNode, NewNode);

    if VacancyNode.isFull then FVacancyList.Remove(VacancyNode);

    FList.Add(NewNode);
    FVacancyList.Add(NewNode);
  finally
    FCS.Release;
  end;
end;

procedure TBinaryTree.add_Node(AParent, AChild: TNode);
begin
  AChild.FParent := AParent;

       if AParent.FLeft  = nil then AParent.FLeft  := AChild
  else if AParent.FRight = nil then AParent.FRight := AChild
end;

procedure TBinaryTree.Clear;
var
  Loop: Integer;
begin
  FCS.Acquire;
  try
    FHead.FParent := nil;
    FHead.FLeft := nil;
    FHead.FRight := nil;

    for Loop := FList.Count-1 downto 0 do TObject(FList[Loop]).Free;

    FList.Clear;

    FVacancyList.Clear;
    FVacancyList.Add(FHead);
  finally
    FCS.Release;
  end;
end;

constructor TBinaryTree.Create;
begin
  inherited;

  FHead := TNode.Create(nil);
  FHead.FParent := nil;
  FHead.FLeft := nil;
  FHead.FRight := nil;

  FList := TList.Create;

  FVacancyList := TList.Create;
  FVacancyList.Add(FHead);

  FCS := TCriticalSection.Create;
end;

destructor TBinaryTree.Destroy;
begin
  Clear;

  FreeAndNil(FHead);
  FreeAndNil(FList);
  FreeAndNil(FVacancyList);
  FreeAndNil(FCS);

  inherited;
end;

function TBinaryTree.GetText: string;
var
  Loop: Integer;
  Node : TNode;
  sParentName, sLeftName, sRightName : string;
  Parent, Left, Right, GusetObject : TGusetObject;
begin
  Result := '';

  for Loop := 0 to FList.Count-1 do begin
    Node := FList[Loop];

    GusetObject := Node.FGuestObject as TGusetObject;

    sParentName := '';

    if Node.FParent = FHead then begin
      sParentName := 'Header';
    end else if Node.FParent <> nil then begin
      Parent := Node.FParent.FGuestObject  as TGusetObject;
      sParentName := Parent.FName;
    end;

    sLeftName := '';

    if Node.FLeft  <> nil then begin
      Left := Node.FLeft.FGuestObject  as TGusetObject;
      sLeftName := Left.FName;
    end;

    sRightName := '';

    if Node.FRight <> nil then begin
      Right := Node.FRight.FGuestObject as TGusetObject;
      sRightName := Right.FName;
    end;

    Result := Result + Format('* Name: %s, (Parent: %s), (Left: %s), (Right: %s)', [GusetObject.FName, sParentName, sLeftName, sRightName]) + #13#10;
  end;
end;

function TBinaryTree.get_EmptyNode: TNode;
var
  Loop: Integer;
  EmptyNode : TNode;

  {$IFDEF DEBUG}
  Left, Right, GusetObject : TGusetObject;
  {$ENDIF}
begin
  Result := nil;

  for Loop := 0 to FVacancyList.Count-1 do begin
    EmptyNode := FVacancyList[Loop];

    {$IFDEF DEBUG}
    GusetObject := EmptyNode.FGuestObject as TGusetObject;

    Trace( 'GusetObject.FName = ' + GusetObject.FName );

    if EmptyNode.FLeft  <> nil then begin
      Left := EmptyNode.FLeft.FGuestObject  as TGusetObject;
      Trace( 'Left.FName = ' + Left.FName );
    end;

    if EmptyNode.FRight <> nil then begin
      Right := EmptyNode.FRight.FGuestObject as TGusetObject;
      Trace( 'Right.FName = ' + Right.FName );
    end;
    {$ENDIF}

    if EmptyNode.isEmpty then begin
      Result := EmptyNode;
      Break;
    end;
  end;
end;

function TBinaryTree.get_VacancyNode: TNode;
var
  VacancyNode : TNode;
begin
  Result := nil;

  while FVacancyList.Count > 0 do begin
    VacancyNode := FVacancyList[0];

    if not VacancyNode.isFull then begin
      Result := VacancyNode;
      Break;
    end;

    FVacancyList.Delete(0);
  end;
end;

procedure TBinaryTree.Remove(AGusetObject: IGusetObject);
var
  hasChild : boolean;
  Node, EmptyNode : TNode;
begin
  Node := AGusetObject.GetNode;

  if Node = nil then Exit;

  FCS.Acquire;
  try
    FList.Remove(Node);
    FVacancyList.Remove(Node);

    remove_Node(Node);

    // �ڽ��� ������ �ڽŸ� �����ϸ� �ȴ�.
    if Node.isEmpty then begin
      Node.Free;
      Exit;
    end;

    EmptyNode := get_EmptyNode;

    // ��� �� �� �ִ� ��尡 ���ٸ� �ڽ��� �������̴�.
    if EmptyNode = nil then begin
      hasChild := not Node.isEmpty;
      Node.Free;

      if hasChild then
        raise Exception.Create('TBinaryTree.Remove - hasChild');

      Exit;
    end;

    add_Node(Node.FParent, EmptyNode);

    EmptyNode.FLeft  := nil;
    EmptyNode.FRight := nil;

    if EmptyNode <> Node.FLeft  then add_Node(EmptyNode, Node.FLeft);
    if EmptyNode <> Node.FRight then add_Node(EmptyNode, Node.FRight);

    Node.Free;
  finally
    FCS.Release;
  end;
end;

procedure TBinaryTree.remove_Node(ANode: TNode);
var
  ParentNode : TNode;
begin
  ParentNode := ANode.FParent;

  if ParentNode = nil then
    raise Exception.Create('TBinaryTree.remove_Node - ParentNode = nil');

       if ParentNode.FLeft  = ANode then ParentNode.FLeft  := nil
  else if ParentNode.FRight = ANode then ParentNode.FRight := nil
end;

end.



