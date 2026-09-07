unit CyberToggle;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberToggle }

  TCyberToggle = class(TCustomControl)
  private
    FChecked: Boolean;
    FOnChange: TNotifyEvent;

    // Variabel untuk Animasi
    FAnimTimer: TTimer;
    FSlidePos: Single; // Nilai 0.0 (Off) hingga 1.0 (On)
    FTargetPos: Single;
    FBuffer: TBGRABitmap;

    procedure SetChecked(AValue: Boolean);
    procedure OnAnimTimerTick(Sender: TObject);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Resize; override;
    procedure DoChange; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Checked: Boolean read FChecked write SetChecked default False;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // Expose standard properties
    property Align;
    property Anchors;
    property Enabled;
    property TabStop default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberToggle]);
end;

{ TCyberToggle }

constructor TCyberToggle.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls];
  DoubleBuffered := True;
  TabStop := True; // Agar bisa diakses via tombol Tab di keyboard

  Width := 60;
  Height := 24;
  FChecked := False;
  FSlidePos := 0.0;
  FTargetPos := 0.0;

  FBuffer := TBGRABitmap.Create(Width, Height);

  // Setup Timer Animasi (60 FPS = ~16ms)
  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Enabled := False;
  FAnimTimer.Interval := 16;
  FAnimTimer.OnTimer := @OnAnimTimerTick;
end;

destructor TCyberToggle.Destroy;
begin
  FAnimTimer.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberToggle.SetChecked(AValue: Boolean);
begin
  if FChecked = AValue then Exit;
  FChecked := AValue;

  if FChecked then
    FTargetPos := 1.0
  else
    FTargetPos := 0.0;

  // Jika sedang di mode desain (IDE), jangan animasi, langsung lompat nilainya
  if csDesigning in ComponentState then
  begin
    FSlidePos := FTargetPos;
    Invalidate;
  end
  else
    FAnimTimer.Enabled := True; // Mulai animasi saat runtime

  DoChange;
end;

procedure TCyberToggle.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCyberToggle.OnAnimTimerTick(Sender: TObject);
const
  AnimSpeed = 0.15; // Kecepatan geser per tick
begin
  // Logika Interpolasi (Mendekati target)
  if FSlidePos < FTargetPos then
  begin
    FSlidePos := FSlidePos + AnimSpeed;
    if FSlidePos >= FTargetPos then
    begin
      FSlidePos := FTargetPos;
      FAnimTimer.Enabled := False; // Hentikan timer jika sudah sampai
    end;
  end
  else if FSlidePos > FTargetPos then
  begin
    FSlidePos := FSlidePos - AnimSpeed;
    if FSlidePos <= FTargetPos then
    begin
      FSlidePos := FTargetPos;
      FAnimTimer.Enabled := False;
    end;
  end;

  Invalidate; // Gambar ulang setiap frame animasi
end;

procedure TCyberToggle.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    SetFocus;
    Checked := not Checked; // Balikkan status saat diklik
  end;
end;

procedure TCyberToggle.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  // Mendukung pergantian status menggunakan tombol Spasi
  if (Key = 32) {VK_SPACE} and Enabled then
    Checked := not Checked;
end;

procedure TCyberToggle.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberToggle.Paint;
var
  TrackRect: TRect;
  ThumbX, ThumbW, ThumbH: Integer;
  Pts: array[0..5] of TPointF;
  CutSize: Single;
  NeonColor, BgColor: TBGRAPixel;
  GlowAlpha: Byte;

  // Tambahan variabel untuk perbaikan error
  PtsRect: array[0..3] of TPointF;
  Weight: Integer;
begin
  // 1. Bersihkan Latar Belakang Form
  FBuffer.Fill(CyberThemeData.BgDark);

  // 2. Hitung Area Track (Jalur geser)
  TrackRect := Rect(0, Height div 4, Width, Height - (Height div 4));

  // 3. Hitung Warna dan Transparansi berdasarkan FSlidePos
  NeonColor := CyberThemeData.PrimaryNeon;
  GlowAlpha := Round(150 * FSlidePos);

  BgColor := CyberThemeData.BgLighter;

  if GlowAlpha > 0 then
  begin
    // PERBAIKAN ERROR 1: Blending warna RGB manual (100% kompatibel di semua versi)
    Weight := Round(100 * FSlidePos); // Rentang 0 s.d 100

    BgColor.red := (CyberThemeData.BgLighter.red * (100 - Weight) + NeonColor.red * Weight) div 100;
    BgColor.green := (CyberThemeData.BgLighter.green * (100 - Weight) + NeonColor.green * Weight) div 100;
    BgColor.blue := (CyberThemeData.BgLighter.blue * (100 - Weight) + NeonColor.blue * Weight) div 100;
    BgColor.alpha := 255;
  end;

  // 4. Gambar Track
  FBuffer.FillRect(TrackRect.Left, TrackRect.Top, TrackRect.Right, TrackRect.Bottom, BgColor, dmSet);

  // PERBAIKAN ERROR 2: Gunakan DrawPolyLineAntialias untuk Border Track
  PtsRect[0] := PointF(TrackRect.Left, TrackRect.Top);
  PtsRect[1] := PointF(TrackRect.Right, TrackRect.Top);
  PtsRect[2] := PointF(TrackRect.Right, TrackRect.Bottom);
  PtsRect[3] := PointF(TrackRect.Left, TrackRect.Bottom);
  FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.SecondaryNeon, 1.0, True);

  // 5. Hitung Posisi & Ukuran Thumb (Knob/Pegangan)
  ThumbW := Width div 3;
  ThumbH := Height;
  ThumbX := Round((Width - ThumbW) * FSlidePos);

  // Bentuk polygon thumb dengan chamfer
  CutSize := ThumbH * 0.25;
  Pts[0] := PointF(ThumbX, 0);
  Pts[1] := PointF(ThumbX + ThumbW - 1 - CutSize, 0);
  Pts[2] := PointF(ThumbX + ThumbW - 1, CutSize);
  Pts[3] := PointF(ThumbX + ThumbW - 1, ThumbH - 1);
  Pts[4] := PointF(ThumbX + CutSize, ThumbH - 1);
  Pts[5] := PointF(ThumbX, ThumbH - 1 - CutSize);

  // 6. Gambar Thumb
  if FSlidePos > 0.1 then
  begin
    NeonColor.alpha := GlowAlpha;
    FBuffer.FillPolyAntialias(Pts, NeonColor);
    FBuffer.DrawPolyLineAntialias(Pts, NeonColor, 5, True);
  end
  else
  begin
    FBuffer.FillPolyAntialias(Pts, CyberThemeData.BgLighter);
  end;

  FBuffer.DrawPolyLineAntialias(Pts, CyberThemeData.PrimaryNeon, 1.5, True);

  FBuffer.DrawLineAntialias(ThumbX + (ThumbW div 2), ThumbH * 0.3,
                            ThumbX + (ThumbW div 2), ThumbH * 0.7,
                            CyberThemeData.BgDark, 2.0);

  // 7. Fokus Indikator (Jika diakses pakai keyboard)
  if Focused then
  begin
    // PERBAIKAN ERROR 3: Gunakan DrawPolyLineAntialias untuk Fokus Indikator
    PtsRect[0] := PointF(0, 0);
    PtsRect[1] := PointF(Width-1, 0);
    PtsRect[2] := PointF(Width-1, Height-1);
    PtsRect[3] := PointF(0, Height-1);
    FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.TextNormal, 1.0, True);
  end;

  // 8. Terapkan ke Canvas LCL
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
