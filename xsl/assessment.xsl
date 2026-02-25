<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:template match="/" mode="assessment">
    <xsl:apply-templates select="/fb/f[what='assessment']"/>
  </xsl:template>
  <xsl:template match="/fb/f[what='assessment' and text]">
    <div class="assessment">
      <h2>
        <xsl:text>Assessment</xsl:text>
      </h2>
      <p>
        <xsl:value-of select="text"/>
      </p>
    </div>
  </xsl:template>
</xsl:stylesheet>
