<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2000/svg" version="2.0">
  <xsl:output method="xml" omit-xml-declaration="yes"/>
  <xsl:template match="/fb">
    <xsl:variable name="sum" select="sum(.//f/award)"/>
    <xsl:variable name="count" select="count(.//f/award)"/>
    <xsl:variable name="avg">
      <xsl:choose>
        <xsl:when test="$count = 0">
          <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="format-number($sum div $count, '0.0')" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="width">
      <xsl:choose>
        <xsl:when test="abs($avg) &gt; 99">
          <xsl:text>126</xsl:text>
        </xsl:when>
        <xsl:when test="abs($avg) &gt; 50">
          <xsl:text>116</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>106</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <svg width="{$width}" height="20">
      <linearGradient id="b" x2="0" y2="100%">
        <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
        <stop offset="1" stop-opacity=".1"/>
      </linearGradient>
      <mask id="a">
        <rect width="{$width}" height="20" rx="3" fill="#fff"/>
      </mask>
      <g mask="url(#a)">
        <path fill="#555" d="M0 0h62v20H0z"/>
        <path fill="#4c1" d="M62 0h67v20H62z">
          <xsl:attribute name="fill">
            <xsl:text>#</xsl:text>
            <xsl:choose>
              <xsl:when test="$avg &gt; 16">
                <xsl:text>4c1</xsl:text>
              </xsl:when>
              <xsl:when test="$avg &gt; 0">
                <xsl:text>fb8530</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>e05d44</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </path>
        <path fill="url(#b)" d="M0 0h{$width}v20H0z"/>
      </g>
      <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
        <text x="31" y="15" fill="#010101" fill-opacity=".3">Zerocracy</text>
        <text x="31" y="14">Zerocracy</text>
        <text x="{$width - 3.5}" y="15" fill="#010101" fill-opacity=".3" text-anchor="end">
          <xsl:value-of select="$avg"/>
        </text>
        <text x="{$width - 3.5}" y="14" text-anchor="end">
          <xsl:value-of select="$avg"/>
        </text>
      </g>
    </svg>
  </xsl:template>
</xsl:stylesheet>
