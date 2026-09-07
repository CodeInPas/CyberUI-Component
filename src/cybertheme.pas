unit CyberTheme;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BGRABitmap, BGRABitmapTypes;

type
  // Pilihan palet warna untuk game simulasi Anda
  TCyberThemeMode = (ctmCyanNeon, ctmMagentaNeon, ctmMatrixGreen);

  { TCyberTheme }

  TCyberTheme = class
  private
    FThemeMode: TCyberThemeMode;
    procedure SetThemeMode(AValue: TCyberThemeMode);
  public
    // Base Colors (Background & Surface)
    BgDark: TBGRAPixel;
    BgLighter: TBGRAPixel;

    // Neon Colors (Aksen & Interaksi)
    PrimaryNeon: TBGRAPixel;
    SecondaryNeon: TBGRAPixel;
    AlertNeon: TBGRAPixel;

    // Text Colors
    TextNormal: TBGRAPixel;
    TextHighlight: TBGRAPixel;

    // Global Render Properties
    GlowIntensity: Integer;
    WireframeThickness: Integer;

    constructor Create;
    procedure ApplyTheme(AMode: TCyberThemeMode);

    property ThemeMode: TCyberThemeMode read FThemeMode write SetThemeMode;
  end;

var
  // Singleton global object. Semua komponen CyberUI akan membaca warna dari sini.
  CyberThemeData: TCyberTheme;

implementation

{ TCyberTheme }

constructor TCyberTheme.Create;
begin
  // Set default tema saat aplikasi berjalan
  ApplyTheme(ctmCyanNeon);
end;

procedure TCyberTheme.SetThemeMode(AValue: TCyberThemeMode);
begin
  if FThemeMode = AValue then Exit;
  FThemeMode := AValue;
  ApplyTheme(FThemeMode);
end;

procedure TCyberTheme.ApplyTheme(AMode: TCyberThemeMode);
begin
  // Warna dasar UI (Cyberpunk / Dark Mode pekat)
  BgDark        := BGRA(15, 15, 20, 255);     // Biru gelap nyaris hitam
  BgLighter     := BGRA(35, 35, 45, 255);     // Panel yang sedikit lebih terang

  TextNormal    := BGRA(200, 200, 220, 255);  // Putih keabu-abuan
  TextHighlight := BGRA(255, 255, 255, 255);  // Putih solid untuk hover

  AlertNeon     := BGRA(255, 50, 50, 255);    // Merah bahaya / Error log

  GlowIntensity := 15;                        // Radius blur untuk efek neon
  WireframeThickness := 1;                    // Ketebalan garis grid standar

  // Switch warna neon berdasarkan Mode Tema
  case AMode of
    ctmCyanNeon:
      begin
        PrimaryNeon   := BGRA(0, 255, 255, 255);   // Cyan dominan (Tron style)
        SecondaryNeon := BGRA(255, 0, 255, 255);   // Magenta untuk aksen (Synthwave)
      end;
    ctmMagentaNeon:
      begin
        PrimaryNeon   := BGRA(255, 0, 255, 255);   // Dibalik: Magenta dominan
        SecondaryNeon := BGRA(0, 255, 255, 255);
      end;
    ctmMatrixGreen:
      begin
        PrimaryNeon   := BGRA(0, 255, 0, 255);     // Hijau terang
        SecondaryNeon := BGRA(0, 150, 0, 255);     // Hijau gelap
        BgDark        := BGRA(5, 10, 5, 255);      // Background agak kehijauan
        TextNormal    := BGRA(150, 255, 150, 255); // Teks hijau pudar
      end;
  end;
end;

initialization
  // Otomatis membuat instance saat unit ini dipanggil pertama kali
  CyberThemeData := TCyberTheme.Create;

finalization
  // Membersihkan memori saat aplikasi ditutup
  if Assigned(CyberThemeData) then
    CyberThemeData.Free;

end.
