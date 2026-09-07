unit CyberSlider;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberSlider }

  TCyberSlider = class(TCustomControl)
  private
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FOnChange: TNotifyEvent;

    // Status Interaksi
    FIsDragging: Boolean;
    FHovered: Boolean;
    FBuffer: TBGRABitmap;

    procedure SetMin(AValue: Integer);
    procedure SetMax(AValue: Integer);
    procedure SetPosition(AValue: Integer);
    function XToValue(X: Integer): Integer;
    function ValueToX(AValue: Integer): Integer;
    procedure DoChange;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Position: Integer read FPosition write SetPosition default 50;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Enabled;
    property TabStop default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberSlider]);
end;

{ TCyberSlider }

constructor TCyberSlider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls];
  DoubleBuffered := True;
  TabStop := True;

  Width := 200;
  Height := 30;

  FMin := 0;
  FMax := 100;
  FPosition := 50;
  FIsDragging := False;
  FHovered := False;

  FBuffer := TBGRABitmap.Create(Width, Height);
end;

destructor TCyberSlider.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberSlider.SetMin(AValue: Integer);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FMin > FMax then FMax := FMin;
  if FPosition < FMin then SetPosition(FMin) else Invalidate;
end;

procedure TCyberSlider.SetMax(AValue: Integer);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FMax < FMin then FMin := FMax;
  if FPosition > FMax then SetPosition(FMax) else Invalidate;
end;

procedure TCyberSlider.SetPosition(AValue: Integer);
begin
  // Batasi (Clamp) nilai agar tidak melebihi Min atau Max
  if AValue < FMin then AValue := FMin;
  if AValue > FMax then AValue := FMax;

  if FPosition = AValue then Exit;

  FPosition := AValue;
  Invalidate;
  DoChange;
end;

procedure TCyberSlider.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

// Konversi koordinat layar (Pixel X) menjadi nilai Slider
function TCyberSlider.XToValue(X: Integer): Integer;
var
  TrackLeft, TrackWidth: Integer;
  Ratio: Single;
begin
  TrackLeft := 15;
  TrackWidth := Width - 30; // Sisakan 15 pixel di kiri dan kanan

  if TrackWidth <= 0 then Exit(FMin);

  Ratio := (X - TrackLeft) / TrackWidth;
  if Ratio < 0 then Ratio := 0;
  if Ratio > 1 then Ratio := 1;

  Result := FMin + Round(Ratio * (FMax - FMin));
end;

// Konversi nilai Slider menjadi koordinat layar (Pixel X)
function TCyberSlider.ValueToX(AValue: Integer): Integer;
var
  TrackLeft, TrackWidth: Integer;
  Ratio: Single;
begin
  TrackLeft := 15;
  TrackWidth := Width - 30;

  if (FMax - FMin) = 0 then Exit(TrackLeft);

  Ratio := (AValue - FMin) / (FMax - FMin);
  Result := TrackLeft + Round(Ratio * TrackWidth);
end;

procedure TCyberSlider.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    SetFocus;
    FIsDragging := True;
    SetPosition(XToValue(X)); // Langsung lompat ke posisi klik
  end;
end;

procedure TCyberSlider.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging then
    SetPosition(XToValue(X));
end;

procedure TCyberSlider.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
    FIsDragging := False;
end;

procedure TCyberSlider.MouseEnter;
begin
  inherited MouseEnter;
  FHovered := True;
  Invalidate;
end;

procedure TCyberSlider.MouseLeave;
begin
  inherited MouseLeave;
  FHovered := False;
  FIsDragging := False; // Keamanan agar tidak tersangkut
  Invalidate;
end;

procedure TCyberSlider.KeyDown(var Key: Word; Shift: TShiftState);
var
  StepSize: Integer;
begin
  inherited KeyDown(Key, Shift);
  if not Enabled then Exit;

  StepSize := Round((FMax - FMin) * 0.05); // Langkah 5% dari total range
  if StepSize < 1 then StepSize := 1;

  if Key = VK_LEFT then SetPosition(Position - StepSize)
  else if Key = VK_RIGHT then SetPosition(Position + StepSize)
  else if Key = VK_HOME then SetPosition(FMin)
  else if Key = VK_END then SetPosition(FMax);
end;

procedure TCyberSlider.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberSlider.Paint;
var
  TrackLeft, TrackRight, TrackWidth: Integer;
  LedSpacing, LedWidth, NumLEDs, i: Integer;
  LedX, LedVal: Integer;
  ThumbX, ThumbY, ThumbSize: Integer;
  Pts: array[0..3] of TPointF;
  NeonColor, LedColor, FillColor: TBGRAPixel;

  // TAMBAHAN VARIABEL UNTUK PERBAIKAN ERROR
  GlowColor: TBGRAPixel;
  PtsRect: array[0..3] of TPointF;
begin
  FBuffer.Fill(CyberThemeData.BgDark);

  TrackLeft := 15;
  TrackRight := Width - 15;
  TrackWidth := TrackRight - TrackLeft;
  NeonColor := CyberThemeData.PrimaryNeon;

  // PERBAIKAN 1: Hitung manual blending warna (GlowColor)
  // Ini meniru persentase pencampuran warna 80/255 tanpa memanggil fungsi BlendPixel
  GlowColor.red := (CyberThemeData.BgDark.red * (255 - 80) + NeonColor.red * 80) div 255;
  GlowColor.green := (CyberThemeData.BgDark.green * (255 - 80) + NeonColor.green * 80) div 255;
  GlowColor.blue := (CyberThemeData.BgDark.blue * (255 - 80) + NeonColor.blue * 80) div 255;
  GlowColor.alpha := 255;

  // 1. Gambar LED Segments (Garis putus-putus)
  LedSpacing := 6; // Jarak antar titik LED
  LedWidth := 2;   // Lebar setiap blok LED
  NumLEDs := TrackWidth div LedSpacing;

  for i := 0 to NumLEDs do
  begin
    LedX := TrackLeft + (i * LedSpacing);
    LedVal := XToValue(LedX);

    // Jika posisi LED lebih kecil dari nilai saat ini, nyalakan!
    if LedVal <= FPosition then
    begin
      LedColor := NeonColor;

      // Terapkan GlowColor yang sudah dihitung manual
      FBuffer.FillRect(LedX - 1, Height div 2 - 3, LedX + LedWidth + 1, Height div 2 + 3,
                       GlowColor, dmSet);
    end
    else
      LedColor := CyberThemeData.BgLighter; // LED mati (redup)

    // Gambar batang LED vertikal
    FBuffer.FillRect(LedX, Height div 2 - 2, LedX + LedWidth, Height div 2 + 2, LedColor, dmSet);
  end;

  // 2. Gambar Garis Dasar Tipis di bawah LED (menyambungkan semua)
  FBuffer.DrawLineAntialias(TrackLeft, Height div 2 + 4, TrackRight, Height div 2 + 4, CyberThemeData.BgLighter, 1.0);

  // 3. Hitung & Gambar Thumb (Pegangan)
  ThumbX := ValueToX(FPosition);
  ThumbY := Height div 2;
  ThumbSize := 6; // Jari-jari (radius) thumb

  // Kita buat bentuk belah ketupat (Diamond) tajam
  Pts[0] := PointF(ThumbX, ThumbY - ThumbSize);
  Pts[1] := PointF(ThumbX + ThumbSize, ThumbY);
  Pts[2] := PointF(ThumbX, ThumbY + ThumbSize);
  Pts[3] := PointF(ThumbX - ThumbSize, ThumbY);

  if FIsDragging or FHovered then
  begin
    FillColor := NeonColor;
    FillColor.alpha := 150; // Agak transparan di tengah
    FBuffer.FillPolyAntialias(Pts, FillColor);
    // Glow untuk thumb
    FBuffer.DrawPolyLineAntialias(Pts, NeonColor, 4, True);
  end
  else
  begin
    FBuffer.FillPolyAntialias(Pts, CyberThemeData.BgDark);
  end;

  // Garis luar belah ketupat
  FBuffer.DrawPolyLineAntialias(Pts, CyberThemeData.TextHighlight, 1.5, True);

  // 4. Garis Fokus Keyboard
  if Focused then
  begin
    // PERBAIKAN 2: Gunakan DrawPolyLineAntialias untuk kotak fokus keyboard
    PtsRect[0] := PointF(0, 0);
    PtsRect[1] := PointF(Width-1, 0);
    PtsRect[2] := PointF(Width-1, Height-1);
    PtsRect[3] := PointF(0, Height-1);
    FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.TextNormal, 1.0, True);
  end;

  // 5. Proyeksikan ke layar
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
