unit CyberWaveform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, ExtCtrls,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberWaveStyle = (cwsEqualizer, cwsSineWave);

  TCyberWaveform = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FIsTransmitting: Boolean;
    FStyle: TCyberWaveStyle;
    FTimer: TTimer;
    FPhase: Single;

    // Array dinamis untuk menyimpan target tinggi masing-masing bar equalizer
    FTargetHeights: array of Single;
    FCurrentHeights: array of Single;

    procedure SetIsTransmitting(AValue: Boolean);
    procedure SetStyle(AValue: TCyberWaveStyle);
    procedure OnWaveTimer(Sender: TObject);
    procedure InitializeBars;
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property IsTransmitting: Boolean read FIsTransmitting write SetIsTransmitting default True;
    property Style: TCyberWaveStyle read FStyle write SetStyle default cwsEqualizer;
    property Align;
    property Anchors;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberWaveform]);
end;

{ TCyberWaveform }

constructor TCyberWaveform.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  Width := 200;
  Height := 60;
  FIsTransmitting := True;
  FStyle := cwsEqualizer;
  FPhase := 0.0;

  FBuffer := TBGRABitmap.Create(Width, Height);

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40; // ~25 FPS untuk animasi dinamis namun hemat CPU
  FTimer.OnTimer := @OnWaveTimer;
  FTimer.Enabled := FIsTransmitting;
end;

destructor TCyberWaveform.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberWaveform.InitializeBars;
var
  BarCount, i: Integer;
begin
  if Width <= 0 then Exit;

  // Asumsi lebar setiap bar adalah 4px + 2px gap = 6px
  BarCount := (Width div 6) + 1;
  SetLength(FTargetHeights, BarCount);
  SetLength(FCurrentHeights, BarCount);

  for i := 0 to High(FTargetHeights) do
  begin
    FTargetHeights[i] := 0;
    FCurrentHeights[i] := 0;
  end;
end;

procedure TCyberWaveform.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    InitializeBars;
    Invalidate;
  end;
end;

procedure TCyberWaveform.SetIsTransmitting(AValue: Boolean);
var
  i: Integer;
begin
  if FIsTransmitting = AValue then Exit;
  FIsTransmitting := AValue;
  FTimer.Enabled := FIsTransmitting;

  // Jika dimatikan, reset target tinggi ke 0 agar gelombang mereda secara natural
  if not FIsTransmitting then
  begin
    for i := 0 to High(FTargetHeights) do
      FTargetHeights[i] := 0;
  end;

  Invalidate;
end;

procedure TCyberWaveform.SetStyle(AValue: TCyberWaveStyle);
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;
  Invalidate;
end;

procedure TCyberWaveform.OnWaveTimer(Sender: TObject);
var
  i: Integer;
  MaxH: Single;
begin
  FPhase := FPhase + 0.15;
  if FPhase > (2 * Pi) then FPhase := FPhase - (2 * Pi);

  MaxH := Height * 0.9;

  // Logika Interpolasi untuk Equalizer
  if FStyle = cwsEqualizer then
  begin
    for i := 0 to High(FTargetHeights) do
    begin
      // Jika mode aktif, acak target baru saat posisi current sudah mendekati target
      if FIsTransmitting then
      begin
        if Abs(FCurrentHeights[i] - FTargetHeights[i]) < 2.0 then
        begin
          // Kombinasi gelombang dasar (Sine) dan Noise (Random) agar terlihat teknis
          FTargetHeights[i] := (Sin(FPhase + (i * 0.5)) * MaxH * 0.3) + Random(Round(MaxH * 0.7));
          if FTargetHeights[i] < 2 then FTargetHeights[i] := 2; // Minimal tinggi bar
        end;
      end;

      // Bergerak mulus menuju target (Lerp sederhana)
      FCurrentHeights[i] := FCurrentHeights[i] + ((FTargetHeights[i] - FCurrentHeights[i]) * 0.3);
    end;
  end;

  Invalidate;
end;

procedure TCyberWaveform.Paint;
var
  NeonColor, GlowColor: TBGRAPixel;
  i: Integer;
  BarX, BarY, BarW: Integer;
  WavePts: array of TPointF;
  X, Y: Single;
  MidY, MaxAmp: Single;
begin
  // Background transparan agar menyatu dengan panel terminal
  FBuffer.FillTransparent;

  NeonColor := CyberThemeData.SecondaryNeon;

  if FStyle = cwsEqualizer then
  begin
    // --- MODE EQUALIZER ---
    BarW := 4; // Lebar bar

    for i := 0 to High(FCurrentHeights) do
    begin
      BarX := i * 6; // Jarak antar bar (4px bar + 2px gap)
      if BarX > Width then Break;

      // Hitung posisi Y agar bar bermula dari bawah
      BarY := Height - Round(FCurrentHeights[i]);

      // Warna redup jika tidak aktif
      if not FIsTransmitting and (FCurrentHeights[i] <= 2) then
      begin
        NeonColor := CyberThemeData.BgLighter;
        FBuffer.FillRect(BarX, Height - 2, BarX + BarW, Height, NeonColor, dmSet);
      end
      else
      begin
        // Gambar inti bar
        FBuffer.FillRect(BarX, BarY, BarX + BarW, Height, NeonColor, dmSet);

        // Titik puncak (Peak dot) yang melayang sedikit di atas bar
        if BarY > 4 then
          FBuffer.FillRect(BarX, BarY - 4, BarX + BarW, BarY - 2, CyberThemeData.TextHighlight, dmSet);
      end;
    end;
  end
  else
  begin
    // --- MODE SINE WAVE (Gelombang Osilator Murni) ---
    MidY := Height / 2;
    MaxAmp := (Height / 2) - 4;

    SetLength(WavePts, Width div 2); // Kerapatan poin untuk garis lengkung

    for i := 0 to High(WavePts) do
    begin
      X := i * 2;
      if FIsTransmitting then
      begin
        // Superposisi dua gelombang Sine untuk menciptakan efek interferensi frekuensi radio
        Y := MidY + (Sin(FPhase * 2 + (X * 0.05)) * (MaxAmp * 0.6)) +
                    (Sin(FPhase * -1.5 + (X * 0.1)) * (MaxAmp * 0.4));
      end
      else
      begin
        // Jika mati, garis menjadi lurus di tengah (Flatline)
        Y := MidY;
      end;

      WavePts[i] := PointF(X, Y);
    end;

    // HELPER ANTI-GAGAL: Hitung Glow Manual (Bobot 100/255)
    GlowColor.red := (CyberThemeData.BgDark.red * (255 - 100) + NeonColor.red * 100) div 255;
    GlowColor.green := (CyberThemeData.BgDark.green * (255 - 100) + NeonColor.green * 100) div 255;
    GlowColor.blue := (CyberThemeData.BgDark.blue * (255 - 100) + NeonColor.blue * 100) div 255;
    GlowColor.alpha := 255;

    // Gambar gelombang Glow
    if Length(WavePts) > 0 then
    begin
      FBuffer.DrawPolyLineAntialias(WavePts, GlowColor, 5.0, False);
      // Gambar gelombang Inti Tajam
      FBuffer.DrawPolyLineAntialias(WavePts, CyberThemeData.TextHighlight, 1.5, False);
    end;
  end;

  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
