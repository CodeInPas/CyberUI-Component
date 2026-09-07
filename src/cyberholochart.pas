unit CyberHoloChart;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberHoloChart }

  TCyberHoloChart = class(TCustomControl)
  private
    FData: array of Single;
    FMaxPoints: Integer;
    FAutoRange: Boolean;
    FFixedMin: Single;
    FFixedMax: Single;
    FBuffer: TBGRABitmap;

    procedure SetMaxPoints(AValue: Integer);
    procedure SetAutoRange(AValue: Boolean);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Method untuk memasukkan data baru secara real-time
    procedure AddPoint(AValue: Single);
    procedure ClearData;
  published
    property MaxPoints: Integer read FMaxPoints write SetMaxPoints default 50;
    property AutoRange: Boolean read FAutoRange write SetAutoRange default True;
    property FixedMin: Single read FFixedMin write FFixedMin;
    property FixedMax: Single read FFixedMax write FFixedMax;

    property Align;
    property Anchors;
    property Color; // Hanya sebagai fallback jika bg transparan
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberHoloChart]);
end;

{ TCyberHoloChart }

constructor TCyberHoloChart.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  Width := 300;
  Height := 150;

  FMaxPoints := 50;
  FAutoRange := True;
  FFixedMin := 0;
  FFixedMax := 100;

  FBuffer := TBGRABitmap.Create(Width, Height);
  ClearData;
end;

destructor TCyberHoloChart.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberHoloChart.SetMaxPoints(AValue: Integer);
begin
  if FMaxPoints = AValue then Exit;
  FMaxPoints := AValue;
  if FMaxPoints < 2 then FMaxPoints := 2;
  ClearData; // Reset data jika batas maksimum diubah
end;

procedure TCyberHoloChart.SetAutoRange(AValue: Boolean);
begin
  if FAutoRange = AValue then Exit;
  FAutoRange := AValue;
  Invalidate;
end;

procedure TCyberHoloChart.ClearData;
begin
  SetLength(FData, 0);
  Invalidate;
end;

procedure TCyberHoloChart.AddPoint(AValue: Single);
var
  L, i: Integer;
begin
  L := Length(FData);
  if L < FMaxPoints then
  begin
    // Jika belum penuh, tambahkan data ke array
    SetLength(FData, L + 1);
    FData[L] := AValue;
  end
  else
  begin
    // Jika penuh, geser semua data ke kiri 1 langkah (Live Feed)
    for i := 0 to L - 2 do
      FData[i] := FData[i + 1];
    FData[L - 1] := AValue;
  end;

  Invalidate;
end;

procedure TCyberHoloChart.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberHoloChart.Paint;
var
  i: Integer;
  Count: Integer;
  ActualMin, ActualMax, ValueRange: Single;
  DrawRect: TRect;
  StepX: Single;
  PX, PY: Single;
  LinePts: array of TPointF;
  PolyPts: array of TPointF;
  NeonColor, BgColor: TBGRAPixel;

  // TAMBAHAN VARIABEL UNTUK PERBAIKAN
  ScanlineColor: TBGRAPixel;
  PtsRect: array[0..3] of TPointF;
begin
  // 1. Gambar Background Dark Theme
  BgColor := CyberThemeData.BgDark;
  FBuffer.Fill(BgColor);

  NeonColor := CyberThemeData.PrimaryNeon;
  DrawRect := Rect(5, 10, Width - 5, Height - 10); // Margin area gambar

  // PERBAIKAN ERROR 1: Hitung manual efek transparansi sangat tipis (8 dari 255)
  ScanlineColor.red := (BgColor.red * (255 - 8) + CyberThemeData.TextNormal.red * 8) div 255;
  ScanlineColor.green := (BgColor.green * (255 - 8) + CyberThemeData.TextNormal.green * 8) div 255;
  ScanlineColor.blue := (BgColor.blue * (255 - 8) + CyberThemeData.TextNormal.blue * 8) div 255;
  ScanlineColor.alpha := 255;

  // 2. Gambar Scanlines (Efek CRT Hologram)
  for i := 0 to Height div 3 do
  begin
    FBuffer.DrawLineAntialias(0, i * 3, Width, i * 3, ScanlineColor, 1);
  end;

  // 3. Gambar Grid Wireframe
  for i := 1 to 4 do // 4 Garis horizontal
    FBuffer.DrawLineAntialias(DrawRect.Left, DrawRect.Top + (i * DrawRect.Height / 5),
                              DrawRect.Right, DrawRect.Top + (i * DrawRect.Height / 5),
                              CyberThemeData.BgLighter, 1);

  for i := 1 to 9 do // 9 Garis vertikal
    FBuffer.DrawLineAntialias(DrawRect.Left + (i * DrawRect.Width / 10), DrawRect.Top,
                              DrawRect.Left + (i * DrawRect.Width / 10), DrawRect.Bottom,
                              CyberThemeData.BgLighter, 1);

  Count := Length(FData);
  if Count < 2 then
  begin
    FBuffer.Draw(Canvas, 0, 0, True);
    Exit;
  end;

  // 4. Kalkulasi Skala Min & Max
  if FAutoRange then
  begin
    ActualMin := FData[0];
    ActualMax := FData[0];
    for i := 1 to Count - 1 do
    begin
      if FData[i] < ActualMin then ActualMin := FData[i];
      if FData[i] > ActualMax then ActualMax := FData[i];
    end;
    ValueRange := ActualMax - ActualMin;
    if ValueRange = 0 then ValueRange := 1;
    ActualMin := ActualMin - (ValueRange * 0.1);
    ActualMax := ActualMax + (ValueRange * 0.1);
  end
  else
  begin
    ActualMin := FFixedMin;
    ActualMax := FFixedMax;
  end;

  ValueRange := ActualMax - ActualMin;
  if ValueRange = 0 then ValueRange := 1;

  // 5. Mapping Data ke Koordinat Poligon & Garis
  SetLength(LinePts, Count);
  SetLength(PolyPts, Count + 2);

  StepX := DrawRect.Width / (FMaxPoints - 1);

  for i := 0 to Count - 1 do
  begin
    PX := DrawRect.Left + (i * StepX);
    PY := DrawRect.Bottom - (((FData[i] - ActualMin) / ValueRange) * DrawRect.Height);

    if PY < DrawRect.Top then PY := DrawRect.Top;
    if PY > DrawRect.Bottom then PY := DrawRect.Bottom;

    LinePts[i] := PointF(PX, PY);
    PolyPts[i + 1] := PointF(PX, PY);
  end;

  PolyPts[0] := PointF(LinePts[0].X, DrawRect.Bottom);
  PolyPts[Count + 1] := PointF(LinePts[Count - 1].X, DrawRect.Bottom);

  // 6. Render Hologram Fill (Poligon Transparan)
  NeonColor.alpha := 45;
  FBuffer.FillPolyAntialias(PolyPts, NeonColor);

  // 7. Render Grafik Utama (Garis Glow & Inti)
  NeonColor.alpha := 150;
  FBuffer.DrawPolyLineAntialias(LinePts, NeonColor, 5.0, False);

  NeonColor.alpha := 255;
  FBuffer.DrawPolyLineAntialias(LinePts, NeonColor, 1.5, False);

  // 8. Render Data Nodes (Kotak kecil bercahaya di ujung data terbaru)
  // PERBAIKAN ERROR 2: Konversi ke Integer menggunakan Round() dan perbaiki urutan Left, Top, Right, Bottom
  FBuffer.FillRect(Round(LinePts[Count-1].X - 2), Round(LinePts[Count-1].Y - 2),
                   Round(LinePts[Count-1].X + 2), Round(LinePts[Count-1].Y + 2),
                   CyberThemeData.TextHighlight, dmSet);

  // Bingkai luar chart
  // PERBAIKAN ERROR 3: Gunakan DrawPolyLineAntialias pengganti DrawRectAntialias
  PtsRect[0] := PointF(0, 0);
  PtsRect[1] := PointF(Width-1, 0);
  PtsRect[2] := PointF(Width-1, Height-1);
  PtsRect[3] := PointF(0, Height-1);
  FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.SecondaryNeon, 1.0, True);

  // 9. Proyeksikan ke Kanvas
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
