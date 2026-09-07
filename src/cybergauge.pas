unit CyberGauge;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme ;

type
  { TCyberGauge }

  TCyberGauge = class(TGraphicControl)
  private
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FSuffix: string;
    FBuffer: TBGRABitmap;

    procedure SetMin(AValue: Integer);
    procedure SetMax(AValue: Integer);
    procedure SetPosition(AValue: Integer);
    procedure SetSuffix(AValue: string);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Position: Integer read FPosition write SetPosition default 75;
    property Suffix: string read FSuffix write SetSuffix; // Teks tambahan, misal: "%" atau " HP"

    property Align;
    property Anchors;
    property Font;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberGauge]);
end;

{ TCyberGauge }

constructor TCyberGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // GraphicControl tidak punya DoubleBuffered secara langsung,
  // tapi Buffer BGRABitmap kita sudah berfungsi sebagai double buffer manual.

  Width := 150;
  Height := 150;

  FMin := 0;
  FMax := 100;
  FPosition := 75;
  FSuffix := '%';

  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 16;
  Font.Style := [fsBold];
end;

destructor TCyberGauge.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberGauge.SetMin(AValue: Integer);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FMin > FMax then FMax := FMin;
  Invalidate;
end;

procedure TCyberGauge.SetMax(AValue: Integer);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FMax < FMin then FMin := FMax;
  Invalidate;
end;

procedure TCyberGauge.SetPosition(AValue: Integer);
begin
  if AValue < FMin then AValue := FMin;
  if AValue > FMax then AValue := FMax;
  if FPosition = AValue then Exit;

  FPosition := AValue;
  Invalidate;
end;

procedure TCyberGauge.SetSuffix(AValue: string);
begin
  if FSuffix = AValue then Exit;
  FSuffix := AValue;
  Invalidate;
end;

procedure TCyberGauge.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberGauge.Paint;
const
  StartAngle = 135;  // Sudut mulai (kiri bawah)
  SweepAngle = 270;  // Total putaran (menyisakan celah di bagian bawah)
  NumSegments = 40;  // Jumlah blok LED
var
  CX, CY: Single;
  InnerRadius, OuterRadius: Single;
  i, ActiveSegments: Integer;
  CurrentAngleDeg: Single;
  AngleRad: Single;
  X1, Y1, X2, Y2: Single;
  NeonColor, SegColor: TBGRAPixel;
  DisplayText: string;

  // TAMBAHAN VARIABEL UNTUK PERBAIKAN
  GlowColor: TBGRAPixel;
  TextY: Integer;
begin
  // 1. Bersihkan Latar Belakang
  FBuffer.Fill(CyberThemeData.BgDark);

  // 2. Hitung Pusat dan Jari-jari
  CX := Width / 2;
  CY := Height / 2;

  // PERBAIKAN ERROR: Hitung manual nilai terkecil agar tidak bentrok dengan properti "Min"
  if Width < Height then
    OuterRadius := (Width / 2) - 10
  else
    OuterRadius := (Height / 2) - 10;

  InnerRadius := OuterRadius - 15; // Ketebalan bar adalah 15 pixel

  NeonColor := CyberThemeData.PrimaryNeon;

  // Hitung manual blending warna (GlowColor)
  GlowColor.red := (CyberThemeData.BgDark.red * (255 - 80) + NeonColor.red * 80) div 255;
  GlowColor.green := (CyberThemeData.BgDark.green * (255 - 80) + NeonColor.green * 80) div 255;
  GlowColor.blue := (CyberThemeData.BgDark.blue * (255 - 80) + NeonColor.blue * 80) div 255;
  GlowColor.alpha := 255;

  // Hitung berapa banyak blok LED yang harus menyala
  if (FMax - FMin) = 0 then
    ActiveSegments := 0
  else
    ActiveSegments := Round(((FPosition - FMin) / (FMax - FMin)) * NumSegments);

  // 3. Render Segmen LED melingkar menggunakan Trigonometri
  for i := 0 to NumSegments do
  begin
    CurrentAngleDeg := StartAngle + (i * (SweepAngle / NumSegments));
    AngleRad := DegToRad(CurrentAngleDeg);

    X1 := CX + (InnerRadius * Cos(AngleRad));
    Y1 := CY + (InnerRadius * Sin(AngleRad));
    X2 := CX + (OuterRadius * Cos(AngleRad));
    Y2 := CY + (OuterRadius * Sin(AngleRad));

    if i <= ActiveSegments then
    begin
      SegColor := NeonColor;

      // Gunakan GlowColor manual
      FBuffer.DrawLineAntialias(X1, Y1, X2, Y2, GlowColor, 8.0);
    end
    else
    begin
      SegColor := CyberThemeData.BgLighter;
    end;

    // Gambar inti LED (Garis tajam)
    FBuffer.DrawLineAntialias(X1, Y1, X2, Y2, SegColor, 3.0);
  end;

  // 4. Render Garis Pembatas (Aksen Kosmetik di pangkal dan ujung Gauge)
  AngleRad := DegToRad(StartAngle - 2);
  X1 := CX + ((InnerRadius - 5) * Cos(AngleRad));
  Y1 := CY + ((InnerRadius - 5) * Sin(AngleRad));
  X2 := CX + ((OuterRadius + 5) * Cos(AngleRad));
  Y2 := CY + ((OuterRadius + 5) * Sin(AngleRad));
  FBuffer.DrawLineAntialias(X1, Y1, X2, Y2, CyberThemeData.SecondaryNeon, 2.0);

  AngleRad := DegToRad(StartAngle + SweepAngle + 2);
  X1 := CX + ((InnerRadius - 5) * Cos(AngleRad));
  Y1 := CY + ((InnerRadius - 5) * Sin(AngleRad));
  X2 := CX + ((OuterRadius + 5) * Cos(AngleRad));
  Y2 := CY + ((OuterRadius + 5) * Sin(AngleRad));
  FBuffer.DrawLineAntialias(X1, Y1, X2, Y2, CyberThemeData.BgLighter, 2.0);

  // 5. Render Teks Nilai di Tengah Lingkaran
  DisplayText := IntToStr(FPosition) + FSuffix;
  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  // Hitung posisi Y manual tanpa tlCenter
  TextY := Round(CY) - (FBuffer.TextSize(DisplayText).cy div 2);

  // Gambar teks dengan 5 argumen saja
  FBuffer.TextOut(Round(CX), TextY, DisplayText, CyberThemeData.TextHighlight, taCenter);

  // 6. Proyeksikan ke layar
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
