unit CyberRadar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Math, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberRadar }

  TCyberRadar = class(TGraphicControl)
  private
    FBuffer: TBGRABitmap;
    FAnimTimer: TTimer;
    FCurrentAngle: Single;
    FSweepSpeed: Single;
    FActive: Boolean;

    // Titik-titik target palsu (X = Sudut, Y = Jarak dari pusat 0.0 - 1.0)
    FBlips: array[0..4] of TPointF;

    procedure SetActive(AValue: Boolean);
    procedure OnTimerTick(Sender: TObject);
    procedure GenerateBlips;
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Active: Boolean read FActive write SetActive default True;
    property SweepSpeed: Single read FSweepSpeed write FSweepSpeed; // Kecepatan rotasi

    property Align;
    property Anchors;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberRadar]);
end;

{ TCyberRadar }

constructor TCyberRadar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Width := 150;
  Height := 150;

  FSweepSpeed := 3.0; // Berputar 3 derajat setiap tick
  FCurrentAngle := 0;
  FActive := True;

  FBuffer := TBGRABitmap.Create(Width, Height);

  // Buat titik-titik target radar secara acak
  GenerateBlips;

  // Setup Timer (Kecepatan ~30fps)
  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Interval := 33;
  FAnimTimer.OnTimer := @OnTimerTick;

  if not (csDesigning in ComponentState) then
    FAnimTimer.Enabled := FActive;
end;

destructor TCyberRadar.Destroy;
begin
  FAnimTimer.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberRadar.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  FActive := AValue;
  if not (csDesigning in ComponentState) then
    FAnimTimer.Enabled := FActive;
  Invalidate;
end;

procedure TCyberRadar.GenerateBlips;
var
  i: Integer;
begin
  Randomize;
  for i := 0 to High(FBlips) do
  begin
    // Sudut acak 0-360
    FBlips[i].X := Random(360);
    // Jarak acak dari pusat (20% hingga 90% dari jari-jari)
    FBlips[i].Y := 0.2 + (Random * 0.7);
  end;
end;

procedure TCyberRadar.OnTimerTick(Sender: TObject);
begin
  FCurrentAngle := FCurrentAngle + FSweepSpeed;
  if FCurrentAngle >= 360 then
    FCurrentAngle := FCurrentAngle - 360;

  Invalidate;
end;

procedure TCyberRadar.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberRadar.Paint;
const
  SweepLength = 70; // Berapa derajat panjang "ekor" sapuan radar
var
  CX, CY, Radius, MaxRadius: Single;
  i: Integer;
  RadAngle: Single;
  PX, PY: Single;
  BlipAngle, BlipDist, AngleDiff: Single;
  BX, BY: Single;
  BlipAlpha: Integer;
  NeonColor, DrawColor, BlipColor: TBGRAPixel;

  // PERBAIKAN ERROR: Fungsi Helper Lokal untuk Menggambar Lingkaran
  procedure DrawCustomCircle(Center_X, Center_Y, Rad: Single; Clr: TBGRAPixel; LineThick: Single);
  var
    j: Integer;
    CircPts: array[0..36] of TPointF;
  begin
    // Menghasilkan 36 titik koordinat (setiap 10 derajat) membentuk poligon melingkar
    for j := 0 to 36 do
    begin
      CircPts[j] := PointF(Center_X + (Rad * Cos(DegToRad(j * 10))),
                           Center_Y + (Rad * Sin(DegToRad(j * 10))));
    end;
    // Gambar garis penghubung antar titik (True = poligon tertutup)
    FBuffer.DrawPolyLineAntialias(CircPts, Clr, LineThick, True);
  end;

begin
  // 1. Bersihkan Latar Belakang
  FBuffer.Fill(CyberThemeData.BgDark);

  CX := Width / 2;
  CY := Height / 2;
  MaxRadius := Min(Width, Height) / 2;
  Radius := MaxRadius - 5; // Beri sedikit margin luar

  NeonColor := CyberThemeData.PrimaryNeon;

  // 2. Gambar Grid Statis (Lingkaran & Garis Silang)
  // Lingkaran luar menggunakan helper custom
  DrawCustomCircle(CX, CY, Radius, CyberThemeData.SecondaryNeon, 2.0);

  // Lingkaran dalam (2 ring tambahan)
  DrawCustomCircle(CX, CY, Radius * 0.66, CyberThemeData.BgLighter, 1.0);
  DrawCustomCircle(CX, CY, Radius * 0.33, CyberThemeData.BgLighter, 1.0);

  // Garis silang (Crosshairs)
  FBuffer.DrawLineAntialias(CX, CY - Radius, CX, CY + Radius, CyberThemeData.BgLighter, 1.0);
  FBuffer.DrawLineAntialias(CX - Radius, CY, CX + Radius, CY, CyberThemeData.BgLighter, 1.0);

  // 3. Gambar Ekor Sapuan Radar (Sweep Tail)
  for i := 0 to SweepLength do
  begin
    RadAngle := DegToRad(FCurrentAngle - i);
    PX := CX + (Radius * Cos(RadAngle));
    PY := CY + (Radius * Sin(RadAngle));

    DrawColor := NeonColor;
    DrawColor.alpha := Round(150 * (1 - (i / SweepLength)));
    FBuffer.DrawLineAntialias(CX, CY, PX, PY, DrawColor, 2.5);
  end;

  // 4. Gambar Garis Depan Radar (Leading Edge / Scanner Line)
  RadAngle := DegToRad(FCurrentAngle);
  PX := CX + (Radius * Cos(RadAngle));
  PY := CY + (Radius * Sin(RadAngle));
  FBuffer.DrawLineAntialias(CX, CY, PX, PY, CyberThemeData.TextHighlight, 2.0);

  // 5. Render Target/Blips
  for i := 0 to High(FBlips) do
  begin
    BlipAngle := FBlips[i].X;
    BlipDist := FBlips[i].Y * Radius;

    BX := CX + (BlipDist * Cos(DegToRad(BlipAngle)));
    BY := CY + (BlipDist * Sin(DegToRad(BlipAngle)));

    AngleDiff := FCurrentAngle - BlipAngle;

    while AngleDiff < 0 do AngleDiff := AngleDiff + 360;
    while AngleDiff >= 360 do AngleDiff := AngleDiff - 360;

    if AngleDiff < 120 then
    begin
      BlipAlpha := Round(255 * (1 - (AngleDiff / 120)));
      if BlipAlpha > 0 then
      begin
        BlipColor := CyberThemeData.TextHighlight;
        BlipColor.alpha := BlipAlpha;

        FBuffer.FillRect(Round(BX - 2), Round(BY - 2), Round(BX + 2), Round(BY + 2), BlipColor, dmSet);

        // Gambar cincin pinggir (Ping effect) menggunakan helper custom
        BlipColor := CyberThemeData.PrimaryNeon;
        BlipColor.alpha := BlipAlpha;
        DrawCustomCircle(BX, BY, 5, BlipColor, 1.0);
      end;
    end;
  end;

  // 6. Proyeksikan ke Canvas
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
