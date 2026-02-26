<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="xs">
  <xsl:template match="/" mode="assessment">
    <xsl:apply-templates select="/fb/f[what='latest-assessment']"/>
  </xsl:template>
  <xsl:template match="/fb/f[what='latest-assessment']">
    <div class="assessment">
      <h2>
        <xsl:text>Assessment</xsl:text>
      </h2>
      <pre>
        <xsl:value-of select="text"/>
        <xsl:text>Last assessed on </xsl:text>
        <xsl:value-of select="xs:date(xs:dateTime(when))"/>
      </pre>
      <xsl:if test="total &gt; 1">
        <p class="darkred">
          <xsl:value-of select="total"/>
          <xsl:text> assessments on factbase were found</xsl:text>
        </p>
      </xsl:if>
    </div>
  </xsl:template>
</xsl:stylesheet>
