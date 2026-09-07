unit UMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  BGRABitmap, BGRABitmapTypes,
  CyberTheme, CyberPanel, CyberPowerCore, CyberWaveform, CyberLED,
  Cyber7Seg, CyberHexGrid, CyberReticle, CyberRadar, CyberGlitchLabel,
  CyberTerminal, CyberHexDump, CyberDivider, CyberKnob, CyberProgressBar;

type
  { TFrmMain }
  TFrmMain = class(TForm)
    PnlLeft: TCyberPanel;
    PnlCenter: TCyberPanel;
    PnlRight: TCyberPanel;

    PowerCore: TCyberPowerCore;
    Waveform: TCyberWaveform;
    SysLED: TCyberLED;
    TimerDisplay: TCyber7Seg;

    HexMap: TCyberHexGrid;
    TargetReticle: TCyberReticle;
    TacticalRadar: TCyberRadar;
    GlitchTitle: TCyberGlitchLabel;

    Terminal: TCyberTerminal;
    MemDump: TCyberHexDump;
    DivHazard: TCyberDivider;
    KnobPower: TCyberKnob;
    ProgShield: TCyberProgressBar;

    procedure FormCreate(Sender: TObject);
    procedure KnobPowerChange(Sender: TObject);
  private
    FEngineTick: Integer;
    FCurrentTheme: Integer;
    EngineTimer: TTimer; // Timer disembunyikan di sini agar LFM tidak kebingungan
    
    // Prosedur manual dipindahkan ke private
    procedure EngineTimerTimer(Sender: TObject);
    procedure GlitchTitleClick(Sender: TObject); 
    procedure ApplyGlobalTheme(ThemeIndex: Integer); 
  public
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.lfm}

{ TFrmMain }

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Color := clBlack;
  WindowState := wsMaximized;

  // Injeksi Properti Aman (Menghindari Crash LFM)
  PnlLeft.BorderSpacing.Around := 10;
  PnlRight.BorderSpacing.Around := 10;
  PnlCenter.BorderSpacing.Around := 10;
  Terminal.BorderSpacing.Around := 10;
  DivHazard.BorderSpacing.Around := 10;
  MemDump.BorderSpacing.Around := 10;
  
  // Setel judul secara manual di sini
  GlitchTitle.Caption := 'PANOPTICON';
  GlitchTitle.OnClick := @GlitchTitleClick;

  FCurrentTheme := 0; 
  FEngineTick := 0;

  Terminal.addLog('PANOPTICON SYSTEM INITIALIZED...');
  Terminal.addLog('AWAITING RULE-BASED ENGINE DIRECTIVES.');
  Terminal.addLog('TIP: CLICK THE TITLE TO SWITCH THEMES.');

  EngineTimer := TTimer.Create(Self);
  EngineTimer.Interval := 1000;
  EngineTimer.OnTimer := @EngineTimerTimer;
  EngineTimer.Enabled := True;
end;

procedure TFrmMain.ApplyGlobalTheme(ThemeIndex: Integer);
begin
  case ThemeIndex of
    0: 
    begin
      CyberThemeData.BgDark := BGRA(15, 20, 25, 255);
      CyberThemeData.BgLighter := BGRA(30, 40, 50, 255);
      CyberThemeData.PrimaryNeon := BGRA(0, 255, 255, 255);
      CyberThemeData.SecondaryNeon := BGRA(0, 150, 200, 255);
      CyberThemeData.AlertNeon := BGRA(255, 50, 50, 255);
      CyberThemeData.TextNormal := BGRA(180, 200, 220, 255);
      CyberThemeData.TextHighlight := BGRA(255, 255, 255, 255);
      Terminal.addLog('SYS_THEME: APPLIED "NEON CYAN"');
    end;
    1: 
    begin
      CyberThemeData.BgDark := BGRA(25, 10, 10, 255);
      CyberThemeData.BgLighter := BGRA(50, 20, 20, 255);
      CyberThemeData.PrimaryNeon := BGRA(255, 50, 50, 255);
      CyberThemeData.SecondaryNeon := BGRA(180, 40, 40, 255);
      CyberThemeData.AlertNeon := BGRA(255, 255, 0, 255);
      CyberThemeData.TextNormal := BGRA(220, 180, 180, 255);
      CyberThemeData.TextHighlight := BGRA(255, 200, 200, 255);
      Terminal.addLog('SYS_THEME: APPLIED "CRIMSON PROTOCOL"');
    end;
    2: 
    begin
      CyberThemeData.BgDark := BGRA(20, 15, 10, 255);
      CyberThemeData.BgLighter := BGRA(45, 30, 15, 255);
      CyberThemeData.PrimaryNeon := BGRA(255, 180, 0, 255);
      CyberThemeData.SecondaryNeon := BGRA(200, 120, 0, 255);
      CyberThemeData.AlertNeon := BGRA(255, 50, 50, 255);
      CyberThemeData.TextNormal := BGRA(220, 200, 150, 255);
      CyberThemeData.TextHighlight := BGRA(255, 255, 200, 255);
      Terminal.addLog('SYS_THEME: APPLIED "RETRO AMBER"');
    end;
  end;
  Invalidate;
end;

procedure TFrmMain.GlitchTitleClick(Sender: TObject);
begin
  Inc(FCurrentTheme);
  if FCurrentTheme > 2 then FCurrentTheme := 0;
  ApplyGlobalTheme(FCurrentTheme);
end;

procedure TFrmMain.EngineTimerTimer(Sender: TObject);
begin
  Inc(FEngineTick);
  PowerCore.Value := PowerCore.Value - Random(5);
  if PowerCore.Value < 0 then
  begin
    PowerCore.Value := 100;
    Terminal.addLog('CRITICAL: POWER CORE REBOOT INITIATED!');
  end;

  if FEngineTick mod 3 = 0 then
  begin
    HexMap.SelectedCol := Random(HexMap.ColCount);
    HexMap.SelectedRow := Random(HexMap.RowCount);
    TargetReticle.TargetAngle := Random(360);
    Waveform.IsTransmitting := not Waveform.IsTransmitting;
  end;
end;

procedure TFrmMain.KnobPowerChange(Sender: TObject);
begin
  ProgShield.Position := KnobPower.Position;
  if ProgShield.Position > 75 then
    SysLED.ThemeColor := clcPrimary
  else if ProgShield.Position > 30 then
    SysLED.ThemeColor := clcSecondary
  else
    SysLED.ThemeColor := clcAlert;
end;

end.
