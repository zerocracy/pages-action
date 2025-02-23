<?xml version="1.0"?>
<!--
 * Copyright (c) 2024-2025 Zerocracy
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" exclude-result-prefixes="xs z">
  <xsl:template match="f[what='earned-value' and ac and ev and pv]" priority="2">
    <xsl:text>AC: </xsl:text>
    <xsl:value-of select="format-number(ac, '0')"/>
    <xsl:text>, EV: </xsl:text>
    <xsl:value-of select="format-number(ev, '0')"/>
    <xsl:text>, PV: </xsl:text>
    <xsl:value-of select="format-number(pv, '0')"/>
    <xsl:text>, CPI: </xsl:text>
    <xsl:copy-of select="z:index(ev div ac)"/>
    <xsl:text>, SPI: </xsl:text>
    <xsl:copy-of select="z:index(ev div pv)"/>
    <xsl:text>.</xsl:text>
  </xsl:template>
  <xsl:template match="f[what='earned-value']" priority="1">
    <p class="darkred">
      <xsl:text>Not enough data in the latest earned-value fact.</xsl:text>
    </p>
  </xsl:template>
</xsl:stylesheet>
