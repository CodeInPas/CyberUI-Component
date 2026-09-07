unit CyberButton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberButtonState = (cbsNormal, cbsHover, cbsPressed);

  { TCyberButton }

  TCyberButton = class(TCustomControl)
  private
    FState: TCyberButtonState;
    FBuffer: TBGRABitmap;
    procedure SetState(AValue: TCyberButtonState);
  protected
    procedure Paint; override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Action;
    property Align;
    property Anchors;
    property Caption;
    property Enabled;
    property Font;
    property OnClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseUp;
  end;

procedure Register;

implementation

procedure Register;
begin
  // Mendaftarkan komponen ke tab 'CyberUI' di Component Palette Lazarus
  RegisterComponents('CyberUI', [TCyberButton]);
end;

{ TCyberButton }

constructor TCyberButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];
  DoubleBuffered := True;
  Width := 120;
  Height := 40;
  FState := cbsNormal;
  FBuffer := TBGRABitmap.Create(Width, Height);

  // Default font style untuk tema cyber
  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];
end;

destructor TCyberButton.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberButton.SetState(AValue: TCyberButtonState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  Invalidate; // Memaksa komponen untuk menggambar ulang dirinya saat state berubah
end;

procedure TCyberButton.MouseEnter;
begin
  inherited MouseEnter;
  SetState(cbsHover);
end;

procedure TCyberButton.MouseLeave;
begin
  inherited MouseLeave;
  SetState(cbsNormal);
end;

procedure TCyberButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
    SetState(cbsPressed);
end;

procedure TCyberButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    // Jika kursor masih di dalam area tombol saat klik dilepas, kembali ke Hover. Jika tidak, Normal.
    if ClientRect.Contains(Point(X, Y)) then
      SetState(cbsHover)
    else
      SetState(cbsNormal);
  end;
end;

procedure TCyberButton.Resize;
begin
  inherited Resize;
  // Perbarui ukuran buffer BGRABitmap jika ukuran tombol diubah
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberButton.Paint;
var
  Pts: array[0..5] of TPointF;
  CutSize: Single;
  NeonColor, FillColor, TextColor: TBGRAPixel;
  AlphaIntensity: Byte;
  TextY: Integer; // 1. TAMBAHKAN VARIABEL INI
begin
  // ... [Kode langkah 1 sampai 6 Anda tetap sama persis, tidak perlu diubah] ...

  // 7. Render Text Caption
  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  // 2. PERBAIKAN: Hitung posisi Y agar teks persis di tengah secara vertikal
  TextY := (Height - FBuffer.TextSize(Caption).cy) div 2;

  // Render teks dengan 5 argumen saja (tanpa tlCenter)
  if FState = cbsPressed then
    FBuffer.TextOut(Width div 2, TextY + 1, Caption, TextColor, taCenter)
  else
    FBuffer.TextOut(Width div 2, TextY, Caption, TextColor, taCenter);

  // 8. Pindahkan buffer ke Canvas LCL
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
