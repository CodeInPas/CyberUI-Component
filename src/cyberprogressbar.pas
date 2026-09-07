unit CyberProgressBar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberProgressStyle = (cpsSegmented, cpsContinuous);

  { TCyberProgressBar }

  TCyberProgressBar = class(TGraphicControl)
  private
    FBuffer: TBGRABitmap;
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FStyle: TCyberProgressStyle;
    FShowText: Boolean;
    FSuffix: string;

    procedure SetMin(AValue: Integer);
    procedure SetMax(AValue: Integer);
    procedure SetPosition(AValue: Integer);
    procedure SetStyle(AValue: TCyberProgressStyle);
    procedure SetShowText(AValue: Boolean);
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
    property Position: Integer read FPosition write SetPosition default 50;
    property Style: TCyberProgressStyle read FStyle write SetStyle default cpsSegmented;
    property ShowText: Boolean read FShowText write SetShowText default True;
    property Suffix: string read FSuffix write SetSuffix; // Contoh: "%" atau " / 100"

    property Align;
    property Anchors;
    property Font;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberProgressBar]);
end;

{ TCyberProgressBar }

constructor TCyberProgressBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 25;

  FMin := 0;
  FMax := 100;
  FPosition := 50;
  FStyle := cpsSegmented;
  FShowText := True;
  FSuffix := '%';

  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];
end;

destructor TCyberProgressBar.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberProgressBar.SetMin(AValue: Integer);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FMin > FMax then FMax := FMin;
  SetPosition(FPosition); // Evaluasi ulang posisi
  Invalidate;
end;

procedure TCyberProgressBar.SetMax(AValue: Integer);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FMax < FMin then FMin := FMax;
  SetPosition(FPosition);
  Invalidate;
end;

procedure TCyberProgressBar.SetPosition(AValue: Integer);
begin
  if AValue < FMin then AValue := FMin;
  if AValue > FMax then AValue := FMax;
  if FPosition = AValue then Exit;
  FPosition := AValue;
  Invalidate;
end;

procedure TCyberProgressBar.SetStyle(AValue: TCyberProgressStyle);
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;
  Invalidate;
end;

procedure TCyberProgressBar.SetShowText(AValue: Boolean);
begin
  if FShowText = AValue then Exit;
  FShowText := AValue;
  Invalidate;
end;

procedure TCyberProgressBar.SetSuffix(AValue: string);
begin
  if FSuffix = AValue then Exit;
  FSuffix := AValue;
  Invalidate;
end;

procedure TCyberProgressBar.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberProgressBar.Paint;
var
  Ratio: Single;
  FillWidth, BarWidth, BarHeight, DrawX, DrawY: Integer;
  SegWidth, SegGap, TotalSegs, ActiveSegs, i: Integer;
  NeonColor, BgColor, FillColor: TBGRAPixel;
  DisplayText: string;
  Pts: array[0..5] of TPointF;
  CutSize: Single;

  // TAMBAHAN VARIABEL UNTUK PERBAIKAN
  SegGlowColor, EdgeGlowColor: TBGRAPixel;
  TextY: Integer;
begin
  // 1. Bersihkan Background
  FBuffer.Fill(CyberThemeData.BgDark);

  NeonColor := CyberThemeData.PrimaryNeon;
  BgColor := CyberThemeData.BgLighter;

  // PERBAIKAN 1: Kalkulasi manual BlendPixel
  // A. Warna glow untuk mode Segmented (Bobot 80)
  SegGlowColor.red := (CyberThemeData.BgDark.red * (255 - 80) + NeonColor.red * 80) div 255;
  SegGlowColor.green := (CyberThemeData.BgDark.green * (255 - 80) + NeonColor.green * 80) div 255;
  SegGlowColor.blue := (CyberThemeData.BgDark.blue * (255 - 80) + NeonColor.blue * 80) div 255;
  SegGlowColor.alpha := 255;

  // B. Warna glow untuk ujung laser mode Continuous (Bobot 150)
  EdgeGlowColor.red := (CyberThemeData.BgDark.red * (255 - 150) + NeonColor.red * 150) div 255;
  EdgeGlowColor.green := (CyberThemeData.BgDark.green * (255 - 150) + NeonColor.green * 150) div 255;
  EdgeGlowColor.blue := (CyberThemeData.BgDark.blue * (255 - 150) + NeonColor.blue * 150) div 255;
  EdgeGlowColor.alpha := 255;

  // Padding dalam
  DrawX := 2;
  DrawY := 2;
  BarWidth := Width - 4;
  BarHeight := Height - 4;

  if (FMax - FMin) = 0 then Ratio := 0
  else Ratio := (FPosition - FMin) / (FMax - FMin);

  FillWidth := Round(Ratio * BarWidth);

  // 2. Gambar Bingkai Luar (Container dengan sudut Chamfer)
  CutSize := BarHeight * 0.3;
  Pts[0] := PointF(DrawX, DrawY);
  Pts[1] := PointF(DrawX + BarWidth - CutSize, DrawY);
  Pts[2] := PointF(DrawX + BarWidth, DrawY + CutSize);
  Pts[3] := PointF(DrawX + BarWidth, DrawY + BarHeight);
  Pts[4] := PointF(DrawX + CutSize, DrawY + BarHeight);
  Pts[5] := PointF(DrawX, DrawY + BarHeight - CutSize);

  // Isi container dengan warna redup
  FBuffer.FillPolyAntialias(Pts, BgColor);
  // Bingkai luar tipis
  FBuffer.DrawPolyLineAntialias(Pts, CyberThemeData.SecondaryNeon, 1.0, True);

  // 3. Render Bar Progress
  if FillWidth > 0 then
  begin
    if FStyle = cpsSegmented then
    begin
      // --- MODE SEGMENTED (Balok Putus-putus) ---
      SegWidth := 6;
      SegGap := 2;
      TotalSegs := BarWidth div (SegWidth + SegGap);
      ActiveSegs := Round(Ratio * TotalSegs);

      for i := 0 to TotalSegs - 1 do
      begin
        if i < ActiveSegs then
        begin
          FillColor := NeonColor;

          // Terapkan SegGlowColor manual
          FBuffer.FillRect(DrawX + (i * (SegWidth + SegGap)) - 1, DrawY + 2,
                           DrawX + (i * (SegWidth + SegGap)) + SegWidth + 1, DrawY + BarHeight - 2,
                           SegGlowColor, dmSet);
        end
        else
          FillColor := CyberThemeData.BgDark; // Segmen mati

        FBuffer.FillRect(DrawX + (i * (SegWidth + SegGap)), DrawY + 3,
                         DrawX + (i * (SegWidth + SegGap)) + SegWidth, DrawY + BarHeight - 3,
                         FillColor, dmSet);
      end;
    end
    else
    begin
      // --- MODE CONTINUOUS (Bar Solid) ---
      FillColor := NeonColor;
      FillColor.alpha := 180; // Agak transparan agar bg di belakang sedikit terlihat

      // Jika bar penuh, paskan dengan poligon, jika belum penuh pakai kotak biasa
      if Ratio >= 0.98 then
        FBuffer.FillPolyAntialias(Pts, FillColor)
      else
        FBuffer.FillRect(DrawX, DrawY + 1, DrawX + FillWidth, DrawY + BarHeight - 1, FillColor, dmSet);

      // Gambar ujung garis (Leading Edge / "Laser head") yang menyala sangat terang
      if FillWidth < BarWidth then
      begin
        FBuffer.DrawLineAntialias(DrawX + FillWidth, DrawY, DrawX + FillWidth, DrawY + BarHeight,
                                  CyberThemeData.TextHighlight, 2.0);
        // Terapkan EdgeGlowColor manual
        FBuffer.DrawLineAntialias(DrawX + FillWidth, DrawY, DrawX + FillWidth, DrawY + BarHeight,
                                  EdgeGlowColor, 6.0);
      end;
    end;
  end;

  // 4. Render Teks Progress (Jika aktif)
  if FShowText then
  begin
    DisplayText := IntToStr(FPosition) + FSuffix;

    FBuffer.FontName := Font.Name;
    FBuffer.FontHeight := Abs(Font.Height);
    FBuffer.FontStyle := Font.Style;

    // PERBAIKAN 2: Hitung posisi Y manual agar berada tepat di tengah
    TextY := (Height - FBuffer.TextSize(DisplayText).cy) div 2;

    // Gambar teks dengan 5 argumen saja (hapus tlCenter)
    FBuffer.TextOut((Width div 2) + 1, TextY + 1, DisplayText, clBlack, taCenter);
    FBuffer.TextOut(Width div 2, TextY, DisplayText, CyberThemeData.TextHighlight, taCenter);
  end;

  // 5. Proyeksikan ke layar
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
