unit CyberEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, StdCtrls, ExtCtrls,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberEdit = class(TCustomControl)
  private
    FInternalEdit: TEdit;
    FBuffer: TBGRABitmap;
    FIsFocused: Boolean;

    procedure InternalEditEnter(Sender: TObject);
    procedure InternalEditExit(Sender: TObject);
    procedure InternalEditChange(Sender: TObject);

    function GetText: string;
    procedure SetText(AValue: string);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Text: string read GetText write SetText;

    property Align;
    property Anchors;
    property Font;
    property Enabled;
    property TabStop default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberEdit]);
end;

constructor TCyberEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls];
  DoubleBuffered := True;

  Width := 200;
  Height := 30;
  FIsFocused := False;
  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];

  // Membuat TEdit internal siluman
  FInternalEdit := TEdit.Create(Self);
  FInternalEdit.Parent := Self;
  FInternalEdit.BorderStyle := bsNone; // Matikan border bawaan OS!

  // Sambungkan event untuk deteksi fokus
  FInternalEdit.OnEnter := @InternalEditEnter;
  FInternalEdit.OnExit := @InternalEditExit;
  FInternalEdit.OnChange := @InternalEditChange;

  // Set tema warna awal
  FInternalEdit.Color := RGBToColor(CyberThemeData.BgDark.red, CyberThemeData.BgDark.green, CyberThemeData.BgDark.blue);
  FInternalEdit.Font.Color := RGBToColor(CyberThemeData.TextNormal.red, CyberThemeData.TextNormal.green, CyberThemeData.TextNormal.blue);
  FInternalEdit.Font.Name := Font.Name;
  FInternalEdit.Font.Size := Font.Size;
  FInternalEdit.Font.Style := Font.Style;
end;

destructor TCyberEdit.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

function TCyberEdit.GetText: string;
begin
  Result := FInternalEdit.Text;
end;

procedure TCyberEdit.SetText(AValue: string);
begin
  FInternalEdit.Text := AValue;
end;

procedure TCyberEdit.InternalEditEnter(Sender: TObject);
begin
  FIsFocused := True;
  FInternalEdit.Font.Color := RGBToColor(CyberThemeData.TextHighlight.red, CyberThemeData.TextHighlight.green, CyberThemeData.TextHighlight.blue);
  Invalidate; // Gambar ulang border agar menyala
end;

procedure TCyberEdit.InternalEditExit(Sender: TObject);
begin
  FIsFocused := False;
  FInternalEdit.Font.Color := RGBToColor(CyberThemeData.TextNormal.red, CyberThemeData.TextNormal.green, CyberThemeData.TextNormal.blue);
  Invalidate; // Gambar ulang border agar redup
end;

procedure TCyberEdit.InternalEditChange(Sender: TObject);
begin
  // Trigger event eksternal jika dibutuhkan nanti
end;

procedure TCyberEdit.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
    FBuffer.SetSize(Width, Height);

  // Posisikan TEdit internal agak ke tengah agar tidak menabrak border buatan kita
  if Assigned(FInternalEdit) then
  begin
    FInternalEdit.Left := 5;
    FInternalEdit.Width := Width - 10;
    // Posisikan di tengah secara vertikal
    FInternalEdit.Top := (Height - FInternalEdit.Height) div 2;
  end;

  Invalidate;
end;

procedure TCyberEdit.Paint;
var
  NeonColor: TBGRAPixel;
  // TAMBAHAN VARIABEL UNTUK PERBAIKAN
  GlowColor: TBGRAPixel;
begin
  // 1. Bersihkan background untuk area pinggiran Edit
  FBuffer.Fill(CyberThemeData.BgDark);

  NeonColor := CyberThemeData.PrimaryNeon;

  if FIsFocused then
  begin
    // PERBAIKAN: Hitung manual blending warna (GlowColor)
    // Meniru bobot 150/255 dari fungsi BlendPixel
    GlowColor.red := (CyberThemeData.BgDark.red * (255 - 150) + NeonColor.red * 150) div 255;
    GlowColor.green := (CyberThemeData.BgDark.green * (255 - 150) + NeonColor.green * 150) div 255;
    GlowColor.blue := (CyberThemeData.BgDark.blue * (255 - 150) + NeonColor.blue * 150) div 255;
    GlowColor.alpha := 255;

    // State FOKUS: Mengetik
    // Gambar bingkai kurung siku ala terminal [    ]
    FBuffer.DrawLineAntialias(0, 0, 5, 0, NeonColor, 2.0); // Kiri atas
    FBuffer.DrawLineAntialias(0, 0, 0, Height, NeonColor, 2.0); // Kiri vertikal
    FBuffer.DrawLineAntialias(0, Height-1, 5, Height-1, NeonColor, 2.0); // Kiri bawah

    FBuffer.DrawLineAntialias(Width-6, 0, Width-1, 0, NeonColor, 2.0); // Kanan atas
    FBuffer.DrawLineAntialias(Width-1, 0, Width-1, Height, NeonColor, 2.0); // Kanan vertikal
    FBuffer.DrawLineAntialias(Width-6, Height-1, Width-1, Height-1, NeonColor, 2.0); // Kanan bawah

    // Garis bawah (Underline) panjang yang bercahaya
    // PERBAIKAN: Gunakan GlowColor hasil perhitungan manual
    FBuffer.DrawLineAntialias(5, Height-1, Width-6, Height-1, GlowColor, 1.0);
  end
  else
  begin
    // State NORMAL (Redup)
    // Cukup gambar garis bawah tipis ala Material Design/Sci-Fi minimalis
    FBuffer.DrawLineAntialias(0, Height-1, Width, Height-1, CyberThemeData.SecondaryNeon, 1.0);

    // Titik aksen di sudut
    FBuffer.SetPixel(0, Height-2, CyberThemeData.TextNormal);
    FBuffer.SetPixel(Width-1, Height-2, CyberThemeData.TextNormal);
  end;

  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
