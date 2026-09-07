unit CyberLED;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls,
  BGRABitmap, BGRABitmapTypes, CyberTheme,Math;

type
  TCyberLEDShape = (clsRound, clsSquare);
  TCyberLEDThemeColor = (clcPrimary, clcSecondary, clcAlert);

  { TCyberLED }

  TCyberLED = class(TGraphicControl)
  private
    FBuffer: TBGRABitmap;
    FIsOn: Boolean;
    FShape: TCyberLEDShape;
    FThemeColor: TCyberLEDThemeColor;

    // Fitur Kedip (Blinking)
    FBlink: Boolean;
    FBlinkInterval: Integer;
    FBlinkTimer: TTimer;
    FBlinkState: Boolean; // Status nyala/mati saat mode blink aktif

    procedure SetIsOn(AValue: Boolean);
    procedure SetShape(AValue: TCyberLEDShape);
    procedure SetThemeColor(AValue: TCyberLEDThemeColor);
    procedure SetBlink(AValue: Boolean);
    procedure SetBlinkInterval(AValue: Integer);
    procedure OnBlinkTimerTick(Sender: TObject);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property IsOn: Boolean read FIsOn write SetIsOn default False;
    property Shape: TCyberLEDShape read FShape write SetShape default clsRound;
    property ThemeColor: TCyberLEDThemeColor read FThemeColor write SetThemeColor default clcPrimary;

    property Blink: Boolean read FBlink write SetBlink default False;
    property BlinkInterval: Integer read FBlinkInterval write SetBlinkInterval default 500;

    property Align;
    property Anchors;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberLED]);
end;

{ TCyberLED }

constructor TCyberLED.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 20;
  Height := 20;

  FIsOn := False;
  FShape := clsRound;
  FThemeColor := clcPrimary;

  FBlink := False;
  FBlinkInterval := 500;
  FBlinkState := False;

  FBuffer := TBGRABitmap.Create(Width, Height);

  // Timer untuk efek berkedip
  FBlinkTimer := TTimer.Create(Self);
  FBlinkTimer.Enabled := False;
  FBlinkTimer.Interval := FBlinkInterval;
  FBlinkTimer.OnTimer := @OnBlinkTimerTick;
end;

destructor TCyberLED.Destroy;
begin
  FBlinkTimer.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberLED.SetIsOn(AValue: Boolean);
begin
  if FIsOn = AValue then Exit;
  FIsOn := AValue;
  // Jika dimatikan/dinyalakan manual, sinkronkan state kedip agar langsung merespon
  FBlinkState := FIsOn;
  Invalidate;
end;

procedure TCyberLED.SetShape(AValue: TCyberLEDShape);
begin
  if FShape = AValue then Exit;
  FShape := AValue;
  Invalidate;
end;

procedure TCyberLED.SetThemeColor(AValue: TCyberLEDThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TCyberLED.SetBlink(AValue: Boolean);
begin
  if FBlink = AValue then Exit;
  FBlink := AValue;

  if csDesigning in ComponentState then Exit; // Jangan berkedip di mode desain IDE

  FBlinkTimer.Enabled := FBlink;
  if not FBlink then
  begin
    // Kembalikan ke state asli saat blink dimatikan
    FBlinkState := FIsOn;
    Invalidate;
  end;
end;

procedure TCyberLED.SetBlinkInterval(AValue: Integer);
begin
  if FBlinkInterval = AValue then Exit;
  FBlinkInterval := AValue;
  FBlinkTimer.Interval := FBlinkInterval;
end;

procedure TCyberLED.OnBlinkTimerTick(Sender: TObject);
begin
  FBlinkState := not FBlinkState;
  Invalidate;
end;

procedure TCyberLED.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberLED.Paint;
var
  CX, CY, Radius: Single;
  Padding, RectSize: Integer;
  BaseColor, DrawColor, GlowColor: TBGRAPixel;
  CurrentStateOn: Boolean;

  // PERBAIKAN 1: Helper untuk menggambar Elips/Lingkaran
  procedure DrawCustomCircle(Center_X, Center_Y, Rad: Single; Clr: TBGRAPixel; LineThick: Single);
  var
    j: Integer;
    CircPts: array[0..36] of TPointF;
  begin
    for j := 0 to 36 do
    begin
      CircPts[j] := PointF(Center_X + (Rad * Cos(DegToRad(j * 10))),
                           Center_Y + (Rad * Sin(DegToRad(j * 10))));
    end;
    FBuffer.DrawPolyLineAntialias(CircPts, Clr, LineThick, True);
  end;

  // PERBAIKAN 2: Helper untuk menggambar Kotak bersudut tajam
  procedure DrawCustomRect(Left, Top, Right, Bottom: Single; Clr: TBGRAPixel; LineThick: Single);
  var
    RectPts: array[0..3] of TPointF;
  begin
    RectPts[0] := PointF(Left, Top);
    RectPts[1] := PointF(Right, Top);
    RectPts[2] := PointF(Right, Bottom);
    RectPts[3] := PointF(Left, Bottom);
    FBuffer.DrawPolyLineAntialias(RectPts, Clr, LineThick, True);
  end;

begin
  // 1. Bersihkan Latar Belakang secara Transparan
  FBuffer.FillTransparent;

  if FBlink then
    CurrentStateOn := FBlinkState
  else
    CurrentStateOn := FIsOn;

  // 2. Ambil warna berdasarkan properti ThemeColor
  case FThemeColor of
    clcPrimary: BaseColor := CyberThemeData.PrimaryNeon;
    clcSecondary: BaseColor := CyberThemeData.SecondaryNeon;
    clcAlert: BaseColor := CyberThemeData.AlertNeon;
  end;

  Padding := 3;

  if FShape = clsRound then
  begin
    // --- RENDER BENTUK BULAT ---
    CX := Width / 2;
    CY := Height / 2;
    if Width < Height then Radius := (Width / 2) - Padding
    else Radius := (Height / 2) - Padding;

    if CurrentStateOn then
    begin
      DrawColor := BaseColor;
      GlowColor := BaseColor;

      GlowColor.alpha := 80;
      // Gunakan helper lingkaran
      DrawCustomCircle(CX, CY, Radius + 1, GlowColor, 4.0);

      GlowColor.alpha := 150;
      FBuffer.FillEllipseAntialias(CX, CY, Radius, Radius, GlowColor);

      DrawColor.alpha := 255;
      FBuffer.FillEllipseAntialias(CX, CY, Radius - 1, Radius - 1, DrawColor);

      FBuffer.FillEllipseAntialias(CX - (Radius * 0.3), CY - (Radius * 0.3),
                                   Radius * 0.25, Radius * 0.25,
                                   BGRA(255,255,255,200));
    end
    else
    begin
      DrawColor := CyberThemeData.BgLighter;
      FBuffer.FillEllipseAntialias(CX, CY, Radius, Radius, DrawColor);

      BaseColor.alpha := 40;
      // Gunakan helper lingkaran
      DrawCustomCircle(CX, CY, Radius, BaseColor, 1.0);
    end;
  end
  else
  begin
    // --- RENDER BENTUK KOTAK ---
    RectSize := Width;
    if Height < Width then RectSize := Height;
    RectSize := RectSize - (Padding * 2);

    if CurrentStateOn then
    begin
      DrawColor := BaseColor;
      GlowColor := BaseColor;

      GlowColor.alpha := 80;
      // Gunakan helper kotak
      DrawCustomRect(Padding, Padding, Padding + RectSize, Padding + RectSize, GlowColor, 4.0);

      GlowColor.alpha := 150;
      FBuffer.FillRect(Padding, Padding, Padding + RectSize, Padding + RectSize, GlowColor, dmSet);

      DrawColor.alpha := 255;
      FBuffer.FillRect(Padding + 1, Padding + 1, Padding + RectSize - 1, Padding + RectSize - 1, DrawColor, dmSet);

      FBuffer.FillRect(Padding + 2, Padding + 2, Padding + 4, Padding + 4, BGRA(255,255,255,200), dmSet);
    end
    else
    begin
      DrawColor := CyberThemeData.BgLighter;
      FBuffer.FillRect(Padding, Padding, Padding + RectSize, Padding + RectSize, DrawColor, dmSet);

      BaseColor.alpha := 40;
      // Gunakan helper kotak
      DrawCustomRect(Padding, Padding, Padding + RectSize, Padding + RectSize, BaseColor, 1.0);
    end;
  end;

  // Proyeksikan ke layar
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
