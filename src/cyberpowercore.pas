unit CyberPowerCore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, ExtCtrls,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberPowerCore = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FValue: Integer;
    FCriticalLevel: Integer;
    FTimer: TTimer;
    FPulsePhase: Single;

    procedure SetValue(AValue: Integer);
    procedure SetCriticalLevel(AValue: Integer);
    procedure OnPulseTimer(Sender: TObject);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Value: Integer read FValue write SetValue default 100;
    property CriticalLevel: Integer read FCriticalLevel write SetCriticalLevel default 20;
    property Align;
    property Anchors;
    property Font;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberPowerCore]);
end;

{ TCyberPowerCore }

constructor TCyberPowerCore.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  Width := 60;
  Height := 200; // Default berbentuk kapsul silinder memanjang ke bawah
  FValue := 100;
  FCriticalLevel := 20;
  FPulsePhase := 0.0;

  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];

  // Inisialisasi mesin animasi internal
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 50; // Refresh rate 50ms untuk animasi mulus
  FTimer.OnTimer := @OnPulseTimer;
  FTimer.Enabled := True;
end;

destructor TCyberPowerCore.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberPowerCore.OnPulseTimer(Sender: TObject);
var
  PulseSpeed: Single;
begin
  // Logika Rule-Based internal: Kecepatan denyut meningkat jika status kritis
  if FValue <= FCriticalLevel then
    PulseSpeed := 0.4
  else
    PulseSpeed := 0.15;

  FPulsePhase := FPulsePhase + PulseSpeed;

  // Reset rotasi gelombang agar tidak terjadi overflow memory pada phase panjang
  if FPulsePhase > (2 * Pi) then
    FPulsePhase := FPulsePhase - (2 * Pi);

  Invalidate;
end;

procedure TCyberPowerCore.SetValue(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if AValue > 100 then AValue := 100;
  if FValue = AValue then Exit;

  FValue := AValue;
  Invalidate;
end;

procedure TCyberPowerCore.SetCriticalLevel(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if AValue > 100 then AValue := 100;
  if FCriticalLevel = AValue then Exit;

  FCriticalLevel := AValue;
  Invalidate;
end;

procedure TCyberPowerCore.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberPowerCore.Paint;
var
  BaseColor, GlowColor, DarkBg: TBGRAPixel;
  DrawRect: TRect;
  BarHeight, FillHeight: Integer;
  i: Integer;
  PulseWeight: Integer;
  Pts: array[0..5] of TPointF;
  CutSize: Single;
  TextStr: string;
  TextY: Integer;
begin
  // 1. Bersihkan Latar
  FBuffer.Fill(CyberThemeData.BgDark);
  DarkBg := CyberThemeData.BgDark;

  // 2. Evaluasi Logika Status Mesin
  if FValue <= FCriticalLevel then
    BaseColor := CyberThemeData.AlertNeon
  else
    BaseColor := CyberThemeData.PrimaryNeon;

  // 3. Kalkulasi Algoritma Gelombang Denyut (Pulse)
  // Menghasilkan nilai fluktuasi antara 80 hingga 180 menggunakan Sin
  PulseWeight := Round(130 + 50 * Sin(FPulsePhase));

  // HELPER ANTI-GAGAL: Hitung BlendPixel Manual untuk warna Glow
  GlowColor.red := (DarkBg.red * (255 - PulseWeight) + BaseColor.red * PulseWeight) div 255;
  GlowColor.green := (DarkBg.green * (255 - PulseWeight) + BaseColor.green * PulseWeight) div 255;
  GlowColor.blue := (DarkBg.blue * (255 - PulseWeight) + BaseColor.blue * PulseWeight) div 255;
  GlowColor.alpha := 255;

  CutSize := 15.0; // Sudut chamfer reaktor
  DrawRect := Rect(5, 5, Width - 5, Height - 5);
  BarHeight := DrawRect.Height;
  FillHeight := Round((FValue / 100) * BarHeight);

  // Definisi Geometri Reaktor (Segi Enam Vertikal)
  Pts[0] := PointF(DrawRect.Left + CutSize, DrawRect.Top);
  Pts[1] := PointF(DrawRect.Right, DrawRect.Top + CutSize);
  Pts[2] := PointF(DrawRect.Right, DrawRect.Bottom);
  Pts[3] := PointF(DrawRect.Right - CutSize, DrawRect.Bottom);
  Pts[4] := PointF(DrawRect.Left, DrawRect.Bottom - CutSize);
  Pts[5] := PointF(DrawRect.Left, DrawRect.Top);

  // 4. Render Background Reaktor
  FBuffer.FillPolyAntialias(Pts, CyberThemeData.BgLighter);

  // 5. Render Inti Plasma (Plasma Core)
  if FillHeight > 0 then
  begin
    // Plasma Glow Eksterior
    FBuffer.FillRect(DrawRect.Left + 2, DrawRect.Bottom - FillHeight,
                     DrawRect.Right - 2, DrawRect.Bottom - 2, GlowColor, dmSet);

    // Inti Plasma Tajam Interior (Cahaya terkonsentrasi)
    BaseColor.alpha := 255;
    FBuffer.FillRect(DrawRect.Left + (Width div 4), DrawRect.Bottom - FillHeight,
                     DrawRect.Right - (Width div 4), DrawRect.Bottom - 2, BaseColor, dmSet);
  end;

  // 6. Render Cincin Pengendali Reaktor (Containment Rings)
  for i := 1 to 9 do
  begin
    FBuffer.DrawLineAntialias(DrawRect.Left, DrawRect.Top + (i * BarHeight / 10),
                              DrawRect.Right, DrawRect.Top + (i * BarHeight / 10),
                              CyberThemeData.BgDark, 2.0);
  end;

  // 7. Render Bingkai Pelindung (Housing) menggunakan PolyLine (Anti-Gagal)
  FBuffer.DrawPolyLineAntialias(Pts, CyberThemeData.SecondaryNeon, 2.0, True);

  // 8. Render Teks Status
  TextStr := IntToStr(FValue) + '%';
  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  // Kalkulasi manual Y center (Anti-Gagal TTextLayout)
  TextY := Round(Height / 2) - (FBuffer.TextSize(TextStr).cy div 2);

  // Efek Drop Shadow untuk visibilitas pada warna plasma terang
  FBuffer.TextOut(Round(Width / 2) + 1, TextY + 1, TextStr, clBlack, taCenter);
  // Teks Inti
  FBuffer.TextOut(Round(Width / 2), TextY, TextStr, CyberThemeData.TextHighlight, taCenter);

  // 9. Proyeksi Akhir
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
