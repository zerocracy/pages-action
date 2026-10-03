<?xml version="1.0" encoding="UTF-8"?>
<!--
* SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
* SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="xs z">
  <xsl:variable name="fb" select="/fb"/>
  <xsl:function name="z:pmp">
    <!--
    Finds a "pmp" fact with the given "area" and then
    tries to find a given property inside.
    -->
    <xsl:param name="area" as="xs:string"/>
    <xsl:param name="param" as="xs:string"/>
    <xsl:param name="default" as="xs:string"/>
    <xsl:variable name="a" select="$fb/f[what='pmp' and area=$area][1]"/>
    <xsl:choose>
      <xsl:when test="$a">
        <xsl:variable name="v" select="$a/*[name()=$param][1]/text()"/>
        <xsl:choose>
          <xsl:when test="$v">
            <xsl:value-of select="$v"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$default"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$default"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>
