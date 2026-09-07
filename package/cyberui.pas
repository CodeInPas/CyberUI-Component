{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit cyberui;

{$warn 5023 off : no warning about unused units}
interface

uses
  CyberTheme, CyberButton, CyberGrid, CyberToggle, CyberSlider, CyberGauge, 
  CyberHoloChart, CyberTerminal, CyberRadar, CyberGlitchLabel, CyberTabHeader, 
  CyberPanel, CyberLabel, CyberEdit, CyberLED, Cyber7Seg, CyberProgressBar, 
  CyberKnob, CyberHexGrid, CyberDivider, CyberPowerCore, CyberReticle, 
  CyberWaveform, CyberHexDump, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('CyberButton', @CyberButton.Register);
  RegisterUnit('CyberGrid', @CyberGrid.Register);
  RegisterUnit('CyberToggle', @CyberToggle.Register);
  RegisterUnit('CyberSlider', @CyberSlider.Register);
  RegisterUnit('CyberGauge', @CyberGauge.Register);
  RegisterUnit('CyberHoloChart', @CyberHoloChart.Register);
  RegisterUnit('CyberTerminal', @CyberTerminal.Register);
  RegisterUnit('CyberRadar', @CyberRadar.Register);
  RegisterUnit('CyberGlitchLabel', @CyberGlitchLabel.Register);
  RegisterUnit('CyberTabHeader', @CyberTabHeader.Register);
  RegisterUnit('CyberPanel', @CyberPanel.Register);
  RegisterUnit('CyberLabel', @CyberLabel.Register);
  RegisterUnit('CyberEdit', @CyberEdit.Register);
  RegisterUnit('CyberLED', @CyberLED.Register);
  RegisterUnit('Cyber7Seg', @Cyber7Seg.Register);
  RegisterUnit('CyberProgressBar', @CyberProgressBar.Register);
  RegisterUnit('CyberKnob', @CyberKnob.Register);
  RegisterUnit('CyberHexGrid', @CyberHexGrid.Register);
  RegisterUnit('CyberDivider', @CyberDivider.Register);
  RegisterUnit('CyberPowerCore', @CyberPowerCore.Register);
  RegisterUnit('CyberReticle', @CyberReticle.Register);
  RegisterUnit('CyberWaveform', @CyberWaveform.Register);
  RegisterUnit('CyberHexDump', @CyberHexDump.Register);
end;

initialization
  RegisterPackage('cyberui', @Register);
end.
