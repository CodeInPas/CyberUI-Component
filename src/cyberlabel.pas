unit CyberLabel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberLabel = class(TGraphicControl)
  private
    FCaption: string;
    FGlowEnabled: Boolean;
    FBuffer: TBGRABitmap;
    procedure SetCaption(AValue: string);
    procedure SetGlowEnabled(AValue: Boolean);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Caption: string read FCaption write SetCaption;
    property GlowEnabled: Boolean read FGlowEnabled write SetGlowEnabled default False;

    property Align;
    property Anchors;
    property Font;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberLabel]);
end;

constructor TCyberLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 100;
  Height := 25;
  FCaption := 'CYBER_LABEL';
  FGlowEnabled := False;
  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];
end;

destructor TCyberLabel.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberLabel.SetCaption(AValue: string);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  Invalidate;
end;

procedure TCyberLabel.SetGlowEnabled(AValue: Boolean);
begin
  if FGlowEnabled = AValue then Exit;
  FGlowEnabled := AValue;
  Invalidate;
end;

procedure TCyberLabel.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberLabel.Paint;
var
  TxtColor, GlowColor: TBGRAPixel;
begin
  // Label biasanya transparan, jadi kita tidak melakukan FBuffer.Fill
  // Kita salin apa yang ada di belakangnya agar benar-benar transparan
  FBuffer.FillTransparent;

  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  TxtColor := CyberThemeData.TextNormal;

  if FGlowEnabled then
  begin
    TxtColor := CyberThemeData.TextHighlight;
    GlowColor := CyberThemeData.PrimaryNeon;
    GlowColor.alpha := 150;

    // PERBAIKAN: Hapus argumen tlTop, gunakan 5 argumen saja
    // Efek Glow: Gambar teks sedikit bergeser dengan warna neon transparan
    FBuffer.TextOut(1, 1, FCaption, GlowColor, taLeftJustify);
    FBuffer.TextOut(3, 3, FCaption, GlowColor, taLeftJustify);
  end;

  // PERBAIKAN: Hapus argumen tlTop
  // Teks Utama
  FBuffer.TextOut(2, 2, FCaption, TxtColor, taLeftJustify);

  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
