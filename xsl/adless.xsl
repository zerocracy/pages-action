<?xml version="1.0" encoding="UTF-8"?>
<!--
* SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
* SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <!--
  Removes the Zerocracy favicon, logo and link from the HTML
  printed by the "judges" tool as HTML, for the "adless" mode.
  -->
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  <xsl:template match="link[contains(@href, 'zerocracy.com')]"/>
  <xsl:template match="a[contains(@href, 'zerocracy.com')]"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
