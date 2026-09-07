unit CyberReticle;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, ExtCtrls,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberReticle = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FTargetAngle: Single;
    FInnerAngle: Single;
    FAutoRotate: Boolean;
    FRotationSpeed: Single;
    FTimer: TTimer;

    procedure SetTargetAngle(AValue: Single);
    procedure SetAutoRotate(AValue: Boolean);
    procedure SetRotationSpeed(AValue: Single);
    procedure OnSpinTimer(Sender: TObject);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property TargetAngle: Single read FTargetAngle write SetTargetAngle default 0.0;
    property AutoRotate: Boolean read FAutoRotate write SetAutoRotate default True;
    property RotationSpeed: Single read FRotationSpeed write SetRotationSpeed default 2.5;
    property Align;
    property Anchors;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberReticle]);
end;

{ TCyberReticle }

constructor TCyberReticle.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  Width := 150;
  Height := 150;
  FTargetAngle := 0.0;
  FInnerAngle := 0.0;
  FAutoRotate := True;
  FRotationSpeed := 2.5;

  FBuffer := TBGRABitmap.Create(Width, Height);

  // Mesin penggerak rotasi cincin HUD internal
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 30; // Sekitar 33 FPS untuk pergerakan taktis yang mulus
  FTimer.OnTimer := @OnSpinTimer;
  FTimer.Enabled := FAutoRotate;
end;

destructor TCyberReticle.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberReticle.OnSpinTimer(Sender: TObject);
begin
  if not FAutoRotate then Exit;

  // Perbarui sudut putar cincin dalam berdasarkan Rule-Based speed
  FInnerAngle := FInnerAngle + FRotationSpeed;
  if FInnerAngle >= 360.0 then FInnerAngle := FInnerAngle - 360.0;
  if FInnerAngle < 0.0 then FInnerAngle := FInnerAngle + 360.0;

  Invalidate;
end;

procedure TCyberReticle.SetTargetAngle(AValue: Single);
begin
  if FTargetAngle = AValue then Exit;
  FTargetAngle := AValue;
  Invalidate;
end;

procedure TCyberReticle.SetAutoRotate(AValue: Boolean);
begin
  if FAutoRotate = AValue then Exit;
  FAutoRotate := AValue;
  FTimer.Enabled := FAutoRotate;
  Invalidate;
end;

procedure TCyberReticle.SetRotationSpeed(AValue: Single);
begin
  if FRotationSpeed = AValue then Exit;
  FRotationSpeed := AValue;
end;

procedure TCyberReticle.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberReticle.Paint;
var
  CX, CY, Rad, InnerRad, LegLen: Single;
  NeonColor, HighlightColor: TBGRAPixel;

  // HELPER ANTI-GAGAL: Rotasi Matriks 2D Murni
  function RotatePt(X, Y, AngleDeg: Single): TPointF;
  var
    RadAngle: Single;
  begin
    RadAngle := DegToRad(AngleDeg);
    Result.X := (X * Cos(RadAngle)) - (Y * Sin(RadAngle));
    Result.Y := (X * Sin(RadAngle)) + (Y * Cos(RadAngle));
  end;

  // HELPER ANTI-GAGAL: Menggambar Sudut Siku (Bracket)
  procedure DrawBracket(OffsetX, OffsetY, TargetRot: Single; Clr: TBGRAPixel; Thick: Single);
  var
    Corner, Leg1, Leg2: TPointF;
    P1, P2, P3: TPointF;
    SignX, SignY: Single;
  begin
    // Tentukan arah siku berdasarkan kuadran
    if OffsetX < 0 then SignX := 1 else SignX := -1;
    if OffsetY < 0 then SignY := 1 else SignY := -1;

    // Titik awal sebelum dirotasi (berpusat di 0,0)
    Corner := PointF(OffsetX, OffsetY);
    Leg1 := PointF(OffsetX + (LegLen * SignX), OffsetY);
    Leg2 := PointF(OffsetX, OffsetY + (LegLen * SignY));

    // Putar titik menggunakan matriks 2D, lalu geser (Translate) ke titik tengah Canvas (CX, CY)
    P1 := RotatePt(Corner.X, Corner.Y, TargetRot);
    P1.X := P1.X + CX; P1.Y := P1.Y + CY;

    P2 := RotatePt(Leg1.X, Leg1.Y, TargetRot);
    P2.X := P2.X + CX; P2.Y := P2.Y + CY;

    P3 := RotatePt(Leg2.X, Leg2.Y, TargetRot);
    P3.X := P3.X + CX; P3.Y := P3.Y + CY;

    // Gambar garis siku
    FBuffer.DrawLineAntialias(P2.X, P2.Y, P1.X, P1.Y, Clr, Thick);
    FBuffer.DrawLineAntialias(P1.X, P1.Y, P3.X, P3.Y, Clr, Thick);
  end;

  // HELPER ANTI-GAGAL: Cincin Putus-Putus (Dashed Ring)
  procedure DrawDashedRing(Radius, Segments, GapDeg, SpinAngle: Single; Clr: TBGRAPixel; Thick: Single);
  var
    i: Integer;
    StepAngle, A1, A2: Single;
    P1, P2: TPointF;
  begin
    StepAngle := 360 / Segments;
    for i := 0 to Round(Segments) - 1 do
    begin
      A1 := DegToRad(SpinAngle + (i * StepAngle));
      A2 := DegToRad(SpinAngle + (i * StepAngle) + (StepAngle - GapDeg));

      // Menggambar segmen lengkung pendek menggunakan garis lurus (Polygon tech style)
      P1 := PointF(CX + Radius * Cos(A1), CY + Radius * Sin(A1));
      P2 := PointF(CX + Radius * Cos(A2), CY + Radius * Sin(A2));
      FBuffer.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, Clr, Thick);
    end;
  end;

begin
  FBuffer.FillTransparent; // Reticle selalu transparan agar tidak menutupi peta

  CX := Width / 2;
  CY := Height / 2;
  Rad := Min(Width, Height) / 2 - 5;
  InnerRad := Rad * 0.65;
  LegLen := Rad * 0.35; // Panjang kaki siku [ ]

  NeonColor := CyberThemeData.PrimaryNeon;
  HighlightColor := CyberThemeData.TextHighlight;

  // 1. Gambar Sudut Pembidik Utama (Outer Brackets)
  // Top-Left, Top-Right, Bottom-Right, Bottom-Left
  DrawBracket(-Rad, -Rad, FTargetAngle, NeonColor, 3.0);
  DrawBracket(Rad, -Rad, FTargetAngle, NeonColor, 3.0);
  DrawBracket(Rad, Rad, FTargetAngle, NeonColor, 3.0);
  DrawBracket(-Rad, Rad, FTargetAngle, NeonColor, 3.0);

  // 2. Gambar Cincin Dalam Animasi (Dashed Ring 1 & 2 berputar berlawanan)
  DrawDashedRing(InnerRad, 12, 10, FInnerAngle, CyberThemeData.SecondaryNeon, 2.0);
  DrawDashedRing(InnerRad * 0.75, 8, 15, -FInnerAngle * 1.5, CyberThemeData.SecondaryNeon, 1.5);

  // 3. Gambar Crosshair (Garis Silang Pusat)
  FBuffer.DrawLineAntialias(CX - 15, CY, CX - 5, CY, HighlightColor, 1.5);
  FBuffer.DrawLineAntialias(CX + 5, CY, CX + 15, CY, HighlightColor, 1.5);
  FBuffer.DrawLineAntialias(CX, CY - 15, CX, CY - 5, HighlightColor, 1.5);
  FBuffer.DrawLineAntialias(CX, CY + 5, CX, CY + 15, HighlightColor, 1.5);

  // Titik Inti
  FBuffer.SetPixel(Round(CX), Round(CY), HighlightColor);
  FBuffer.SetPixel(Round(CX)+1, Round(CY), HighlightColor);
  FBuffer.SetPixel(Round(CX), Round(CY)+1, HighlightColor);
  FBuffer.SetPixel(Round(CX)+1, Round(CY)+1, HighlightColor);

  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
