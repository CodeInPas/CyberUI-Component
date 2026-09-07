unit CyberGlitchLabel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Math, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberGlitchLabel }

  TCyberGlitchLabel = class(TGraphicControl)
  private
    FBuffer: TBGRABitmap;
    FCaption: string;
    FGlitchIntensity: Integer;

    // Sistem Timer Ganda
    FIdleTimer: TTimer;
    FGlitchTimer: TTimer;

    FIsGlitching: Boolean;
    FGlitchFrameCount: Integer;

    procedure SetCaption(AValue: string);
    procedure OnIdleTimerTick(Sender: TObject);
    procedure OnGlitchTimerTick(Sender: TObject);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Prosedur untuk memicu glitch secara manual (misal saat player kena damage)
    procedure TriggerGlitch;
  published
    property Caption: string read FCaption write SetCaption;
    property GlitchIntensity: Integer read FGlitchIntensity write FGlitchIntensity default 4;

    property Align;
    property Anchors;
    property Font;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberGlitchLabel]);
end;

{ TCyberGlitchLabel }

constructor TCyberGlitchLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Width := 150;
  Height := 40;
  FCaption := 'SYSTEM_ERROR';
  FGlitchIntensity := 4;
  FIsGlitching := False;

  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 14;
  Font.Style := [fsBold];

  // Timer 1: Menunggu waktu santai (Interval acak 2 s.d 5 detik)
  FIdleTimer := TTimer.Create(Self);
  FIdleTimer.Interval := 2000 + Random(3000);
  FIdleTimer.OnTimer := @OnIdleTimerTick;

  // Timer 2: Animasi frame glitch yang super cepat (~60 FPS)
  FGlitchTimer := TTimer.Create(Self);
  FGlitchTimer.Interval := 16;
  FGlitchTimer.Enabled := False;
  FGlitchTimer.OnTimer := @OnGlitchTimerTick;

  if not (csDesigning in ComponentState) then
  begin
    Randomize;
    FIdleTimer.Enabled := True;
  end;
end;

destructor TCyberGlitchLabel.Destroy;
begin
  FIdleTimer.Free;
  FGlitchTimer.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberGlitchLabel.SetCaption(AValue: string);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  Invalidate;
end;

procedure TCyberGlitchLabel.TriggerGlitch;
begin
  if FIsGlitching then Exit;

  FIsGlitching := True;
  FGlitchFrameCount := 0;

  FIdleTimer.Enabled := False; // Hentikan masa santai
  FGlitchTimer.Enabled := True; // Mulai animasi glitch
end;

procedure TCyberGlitchLabel.OnIdleTimerTick(Sender: TObject);
begin
  // Saat Idle Timer menyala, picu efek glitch
  TriggerGlitch;
end;

procedure TCyberGlitchLabel.OnGlitchTimerTick(Sender: TObject);
begin
  Inc(FGlitchFrameCount);

  // Hentikan glitch setelah ~150 milidetik (sekitar 10 frame)
  if FGlitchFrameCount > 10 then
  begin
    FIsGlitching := False;
    FGlitchTimer.Enabled := False;

    // Setel ulang interval Idle Timer secara acak untuk glitch berikutnya
    FIdleTimer.Interval := 1000 + Random(4000);
    FIdleTimer.Enabled := True;
  end;

  Invalidate; // Gambar ulang layar
end;

procedure TCyberGlitchLabel.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberGlitchLabel.Paint;
var
  DrawX, DrawY: Integer;
  OffsetX, OffsetY: Integer;
  SliceY, SliceHeight: Integer;
  CyanColor, MagentaColor: TBGRAPixel;
begin
  // 1. Bersihkan Latar Belakang
  FBuffer.Fill(CyberThemeData.BgDark);

  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  DrawX := Width div 2;
  // PERBAIKAN ERROR: Hitung posisi Y manual agar tepat di tengah vertikal
  DrawY := (Height - FBuffer.TextSize(FCaption).cy) div 2;

  if not FIsGlitching then
  begin
    // STATE NORMAL: Gambar teks biasa yang tajam dan diam (Hapus tlCenter)
    FBuffer.TextOut(DrawX, DrawY, FCaption, CyberThemeData.TextNormal, taCenter);
  end
  else
  begin
    // STATE GLITCH: Animasi rusak

    // Kalkulasi Jitter (Getaran posisi X dan Y)
    OffsetX := Random(FGlitchIntensity * 2) - FGlitchIntensity;
    OffsetY := Random(3) - 1;

    // Warna untuk Chromatic Aberration
    CyanColor := BGRA(0, 255, 255, 200);     // Primary RGB Shift
    MagentaColor := BGRA(255, 0, 255, 200);  // Secondary RGB Shift

    // Layer 1 (Bawah): Bayangan Magenta bergeser ke kiri (Hapus tlCenter)
    FBuffer.TextOut(DrawX - OffsetX - (FGlitchIntensity div 2), DrawY + OffsetY,
                    FCaption, MagentaColor, taCenter);

    // Layer 2 (Tengah): Bayangan Cyan bergeser ke kanan (Hapus tlCenter)
    FBuffer.TextOut(DrawX + OffsetX + (FGlitchIntensity div 2), DrawY - OffsetY,
                    FCaption, CyanColor, taCenter);

    // Layer 3 (Atas): Teks utama berwarna putih terang, bergetar searah OffsetX (Hapus tlCenter)
    FBuffer.TextOut(DrawX + OffsetX, DrawY,
                    FCaption, CyberThemeData.TextHighlight, taCenter);

    // Efek Slicing / Tearing (Garis hitam tipis acak memotong teks)
    // Mensimulasikan data raster yang hilang (Scanline error)
    if Random(100) > 30 then // 70% kemungkinan muncul garis potong di frame ini
    begin
      SliceY := Random(Height);
      SliceHeight := 1 + Random(3);
      FBuffer.FillRect(0, SliceY, Width, SliceY + SliceHeight, CyberThemeData.BgDark, dmSet);
    end;
  end;

  // 2. Proyeksikan ke Canvas
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
