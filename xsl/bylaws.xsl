<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:template match="/" mode="bylaws">
    <xsl:apply-templates select="/fb/f[what='bylaws']"/>
  </xsl:template>
  <xsl:template match="/fb/f[what='bylaws' and not(html)]">
    <p class="darkred">
      <xsl:text>There is no information about bylaws.</xsl:text>
    </p>
  </xsl:template>
  <xsl:template match="/fb/f[what='bylaws' and html]">
    <div class="bylaws">
      <h2>
        <xsl:text>Bylaws</xsl:text>
      </h2>
      <div class="columns">
        <xsl:value-of select="html" disable-output-escaping="yes"/>
      </div>
    </div>
  </xsl:template>
</xsl:stylesheet>
