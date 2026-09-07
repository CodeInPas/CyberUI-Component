unit CyberDivider;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberDividerOrientation = (cdoHorizontal, cdoVertical);
  TCyberDividerStyle = (cdsGlowLine, cdsHazard);

  TCyberDivider = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FOrientation: TCyberDividerOrientation;
    FStyle: TCyberDividerStyle;

    procedure SetOrientation(AValue: TCyberDividerOrientation);
    procedure SetStyle(AValue: TCyberDividerStyle);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Orientation: TCyberDividerOrientation read FOrientation write SetOrientation default cdoHorizontal;
    property Style: TCyberDividerStyle read FStyle write SetStyle default cdsHazard;
    property Align;
    property Anchors;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberDivider]);
end;

{ TCyberDivider }

constructor TCyberDivider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  Width := 200;
  Height := 15; // Default tipis memanjang
  FOrientation := cdoHorizontal;
  FStyle := cdsHazard;

  FBuffer := TBGRABitmap.Create(Width, Height);
end;

destructor TCyberDivider.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberDivider.SetOrientation(AValue: TCyberDividerOrientation);
var
  Temp: Integer;
begin
  if FOrientation = AValue then Exit;
  FOrientation := AValue;

  // Tukar Width dan Height secara otomatis saat orientasi berubah
  if not (csLoading in ComponentState) then
  begin
    Temp := Width;
    Width := Height;
    Height := Temp;
  end;

  Invalidate;
end;

procedure TCyberDivider.SetStyle(AValue: TCyberDividerStyle);
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;
  Invalidate;
end;

procedure TCyberDivider.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberDivider.Paint;
var
  NeonColor, DarkColor, GlowColor: TBGRAPixel;
  i, StepDist: Integer;
  PtsRect: array[0..3] of TPointF;
begin
  // 1. Bersihkan Latar Belakang (Transparan)
  FBuffer.FillTransparent;

  NeonColor := CyberThemeData.PrimaryNeon;
  DarkColor := CyberThemeData.BgDark;

  if FStyle = cdsHazard then
  begin
    // --- MODE HAZARD (Garis Miring Peringatan) ---

    // Blok warna dasar neon
    FBuffer.FillRect(0, 0, Width, Height, NeonColor, dmSet);

    StepDist := 20; // Jarak antar garis miring (Stripe gap)

    // Gambar garis miring (Otomatis terpotong oleh batas FBuffer tanpa perlu algoritma clipping)
    if FOrientation = cdoHorizontal then
    begin
      i := -Height;
      while i < Width + Height do
      begin
        // Garis miring memotong dari bawah ke atas
        FBuffer.DrawLineAntialias(i, Height, i + Height, 0, DarkColor, 10.0);
        Inc(i, StepDist);
      end;
    end
    else
    begin
      i := -Width;
      while i < Height + Width do
      begin
        FBuffer.DrawLineAntialias(0, i, Width, i + Width, DarkColor, 10.0);
        Inc(i, StepDist);
      end;
    end;

    // Bingkai Luar Pembatas Hazard (Menggunakan PolyLine anti-gagal)
    PtsRect[0] := PointF(0, 0);
    PtsRect[1] := PointF(Width-1, 0);
    PtsRect[2] := PointF(Width-1, Height-1);
    PtsRect[3] := PointF(0, Height-1);
    FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.TextNormal, 1.5, True);
  end
  else
  begin
    // --- MODE GLOW LINE (Garis Lurus Minimalis) ---

    // HELPER ANTI-GAGAL: Kalkulasi manual BlendPixel (Bobot 120/255)
    GlowColor.red := (DarkColor.red * (255 - 120) + NeonColor.red * 120) div 255;
    GlowColor.green := (DarkColor.green * (255 - 120) + NeonColor.green * 120) div 255;
    GlowColor.blue := (DarkColor.blue * (255 - 120) + NeonColor.blue * 120) div 255;
    GlowColor.alpha := 255;

    if FOrientation = cdoHorizontal then
    begin
      // Glow Tebal
      FBuffer.DrawLineAntialias(0, Height div 2, Width, Height div 2, GlowColor, 6.0);
      // Inti Neon Tajam
      FBuffer.DrawLineAntialias(0, Height div 2, Width, Height div 2, NeonColor, 1.5);
    end
    else
    begin
      // Glow Tebal
      FBuffer.DrawLineAntialias(Width div 2, 0, Width div 2, Height, GlowColor, 6.0);
      // Inti Neon Tajam
      FBuffer.DrawLineAntialias(Width div 2, 0, Width div 2, Height, NeonColor, 1.5);
    end;
  end;

  // 2. Proyeksikan ke Canvas Utama
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
