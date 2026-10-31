<?xml version="1.0" encoding="UTF-8"?>
<!--
* SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
* SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="xs z">
  <xsl:variable name="fb" select="/fb"/>
  <xsl:function name="z:pmp">
    <!--
    Finds the first "pmp" fact with the given "area" that has
    the given property and returns its value. If no such fact
    is found or the value is empty, the default value is returned.
    -->
    <xsl:param name="area" as="xs:string"/>
    <xsl:param name="param" as="xs:string"/>
    <xsl:param name="default" as="xs:string"/>
    <xsl:variable name="a" select="$fb/f[what='pmp' and area=$area and *[name()=$param]][1]"/>
    <xsl:choose>
      <xsl:when test="$a">
        <xsl:variable name="property" select="$a/*[name()=$param][1]"/>
        <xsl:variable name="v" select="string(($property/v, $property[not(v)])[1])"/>
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
