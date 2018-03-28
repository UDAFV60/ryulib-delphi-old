unit RyuLib.WhiteBoard;

interface

uses
  RyuGraphics, MouseEventControl,
  Windows, Messages, SysUtils, Classes, Graphics, Controls;

type
  TDrawType = ( dtClear, dtEraser, dtFreeDraw, dtLine, dtRectangle, dtEllipse );

  TDrawingFunction = procedure (AX,AY:Integer) of object;

  TWhiteBoard = class (TCustomControl)
  private
    /// ��׶���(����) �̹���
    FBitmap: TBitmap;

    /// ����� ����
    FBitmapTemp : TBitmap;

    /// ȭ�鿡 ǥ��
    FBitmapDisplay: TBitmap;

    // ���� ȭ�� ��ü�� ���� Bitmap (FBitmap + FBitmapTemp + FBitmapDisplay)
    FInternalBitmap : TBitmap;

    FPolyLines : array of TPoint;
  private
    FMouseDown : TPoint;
    FMouseUp : TPoint;
    FIsDrawing : boolean;
    FMouseEventControl : TMouseEventControl;
    procedure on_MouseDown(Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:Integer);
    procedure on_MouseMove(Sender:TObject; Shift:TShiftState; X,Y:Integer);
    procedure on_MouseUp(Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:Integer);
  private
    do_BeginDrawing : TDrawingFunction;
    do_Drawing : TDrawingFunction;
    do_EndDrawing : TDrawingFunction;

    procedure do_Clear_BitmapTemp;

    procedure do_Eraser_BeginDrawing(AX,AY:Integer);
    procedure do_Eraser_Drawing(AX,AY:Integer);
    procedure do_Eraser_EndDrawing(AX,AY:Integer);

    procedure do_FreeDraw_BeginDrawing(AX,AY:Integer);
    procedure do_FreeDraw_Drawing(AX,AY:Integer);
    procedure do_FreeDraw_EndDrawing(AX,AY:Integer);

    procedure do_Line_BeginDrawing(AX,AY:Integer);
    procedure do_Line_Drawing(AX,AY:Integer);
    procedure do_Line_EndDrawing(AX,AY:Integer);

    procedure do_Rectangle_BeginDrawing(AX,AY:Integer);
    procedure do_Rectangle_Drawing(AX,AY:Integer);
    procedure do_Rectangle_EndDrawing(AX,AY:Integer);

    procedure do_Ellipse_BeginDrawing(AX,AY:Integer);
    procedure do_Ellipse_Drawing(AX,AY:Integer);
    procedure do_Ellipse_EndDrawing(AX,AY:Integer);
  protected
    procedure Paint; override;
  private
    FDrawType : TDrawType;
    FEraserSize: integer;
    FOnPaint: TNotifyEvent;
    procedure SetTDrawType(const Value: TDrawType);
    function GetPen: TPen;
    function GetFont: TFont;
    procedure SetBitmap(const Value:TBitmap);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;

    procedure Prepare; overload;
    procedure Prepare( AWidth,AHeight:integer); overload;

    procedure LoadFromFile(AFileName:string);
  published
    property Align;
    property Anchors;
    property Enabled;
    property ShowHint;
    property Visible;
    property Canvas;
    property OnClick;
    property OnMouseEnter;
    property OnMouseLeave;

    property Font : TFont read GetFont;
    property Pen : TPen read GetPen;
    property DrawType : TDrawType read FDrawType write SetTDrawType;
    property EraserSize : integer read FEraserSize write FEraserSize;

    property Bitmap : TBitmap read FBitmap write SetBitmap;
    property InternalBitmap : TBitmap read FInternalBitmap;

    property OnPaint : TNotifyEvent read FOnPaint write FOnPaint;
  end;

implementation

{ TWhiteBoard }

procedure TWhiteBoard.Clear;
begin
  FIsDrawing := false;

  do_Clear_BitmapTemp;

  FBitmapDisplay.Assign(FBitmap);

  Invalidate;
end;

constructor TWhiteBoard.Create(AOwner: TComponent);
begin
  inherited;

  DoubleBuffered := true;
  ControlStyle := ControlStyle + [csOpaque];

  FIsDrawing := false;
  FEraserSize := 32;

  SetTDrawType( dtFreeDraw );

  FBitmap := TBitmap.Create;
  FBitmap.PixelFormat := pf32bit;

  FBitmapDisplay := TBitmap.Create;
  FBitmapDisplay.PixelFormat := pf32bit;

  FBitmapTemp := TBitmap.Create;
  FBitmapTemp.PixelFormat := pf32bit;
  FBitmapTemp.TransparentColor := clWhite;
  FBitmapTemp.Transparent := true;

  FInternalBitmap := TBitmap.Create;
  FInternalBitmap.PixelFormat := pf32bit;

  FMouseEventControl := TMouseEventControl.Create(Self);
  FMouseEventControl.TargetControl := Self;
  FMouseEventControl.OnMouseDown := on_MouseDown;
  FMouseEventControl.OnMouseMove := on_MouseMove;
  FMouseEventControl.OnMouseUp   := on_MouseUp;
end;

destructor TWhiteBoard.Destroy;
begin
  FreeAndNil(FMouseEventControl);
  FreeAndNil(FBitmapDisplay);
  FreeAndNil(FBitmapTemp);
  FreeAndNil(FBitmap);

  inherited;
end;

procedure TWhiteBoard.do_Clear_BitmapTemp;
begin
  FBitmapTemp.Canvas.Brush.Style := bsSolid;
  FBitmapTemp.Canvas.Brush.Color := clWhite;
  FBitmapTemp.Canvas.FillRect( Rect(0, 0, FBitmapTemp.Width, FBitmapTemp.Height) );

  FBitmapTemp.Canvas.Pen.Assign( FBitmapDisplay.Canvas.Pen );
end;

procedure TWhiteBoard.do_Ellipse_BeginDrawing(AX, AY: Integer);
begin
  do_Clear_BitmapTemp;
end;

procedure TWhiteBoard.do_Ellipse_Drawing(AX, AY: Integer);
begin
  do_Clear_BitmapTemp;

  FBitmapTemp.Canvas.Ellipse( FMouseDown.X, FMouseDown.Y, AX, AY );
end;

procedure TWhiteBoard.do_Ellipse_EndDrawing(AX, AY: Integer);
begin
end;

procedure TWhiteBoard.do_Eraser_BeginDrawing(AX, AY: Integer);
begin
  do_Clear_BitmapTemp;
end;

procedure TWhiteBoard.do_Eraser_Drawing(AX, AY: Integer);
var
  pSrc, pDst : ^DWord;
  iX, iY : integer;
begin
  for iY := AY to AY+FEraserSize-1 do begin
    pSrc := FBitmap.ScanLine[iY];
    Inc(pSrc, AX);

    pDst := FBitmapDisplay.ScanLine[iY];
    Inc(pDst, AX);

    for iX := AX to AX+FEraserSize-1 do begin
      pDst^ := pSrc^;

      Inc(pSrc);
      Inc(pDst);
    end;
  end;

  Invalidate;
end;

procedure TWhiteBoard.do_Eraser_EndDrawing(AX, AY: Integer);
begin
  //
end;

procedure TWhiteBoard.do_FreeDraw_BeginDrawing(AX, AY: Integer);
begin
  do_Clear_BitmapTemp;

  SetLength( FPolyLines, 1 );
  FPolyLines[0] := Point( AX, AY );

  FBitmapTemp.Canvas.MoveTo( AX, AY );
end;

procedure TWhiteBoard.do_FreeDraw_Drawing(AX, AY: Integer);
begin
  SetLength( FPolyLines, Length(FPolyLines)+1 );
  FPolyLines[Length(FPolyLines)-1] := Point( AX, AY );

  FBitmapTemp.Canvas.LineTo( AX, AY );
end;

procedure TWhiteBoard.do_FreeDraw_EndDrawing(AX, AY: Integer);
var
  isBezierDone : boolean;
begin
  do_Clear_BitmapTemp;

  FBitmapTemp.Canvas.Lock;
  try
    isBezierDone := PolyBezier(FBitmapTemp.Canvas.Handle, FPolyLines[0], High(FPolyLines) + 1);
  finally
    FBitmapTemp.Canvas.Unlock;
  end;

  if not isBezierDone then FBitmapTemp.Canvas.Polyline( FPolyLines );
end;

procedure TWhiteBoard.do_Line_BeginDrawing(AX, AY: Integer);
begin
  do_Clear_BitmapTemp;
end;

procedure TWhiteBoard.do_Line_Drawing(AX, AY: Integer);
begin
  do_Clear_BitmapTemp;

  FBitmapTemp.Canvas.MoveTo( FMouseDown.X, FMouseDown.Y );
  FBitmapTemp.Canvas.LineTo( AX, AY );
end;

procedure TWhiteBoard.do_Line_EndDrawing(AX, AY: Integer);
begin
end;

procedure TWhiteBoard.do_Rectangle_BeginDrawing(AX, AY: Integer);
begin
  do_Clear_BitmapTemp;
end;

procedure TWhiteBoard.do_Rectangle_Drawing(AX, AY: Integer);
begin
  do_Clear_BitmapTemp;

  FBitmapTemp.Canvas.Rectangle( FMouseDown.X, FMouseDown.Y, AX, AY );
end;

procedure TWhiteBoard.do_Rectangle_EndDrawing(AX, AY: Integer);
begin
end;

function TWhiteBoard.GetFont: TFont;
begin
  Result := FBitmapDisplay.Canvas.Font;
end;

function TWhiteBoard.GetPen: TPen;
begin
  Result := FBitmapDisplay.Canvas.Pen;
end;

procedure TWhiteBoard.LoadFromFile(AFileName: string);
var
  bmpFile, bmpResize : TBitmap;
  ptSrc, ptDst, ptResult : TPoint;
begin
  FBitmap.Width  := Width;
  FBitmap.Height := Height;

  FBitmap.Canvas.Brush.Style := bsSolid;
  FBitmap.Canvas.Brush.Color := clWhite;
  FBitmap.Canvas.FillRect( Rect(0, 0, FBitmap.Width, FBitmap.Height) );

  Clear;

  bmpFile := TBitmap.Create;
  try
    ImageFileToBitmap( AFileName, bmpFile );

    bmpFile.PixelFormat := pf32bit;

    if (bmpFile.Width <= Width) and (bmpFile.Height <= Height) then begin
      FBitmap.Canvas.Draw(
        (FBitmap.Width  div 2) - (bmpFile.Width  div 2),
        (FBitmap.Height div 2) - (bmpFile.Height div 2),
        bmpFile
      );

    end else begin
      bmpResize := TBitmap.Create;
      try
        bmpResize.PixelFormat := pf32bit;

        ptSrc := Point( bmpFile.Width, bmpFile.Height );
        ptDst := Point( FBitmap.Width, FBitmap.Height );

        ptResult := RatioSize(ptSrc, ptDst);

        bmpResize.Width  := ptResult.X;
        bmpResize.Height := ptResult.Y;

        SmoothResize(bmpFile, bmpResize);

        FBitmap.Canvas.Draw(
          (FBitmap.Width  div 2) - (bmpResize.Width  div 2),
          (FBitmap.Height div 2) - (bmpResize.Height div 2),
          bmpResize
        );
      finally
        bmpResize.Free;
      end;
    end;
  finally
    bmpFile.Free;
  end;

  Prepare;
end;

procedure TWhiteBoard.on_MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (ssLeft in Shift) or (ssPen in Shift) then begin
    FIsDrawing := true;
    FMouseDown := Point( X, Y );

    FBitmapTemp.PixelFormat := FBitmapDisplay.PixelFormat;
    FBitmapTemp.Width := FBitmapDisplay.Width;
    FBitmapTemp.Height := FBitmapDisplay.Height;

    do_BeginDrawing( X, Y );
  end;
end;

procedure TWhiteBoard.on_MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if FIsDrawing then begin
    do_Drawing( X, Y );

    Invalidate;
  end;
end;

procedure TWhiteBoard.on_MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FIsDrawing then begin
    FMouseUp := Point( X, Y );

    do_EndDrawing( X, Y );

    FIsDrawing := false;

    FBitmapDisplay.Canvas.Draw( 0, 0, FBitmapTemp );

    Invalidate;
  end;
end;

procedure TWhiteBoard.Paint;
begin
  inherited;

  FInternalBitmap.Width  := Width;
  FInternalBitmap.Height := Height;

  FInternalBitmap.Canvas.Draw(0, 0, FBitmapDisplay);
  if FIsDrawing then FInternalBitmap.Canvas.Draw(0, 0, FBitmapTemp);

  Canvas.Draw(0, 0, FInternalBitmap);

  if Assigned(FOnPaint) then FOnPaint(Self);
end;

procedure TWhiteBoard.Prepare;
begin
  FBitmap.PixelFormat := pf32bit;

  Clear;
end;

procedure TWhiteBoard.Prepare(AWidth, AHeight: integer);
begin
  FBitmap.PixelFormat := pf32bit;
  FBitmap.Width  := AWidth;
  FBitmap.Height := AHeight;
  FBitmap.Canvas.Brush.Style := bsSolid;
  FBitmap.Canvas.Brush.Color := clWhite;
  FBitmap.Canvas.FillRect( Rect(0, 0, FBitmap.Width, FBitmap.Height) );

  Clear;
end;

procedure TWhiteBoard.SetBitmap(const Value: TBitmap);
begin
  FBitmap.Assign( Value );
  FBitmap.PixelFormat := pf32bit;

  FBitmapDisplay.Assign( FBitmap );

  Invalidate;
end;

procedure TWhiteBoard.SetTDrawType(const Value: TDrawType);
begin
  FDrawType := Value;

  case Value of
    dtEraser: begin
      do_BeginDrawing := do_Eraser_BeginDrawing;
      do_Drawing      := do_Eraser_Drawing;
      do_EndDrawing   := do_Eraser_EndDrawing;
    end;

    dtFreeDraw: begin
      do_BeginDrawing := do_FreeDraw_BeginDrawing;
      do_Drawing      := do_FreeDraw_Drawing;
      do_EndDrawing   := do_FreeDraw_EndDrawing;
    end;

    dtLine: begin
      do_BeginDrawing := do_Line_BeginDrawing;
      do_Drawing      := do_Line_Drawing;
      do_EndDrawing   := do_Line_EndDrawing;
    end;

    dtRectangle: begin
      do_BeginDrawing := do_Rectangle_BeginDrawing;
      do_Drawing      := do_Rectangle_Drawing;
      do_EndDrawing   := do_Rectangle_EndDrawing;
    end;

    dtEllipse: begin
      do_BeginDrawing := do_Ellipse_BeginDrawing;
      do_Drawing      := do_Ellipse_Drawing;
      do_EndDrawing   := do_Ellipse_EndDrawing;
    end;
  end;
end;

end.
