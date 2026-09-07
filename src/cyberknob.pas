unit CyberKnob;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberKnob = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FIsDragging: Boolean;
    FLastMouseY: Integer;
    FOnChange: TNotifyEvent;

    procedure SetPosition(AValue: Integer);
    procedure SetMin(AValue: Integer);
    procedure SetMax(AValue: Integer);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Position: Integer read FPosition write SetPosition default 50;
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Align;
    property Anchors;
    property Font;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberKnob]);
end;

{ TCyberKnob }

constructor TCyberKnob.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];
  DoubleBuffered := True;
  Width := 80;
  Height := 80;
  FMin := 0;
  FMax := 100;
  FPosition := 50;
  FIsDragging := False;
  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];
end;

destructor TCyberKnob.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberKnob.SetPosition(AValue: Integer);
begin
  if AValue < FMin then AValue := FMin;
  if AValue > FMax then AValue := FMax;
  if FPosition = AValue then Exit;

  FPosition := AValue;
  Invalidate;

  // Memicu event OnChange agar bisa di-hook ke logika algoritma engine Anda
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TCyberKnob.SetMin(AValue: Integer);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FPosition < FMin then SetPosition(FMin) else Invalidate;
end;

procedure TCyberKnob.SetMax(AValue: Integer);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FPosition > FMax then SetPosition(FMax) else Invalidate;
end;

procedure TCyberKnob.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberKnob.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FIsDragging := True;
    FLastMouseY := Y;
    Invalidate; // Gambar ulang untuk memberikan efek visual menyala saat disentuh
  end;
end;

procedure TCyberKnob.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Delta: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging then
  begin
    // Geser kursor ke ATAS = Nilai Bertambah, BAWAH = Berkurang
    Delta := FLastMouseY - Y;

    if Delta <> 0 then
    begin
      // Mengurangi sensitivitas drag (dibagi 2) agar presisi
      if Abs(Delta) > 1 then
      begin
        SetPosition(FPosition + (Delta div 2));
        FLastMouseY := Y;
      end;
    end;
  end;
end;

procedure TCyberKnob.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FIsDragging := False;
    Invalidate; // Gambar ulang untuk meredupkan komponen
  end;
end;

procedure TCyberKnob.Paint;
const
  StartAngle = 135;  // Mulai dari kiri bawah
  SweepAngle = 270;  // Sapuan putaran
var
  CX, CY, Radius: Single;
  CurrentAngleDeg, AngleRad: Single;
  X1, Y1, X2, Y2: Single;
  i, TotalTicks: Integer;
  NeonColor, TickColor, GlowColor: TBGRAPixel;
  Ratio: Single;
  TextY: Integer;
  ValText: string;

  // HELPER ANTI-GAGAL: Gambar Lingkaran Manual
  procedure DrawCustomCircle(Center_X, Center_Y, Rad: Single; Clr: TBGRAPixel; LineThick: Single);
  var
    j: Integer;
    CircPts: array[0..36] of TPointF;
  begin
    for j := 0 to 36 do
    begin
      CircPts[j] := PointF(Center_X + (Rad * Cos(DegToRad(j * 10))),
                           Center_Y + (Rad * Sin(DegToRad(j * 10))));
    end;
    FBuffer.DrawPolyLineAntialias(CircPts, Clr, LineThick, True);
  end;

begin
  // 1. Bersihkan Latar
  FBuffer.Fill(CyberThemeData.BgDark);

  CX := Width / 2;
  CY := Height / 2;

  if Width < Height then
    Radius := (Width / 2) - 10
  else
    Radius := (Height / 2) - 10;

  NeonColor := CyberThemeData.PrimaryNeon;

  // HELPER ANTI-GAGAL: Hitung BlendPixel Manual
  GlowColor.red := (CyberThemeData.BgDark.red * (255 - 100) + NeonColor.red * 100) div 255;
  GlowColor.green := (CyberThemeData.BgDark.green * (255 - 100) + NeonColor.green * 100) div 255;
  GlowColor.blue := (CyberThemeData.BgDark.blue * (255 - 100) + NeonColor.blue * 100) div 255;
  GlowColor.alpha := 255;

  if (FMax - FMin) = 0 then Ratio := 0
  else Ratio := (FPosition - FMin) / (FMax - FMin);

  CurrentAngleDeg := StartAngle + (Ratio * SweepAngle);

  // 2. Gambar Outer Ring (Indikator titik-titik melingkar)
  TotalTicks := 25;
  for i := 0 to TotalTicks do
  begin
    AngleRad := DegToRad(StartAngle + (i * SweepAngle / TotalTicks));
    X1 := CX + (Radius * Cos(AngleRad));
    Y1 := CY + (Radius * Sin(AngleRad));
    X2 := CX + ((Radius - 5) * Cos(AngleRad));
    Y2 := CY + ((Radius - 5) * Sin(AngleRad));

    if (StartAngle + (i * SweepAngle / TotalTicks)) <= CurrentAngleDeg then
    begin
      TickColor := NeonColor;
      // Berikan efek pendar tipis pada bar yang aktif
      FBuffer.DrawLineAntialias(X1, Y1, X2, Y2, GlowColor, 4.0);
    end
    else
      TickColor := CyberThemeData.BgLighter;

    FBuffer.DrawLineAntialias(X1, Y1, X2, Y2, TickColor, 2.0);
  end;

  // 3. Gambar Inner Dial (Basis piringan pemutar)
  DrawCustomCircle(CX, CY, Radius - 12, CyberThemeData.BgLighter, 2.0);

  // Berikan respon visual jika sedang ditahan (di-drag)
  if FIsDragging then
    DrawCustomCircle(CX, CY, Radius - 12, GlowColor, 6.0);

  // 4. Gambar Pointer (Jarum penunjuk arah putaran)
  AngleRad := DegToRad(CurrentAngleDeg);
  X1 := CX + ((Radius - 22) * Cos(AngleRad));
  Y1 := CY + ((Radius - 22) * Sin(AngleRad));
  X2 := CX + ((Radius - 12) * Cos(AngleRad));
  Y2 := CY + ((Radius - 12) * Sin(AngleRad));

  FBuffer.DrawLineAntialias(X1, Y1, X2, Y2, GlowColor, 6.0); // Glow pointer
  FBuffer.DrawLineAntialias(X1, Y1, X2, Y2, CyberThemeData.TextHighlight, 2.5); // Inti tajam

  // 5. Gambar Teks Nilai di Tengah Piringan (Tanpa TTextLayout)
  ValText := IntToStr(FPosition);
  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  TextY := Round(CY) - (FBuffer.TextSize(ValText).cy div 2);

  if FIsDragging then
    FBuffer.TextOut(Round(CX), TextY, ValText, CyberThemeData.TextHighlight, taCenter)
  else
    FBuffer.TextOut(Round(CX), TextY, ValText, CyberThemeData.TextNormal, taCenter);

  // 6. Proyeksikan ke Canvas
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
