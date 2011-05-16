<?xml version="1.0" encoding="utf-8"?>
<!--
Copyright (c) 2011, Ziliang Guo
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
    * Neither the name of the ReactOS Project nor the names of its contributors
    may be used to endorse or promote products derived from this software without
    specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
    GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-->
<xsl:stylesheet version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:wix="http://schemas.microsoft.com/wix/2006/wi"
   xmlns:fire="http://schemas.microsoft.com/wix/FirewallExtension">
  <xsl:output indent="yes" method="xml"/>

  <xsl:template match="/wix:Wix">
    <Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
      <Product xmlns="http://schemas.microsoft.com/wix/2006/wi"
       Id="877D13F9-FC8A-42DC-9D57-A7F55A4FEA3A" Name="ReactOS Build Environment"
       Language="1033" Version="1.5.2"
       Manufacturer="ReactOS Project" UpgradeCode="AC1907F1-2D33-4809-A275-91FDEE93F401">
        <Package InstallerVersion="300" Compressed="yes"/>
        <Media Id="1" Cabinet="media1.cab" EmbedCab="yes"/>
        <!-- Always force the root drive to be C: -->
        <Property Id="ROOTDRIVE"><![CDATA[C:\]]></Property>
        <Directory Id="TARGETDIR" Name="SourceDir">
          <Directory Id="ProgramFilesFolder">
            <Directory Id="RosBE" Name="ReactOS Build Environment">
            </Directory>

            <!-- Update the registry, ENV, and FW -->
           <Component Id="CondorRegNEnv" Guid="E282D017-976B-4685-A330-5180B27277C0">
             <RegistryKey Root="HKLM" Key="SOFTWARE\Condor" Action="createAndRemoveOnUninstall" >
                 <RegistryValue Type="string" Name="CONDOR_CONFIG" Value="[INSTALLLOCATION]condor_config" KeyPath="yes" />
                 <RegistryValue Type="string" Name="RELEASE_DIR" Value="[INSTALLLOCATION]"/>
             </RegistryKey>
             <Environment Id="CondorBin" Action="set" Name="PATH" Part="last" Permanent="no" System="yes" Value="[INSTALLLOCATION]bin\"/>
           </Component>

          </Directory>
        </Directory>

        <Condition Message="This application is only supported on Windows XP(SP2) or higher">
          <![CDATA[(VersionNT >= 501)]]>
        </Condition>
        <!-- Feature Block e.g. ComponentRef's -->
        <Feature Id="RosBE" Title="ReactOS Build Environment" Level="1" Display="expand">
          <Feature Id="x86" Title="x86 Build Tools" Level="1">
            <xsl:apply-templates select="wix:Fragment" mode="CompRef">
              <xsl:with-param name="ftype">i386</xsl:with-param>
            </xsl:apply-templates>
          </Feature>
          <Feature Id="x64" Title="x64 Build Tools" Level="1">
            <xsl:apply-templates select="wix:Fragment" mode="CompRef">
              <xsl:with-param name="ftype">amd64</xsl:with-param>
            </xsl:apply-templates>
          </Feature>
          <Feature Id="ARM" Title="ARM Build Tools" Level="1">
          </Feature>
        </Feature>

        <!-- UI Flow + our custom dialogs -->
        <UI Id="MyWixUI_FeatureTree">
            <UIRef Id="WixUI_FeatureTree" />
            <!--<Publish Dialog="LicenseAgreementDlg" Control="Next" Event="NewDialog" Value="CustomizeDlg" Order="2">LicenseAccepted = "1"</Publish>
            <Publish Dialog="CustomizeDlg" Control="Back" Event="NewDialog" Value="LicenseAgreementDlg">1</Publish>-->
        </UI>

        <!--<UIRef Id="WixUI_FeatureTree" />-->
        <UIRef Id="WixUI_ErrorProgressText" />

        <!-- Update  -->
        <WixVariable Id="WixUIBannerBmp" Overridable="yes" Value="../Bitmaps/bannrbmp.bmp"/>
        <WixVariable Id="WixUIDialogBmp" Overridable="yes" Value="../Bitmaps/dlgbmp.bmp"/>

      </Product>

      <!--Output the fragment info which heat generates-->
      <xsl:apply-templates select="wix:Fragment" mode="CopyOf"/>

    </Wix>
  </xsl:template>

  <!-- ************************* Begin Templates ************************* -->
  <!-- Begin CompRef Templates -->
  <xsl:template match="wix:Component" mode="CompRef">
    <xsl:element name="ComponentRef" xmlns="http://schemas.microsoft.com/wix/2006/wi" >
      <xsl:attribute name="Id">
        <xsl:value-of select="@Id" />
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template match="wix:Directory" mode="CompRef" >
    <xsl:apply-templates select="wix:Component" mode="CompRef"/>
    <xsl:apply-templates select="wix:Directory" mode="CompRef"/>
  </xsl:template>

  <xsl:template match="wix:DirectoryRef" mode="CompRef">
    <xsl:apply-templates select="wix:Component" mode="CompRef"/>
    <xsl:apply-templates select="wix:Directory" mode="CompRef"/>
  </xsl:template>

  <xsl:template match="wix:Fragment" mode="CompRef">
    <xsl:param name="ftype"/>
    <xsl:if test="wix:DirectoryRef//wix:Component//wix:File [@Source=contains(@Source, $ftype)]">
      <xsl:apply-templates select="wix:DirectoryRef" mode="CompRef"/>
    </xsl:if>
  </xsl:template>

  <!-- Begin CopyOf Templates -->
  <xsl:template match="wix:File" mode="CopyOf">    


        <xsl:copy>
          <xsl:copy-of select="@*"/>
        </xsl:copy> 


  </xsl:template>

  <xsl:template match="wix:Component" mode="CopyOf">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="wix:File" mode="CopyOf"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="wix:Directory" mode="CopyOf" >
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="wix:Component" mode="CopyOf"/>
      <xsl:apply-templates select="wix:Directory" mode="CopyOf"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="wix:DirectoryRef" mode="CopyOf">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="wix:Component" mode="CopyOf"/>
      <xsl:apply-templates select="wix:Directory" mode="CopyOf"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="wix:Fragment" mode="CopyOf">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="wix:DirectoryRef" mode="CopyOf"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
