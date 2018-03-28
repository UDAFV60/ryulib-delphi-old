unit glCanvas;

interface

uses
  DebugTools, RyuLibBase, SimpleThread, RyuGraphics,
  Windows, SysUtils, Classes, Controls, Graphics, SyncObjs;

const
  DRAWDATA_LIST_COUNT = 256;

  ERROR_CAN_NOT_INIT    = -1;
  ERROR_TOO_OLD_VERSION = -2;

type
  TDrawBitmapFunction = reference to function(Bitmap:TBitmap):boolean;

  TDrawData = packed record
    X,Y : word;
  end;

  TDrawDataList = packed array [0..DRAWDATA_LIST_COUNT-1] of TDrawData;

  TglCanvas = class (TCustomControl)
  private
    FVersionPtr : PAnsiChar;
    FVersion : AnsiString;
    FInitialized : boolean;
    FIsFBitmapLayerClear : boolean;
    FCS : TCriticalSection;
    FBitmap : TBitmap;
    FBitmapResize : TBitmap;
    FBitmapLayer : TBitmap;
    procedure glInit;
    procedure glDraw;
  private
    FSimpleThread : TSimpleThread;
    procedure on_FSimpleThread_Execute(ASimpleThread:TSimpleThread);
  protected
    procedure Resize; override;
    procedure Paint; override;
  protected
    FMouseDown : TPoint;
    FOldWindowSize : TSize;
    FDrawDataIndex : integer;
    FDrawDataList : TDrawDataList;

    procedure add_DrawData(AX,AY:integer);

    procedure MouseDown(Button:TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure MouseMove(Shift:TShiftState; X,Y:Integer); override;
    procedure MouseUp(Button:TMouseButton; Shift:TShiftState; X,Y:Integer); override;
  private
    FOnDrawData: TDataEvent;
    FCanDraw: boolean;
    FStretch: boolean;
    FOnError: TIntegerEvent;
    FUseGDI: boolean;
    FIsBusy: boolean;
    function GetPenColor: TColor;
    function GetTransparentColor: TColor;
    procedure SetPenColor(const Value: TColor);
    procedure SetTransparentColor(const Value: TColor);
    procedure SetStretch(const Value: boolean);
    function GetVersion: string;
    procedure SetUseGDI(const Value: boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;

    procedure Draw(ABitmap:TBitmap); overload;
    procedure Draw(ADrawBitmapFunction:TDrawBitmapFunction); overload;
  published
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  published
    property Version : string read GetVersion;
    property CanDraw : boolean read FCanDraw write FCanDraw;
    property Stretch : boolean read FStretch write SetStretch;
    property PenColor : TColor read GetPenColor write SetPenColor;
    property TransparentColor : TColor read GetTransparentColor write SetTransparentColor;

    /// ��� ���� Bitmap�� ����.
    property IsBusy : boolean read FIsBusy;

    /// OpenGL�� ������� �ʰ� GDI�� ���ؼ��� �׸���� ��ȯ
    property UseGDI : boolean read FUseGDI write SetUseGDI;

    property Bitmap : TBitmap read FBitmap;
    property BitmapLayer : TBitmap read FBitmapLayer;
    property OnDrawData : TDataEvent read FOnDrawData write FOnDrawData;
    property OnError : TIntegerEvent read FOnError write FOnError;
  end;

implementation

const
  GL_DEPTH_BUFFER_BIT                 = $00000100;
  GL_UNSIGNED_BYTE                    = $1401;
  GL_COLOR_BUFFER_BIT                 = $00004000;
  GL_VERSION                          = $1F02;

type
  GLbitfield = Cardinal;
  GLsizei = Integer;
  GLenum = Cardinal;

  TglGetString = function  (name: GLenum): PAnsiChar; stdcall;
  TwglCreateContext= function (DC: HDC): HGLRC; stdcall;
  TglClear = procedure (mask: GLbitfield); stdcall;
  TglDrawPixels = procedure (width, height: GLsizei; format, pixeltype: GLenum; pixels: Pointer); stdcall;

var
  glGetString : TglGetString = nil;
  wglCreateContext : TwglCreateContext = nil;
  glClear : TglClear = nil;
  glDrawPixels : TglDrawPixels = nil;

{ TglCanvas }

procedure TglCanvas.add_DrawData(AX, AY: integer);
begin
  if (Width * Height) = 0 then Exit;

  FDrawDataList[FDrawDataIndex].X := AX * $FFFF div Width;
  FDrawDataList[FDrawDataIndex].Y := AY * $FFFF div Height;

  FDrawDataIndex := FDrawDataIndex + 1;

  if FDrawDataIndex >= DRAWDATA_LIST_COUNT then begin
    if Assigned(FOnDrawData) then FOnDrawData( Self, @FDrawDataList, FDrawDataIndex * SizeOf(TDrawData) );

    FBitmapLayer.Canvas.MoveTo( AX, AY );

    FDrawDataIndex := 0;

    FDrawDataList[FDrawDataIndex].X := AX * $FFFF div Width;
    FDrawDataList[FDrawDataIndex].Y := AY * $FFFF div Height;

    FDrawDataIndex := FDrawDataIndex + 1;
  end;
end;

procedure TglCanvas.Clear;
begin
  FDrawDataIndex := 0;

  FIsFBitmapLayerClear := true;

  FCS.Acquire;
  try
    FBitmapLayer.Canvas.FillRect( Rect(0, 0, Width, Height) );
  finally
    FCS.Release;
  end;

  FSimpleThread.WakeUp;
end;

constructor TglCanvas.Create(AOwner: TComponent);
const
  DEFAULT_PEN_COLOR = clRed;
  DEFAULT_TRANSPARENT_COLOR = $578390;
begin
  inherited;

  MakeOpaque( Self );

  FVersionPtr := nil;
  Color := clBlack;
  FDrawDataIndex := 0;
  FInitialized := false;
  FIsFBitmapLayerClear := true;
  FUseGDI := false;

  FCanDraw := false;
  FIsBusy := false;
  FStretch := true;

  DoubleBuffered := true;
  ControlStyle := ControlStyle + [csOpaque];

  FCS := TCriticalSection.Create;

  FBitmap := TBitmap.Create;
  FBitmap.Canvas.Brush.Color := clBlack;
  FBitmap.PixelFormat := pf32bit;

  FBitmapResize := TBitmap.Create;
  FBitmapResize.Canvas.Brush.Color := clBlack;
  FBitmapResize.PixelFormat := pf32bit;

  FBitmapLayer := TBitmap.Create;
  FBitmapLayer.PixelFormat := pf32bit;
  FBitmapLayer.Canvas.Pen.Color := DEFAULT_PEN_COLOR;
  FBitmapLayer.Canvas.Pen.Width := 3;
  FBitmapLayer.Canvas.Brush.Color := DEFAULT_TRANSPARENT_COLOR;
  FBitmapLayer.TransparentColor := DEFAULT_TRANSPARENT_COLOR;
  FBitmapLayer.Transparent := true;

  FSimpleThread := TSimpleThread.Create('TglCanvas', on_FSimpleThread_Execute);
  FSimpleThread.FreeOnTerminate := false;
end;

destructor TglCanvas.Destroy;
begin
  FSimpleThread.Terminate;

  inherited;
end;

procedure TglCanvas.Draw(ABitmap: TBitmap);
begin
  FCS.Acquire;
  try
    if ABitmap = nil then FBitmap.Width := 0
    else AssignBitmap( ABitmap, FBitmap );
  finally
    FCS.Release;
  end;

  FIsBusy := true;
  FSimpleThread.WakeUp;
end;

procedure TglCanvas.Draw(ADrawBitmapFunction: TDrawBitmapFunction);
var
  isBitmapReady : boolean;
begin
  FCS.Acquire;
  try
    isBitmapReady := ADrawBitmapFunction( FBitmap );
  finally
    FCS.Release;
  end;

  if isBitmapReady then begin
    FIsBusy := true;
    FSimpleThread.WakeUp;
  end;
end;

function TglCanvas.GetPenColor: TColor;
begin
  Result := FBitmapLayer.Canvas.Pen.Color;
end;

function TglCanvas.GetTransparentColor: TColor;
begin
  Result := FBitmapLayer.TransparentColor;
end;

function TglCanvas.GetVersion: string;
begin
  Result := String( FVersion );
end;

procedure setupPixelFormat(DC: HDC);
const
  pfd: TPIXELFORMATDESCRIPTOR = (nSize: sizeof(TPIXELFORMATDESCRIPTOR); // size
    nVersion: 1; // version
    dwFlags: PFD_SUPPORT_OPENGL or PFD_DRAW_TO_WINDOW or PFD_DOUBLEBUFFER;
    // support double-buffering
    iPixelType: PFD_TYPE_RGBA; // color type
    cColorBits: 24; // preferred color depth
    cRedBits: 0; cRedShift: 0; // color bits (ignored)
    cGreenBits: 0; cGreenShift: 0; cBlueBits: 0; cBlueShift: 0; cAlphaBits: 0;
    cAlphaShift: 0; // no alpha buffer
    cAccumBits: 0; cAccumRedBits: 0; // no accumulation buffer,
    cAccumGreenBits: 0; // accum bits (ignored)
    cAccumBlueBits: 0; cAccumAlphaBits: 0; cDepthBits: 16; // depth buffer
    cStencilBits: 0; // no stencil buffer
    cAuxBuffers: 0; // no auxiliary buffers
    iLayerType: PFD_MAIN_PLANE; // main layer
    bReserved: 0; dwLayerMask: 0; dwVisibleMask: 0; dwDamageMask: 0;);
  // no layer, visible, damage masks
var
  pixelFormat: integer;
begin
  pixelFormat := ChoosePixelFormat(DC, @pfd);

  if (pixelFormat = 0) then
    raise Exception.Create('setupPixelFormat - pixelFormat = 0');

  if (SetPixelFormat(DC, pixelFormat, @pfd) <> TRUE) then
    raise Exception.Create('setupPixelFormat - SetPixelFormat(DC, pixelFormat, @pfd) <> TRUE');
end;

procedure DrawBitmap(ASrc,ADst:TBitmap);
const
//  DEFAULT_TRANSPARENT_COLOR = $578390;
  DEFAULT_TRANSPARENT_COLOR = $908357;
var
  Loop: Integer;
  pSrc, pDst : PDWord;
begin
  if (ASrc.Width <> ADst.Width) or (ASrc.Height <> ADst.Height) then Exit;

  pSrc := ASrc.ScanLine[ASrc.Height-1];
  pDst := ADst.ScanLine[ADst.Height-1];

  for Loop := 1 to ASrc.Width*ASrc.Height do begin
    if pSrc^ <> DEFAULT_TRANSPARENT_COLOR then pDst^ := pSrc^;

    Inc(pSrc);
    Inc(pDst);
  end;
end;

procedure TglCanvas.glDraw;
const
  GL_BGRA = $80E1;
begin
  try
    if (not FUseGDI) and Assigned(glClear) then glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

    if ((FBitmap.Width * FBitmap.Height) <> 0) and ((Width * Height) <> 0) then begin
      FCS.Acquire;
      try
        FBitmapResize.Width  := Width;
        FBitmapResize.Height := Height;

        if FStretch then SmoothResize(FBitmap, FBitmapResize)
        else AssignBitmap(FBitmap, FBitmapResize);

        if not FIsFBitmapLayerClear then begin
          FBitmapLayer.Width  := FBitmapResize.Width;
          FBitmapLayer.Height := FBitmapResize.Height;

          DrawBitmap( FBitmapLayer, FBitmapResize );
        end;
      finally
        FCS.Release;
      end;

      // OpenGL �ʱ�ȭ�� �ȵǾ��ų� ����̹��� ��ġ �Ǿ� ���� �ʴ�.
      if FUseGDI or (FVersionPtr = nil) then begin
        Invalidate;
        Exit;
      end;

      FCS.Acquire;
      try
        if Assigned(glDrawPixels) then glDrawPixels(FBitmapResize.Width, FBitmapResize.Height, GL_BGRA, GL_UNSIGNED_BYTE, FBitmapResize.ScanLine[FBitmapResize.Height-1]);
      finally
        FCS.Release;
      end;
    end;

    SwapBuffers(wglGetCurrentDC);
  except
    on E : Exception do begin
      FUseGDI := true;
      Trace( 'TglCanvas.glDraw - ' + E.Message );
    end;
  end;
end;

procedure TglCanvas.glInit;
var
  DC: HDC;
  RC: HGLRC;
  isGL_Working : boolean;
begin
  isGL_Working :=
    Assigned(glGetString) and
    Assigned(wglCreateContext) and
    Assigned(glClear) and
    Assigned(glDrawPixels);

  if isGL_Working then begin
    try
      DC := GetDC(Handle);
      setupPixelFormat(DC);
      RC := wglCreateContext(DC);
      wglMakeCurrent(DC, RC);

      FVersionPtr := glGetString( GL_VERSION );
      if FVersionPtr <> nil then FVersion := StrPas(FVersionPtr);
    except
      FVersionPtr := nil;
      FVersion := '';
    end;
  end else begin
    FVersionPtr := nil;
    FVersion := '';
  end;

  if Assigned(FOnError) then begin
    if FVersionPtr = nil then FOnError(Self, ERROR_CAN_NOT_INIT)
    else begin
      // 1.x.x ������ ���ɿ� ������ ���� �� �ִ�.
      if Copy(FVersion, 1, 1) = '1' then begin
        FOnError(Self, ERROR_TOO_OLD_VERSION);
        Trace( 'ERROR_TOO_OLD_VERSION' );
      end;
    end;
  end;

  {$IFDEF DEBUG}
  Trace( 'TglCanvas.glInit - OpenGL Version: '+ FVersion );
  {$ENDIF}

  FInitialized := true;
end;

procedure TglCanvas.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  FDrawDataIndex := 0;

  if not FCanDraw then Exit;

  add_DrawData( X, Y );

  FMouseDown := Point( X, Y);

  FOldWindowSize.cx := Width;
  FOldWindowSize.cy := Height;

  FCS.Acquire;
  try
    FBitmapLayer.Canvas.MoveTo( X, Y );
  finally
    FCS.Release;
  end;
end;

procedure TglCanvas.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if not FCanDraw then Exit;

  if Shift = [ssLeft] then begin
    FCS.Acquire;
    try
      FBitmapLayer.Canvas.LineTo( X, Y );
    finally
      FCS.Release;
    end;

    FIsFBitmapLayerClear := false;

    FSimpleThread.WakeUp;

    add_DrawData( X, Y );
  end;
end;

function PointDistance(A,B:TPoint):integer;
begin
  Result := Round( SQRT (SQR(A.X-B.X) + SQR(A.Y-B.Y)) );
end;

procedure TglCanvas.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
const
  POINT_DISTANCE_LIMIT = 1;
begin
  inherited;

  if not FCanDraw then Exit;

  // �׸��� ���� ��Ʈ���� ũ�Ⱑ ���Ѵٸ� �׸��� ������ ����Ѵ�.
  if (FOldWindowSize.cx <> Width) or (FOldWindowSize.cy <> Height) then begin
    FCS.Acquire;
    try
      FBitmapLayer.Canvas.FillRect( Rect(0, 0, Width, Height) );
    finally
      FCS.Release;
    end;

    FSimpleThread.WakeUp;

    Exit;
  end;

  // �׸��� ���� ���콺 ��ġ�� �� �� �̻� ���߰ų�, ��ġ�� 1 �ȼ� �̻� ������ ��츸 ó�� ������ ����
  // ����Ŭ�� ���� �׸��� �������� �����ϴ� ���� ����
  if (FDrawDataIndex > 1) or (PointDistance(FMouseDown, Point(X, Y)) > POINT_DISTANCE_LIMIT) then begin
    if Assigned(FOnDrawData) then FOnDrawData( Self, @FDrawDataList, FDrawDataIndex * SizeOf(TDrawData) );
    FDrawDataIndex := 0;
  end;
end;

procedure TglCanvas.on_FSimpleThread_Execute(ASimpleThread:TSimpleThread);
var
  OldWidth, OldHeight : integer;
begin
  ASimpleThread.SleepTight;

  OldWidth  := 0;
  OldHeight := 0;

  try
    if IsWindowVisible(Handle) then begin
      glInit;

      OldWidth  := Width;
      OldHeight := Height;
    end;
  except
  end;

  while not ASimpleThread.Terminated do begin
    try
      if FInitialized and IsWindowVisible(Handle) then glDraw
      else begin
        OldWidth  := 0;
        OldHeight := 0;
      end;
    except
      OldWidth  := 0;
      OldHeight := 0;
    end;

    FIsBusy := false;

    ASimpleThread.SleepTight;

    if (not FInitialized) or (Width <> OldWidth) or (Height <> OldHeight) then begin
      try
        if (not FUseGDI) and IsWindowVisible(Handle) then begin
          glInit;

          OldWidth := Width;
          OldHeight := Height;
        end;
      except
        OldWidth  := 0;
        OldHeight := 0;
      end;
    end;
  end;

//  FreeAndNil(FCS);
//  FreeAndNil(FBitmap);
//  FreeAndNil(FBitmapResize);
//  FreeAndNil(FBitmapLayer);
end;

procedure TglCanvas.Paint;
begin
  inherited;

  // OpenGL �ʱ�ȭ�� �ȵǾ��ų� ����̹��� ��ġ �Ǿ� ���� �ʴ�.
  if FUseGDI or (FVersionPtr = nil) then begin
    FCS.Acquire;
    try
      Canvas.Draw( 0, 0, FBitmapResize );
    finally
      FCS.Release;
    end;
  end else begin
    FSimpleThread.WakeUp;
  end;

  FIsBusy := false;
end;

procedure TglCanvas.Resize;
begin
  inherited;

  // OpenGL �ʱ�ȭ�� �ȵǾ��ų� ����̹��� ��ġ �Ǿ� ���� �ʴ�.
  if FVersionPtr = nil then begin
    Invalidate;
  end else begin
    FSimpleThread.WakeUp;
  end;
end;

procedure TglCanvas.SetPenColor(const Value: TColor);
begin
  FBitmapLayer.Canvas.Pen.Color := Value;
end;

procedure TglCanvas.SetStretch(const Value: boolean);
begin
  FStretch := Value;
end;

procedure TglCanvas.SetTransparentColor(const Value: TColor);
begin
  FBitmapLayer.TransparentColor := Value;
end;

procedure TglCanvas.SetUseGDI(const Value: boolean);
begin
  FUseGDI := Value;
end;

var
  dllHandle : Cardinal;

initialization
  dllHandle := LoadLibrary( 'opengl32.dll' );
  if dllHandle = 0 then Exit;

  @glGetString := GetProcAddress( dllHandle, 'glGetString' );
  @wglCreateContext := GetProcAddress( dllHandle, 'wglCreateContext' );
  @glClear := GetProcAddress( dllHandle, 'glClear' );
  @glDrawPixels := GetProcAddress( dllHandle, 'glDrawPixels' );
end.
