<?xml version="1.0" encoding="UTF-8"?>
<!--
MIT License

Copyright (c) 2024-2025 Zerocracy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to who_namem the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs">
  <xsl:template name="qo-section">
    <xsl:param name="what" as="xs:string"/>
    <xsl:param name="title" as="xs:string"/>
    <xsl:param name="colors" as="xs:string" select="'n_composite:orange'"/>
    <xsl:param name="before"/>
    <xsl:variable name="facts" select="/fb/f[what=$what and xs:dateTime(when) &gt; (xs:dateTime($today) - xs:dayTimeDuration('P180D'))]"/>
    <xsl:choose>
      <xsl:when test="empty($facts)">
        <p class="darkred">
          <xsl:text>There is no information about the </xsl:text>
          <xsl:value-of select="$title"/>
          <xsl:text>.</xsl:text>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <h2>
          <xsl:value-of select="$title"/>
        </h2>
        <xsl:if test="not(empty($before))">
          <p>
            <xsl:copy-of select="$before"/>
          </p>
        </xsl:if>
        <div class="qo-section">
          <canvas id="{$what}">
            <xsl:text> </xsl:text>
          </canvas>
        </div>
        <script type="text/javascript">
          <xsl:text>$(function(){const color = chroma('#D3D3D3'); qo_render('</xsl:text>
          <xsl:value-of select="$what"/>
          <xsl:text>',{labels:[</xsl:text>
          <xsl:for-each select="$facts">
            <xsl:sort select="when" data-type="text" order="ascending"/>
            <xsl:if test="position() &gt; 1">
              <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>'</xsl:text>
            <xsl:value-of select="format-date(xs:date(xs:dateTime(when)), '[M1]/[D1]')"/>
            <xsl:text>'</xsl:text>
          </xsl:for-each>
          <xsl:text>],</xsl:text>
          <xsl:text>datasets:[</xsl:text>
          <xsl:for-each select="distinct-values($facts/*[starts-with(name(), 'n_')]/name())">
            <xsl:variable name="n" select="."/>
            <xsl:if test="position() &gt; 1">
              <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>{label:'</xsl:text>
            <xsl:value-of select="substring-after($n, 'n_')"/>
            <xsl:text>',borderColor:</xsl:text>
            <xsl:variable name='c' select="substring-before(substring-after(concat(',', $colors, ','), concat(',', $n, ':')), ',')"/>
            <xsl:choose>
              <xsl:when test="$c">
                <xsl:text>'</xsl:text>
                <xsl:value-of select="$c"/>
                <xsl:text>'</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>color.darken(</xsl:text>
                <xsl:value-of select="position() * 0.4"/>
                <xsl:text>).hex()</xsl:text>
                <xsl:text>,borderWidth:1</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text>,data:[</xsl:text>
            <xsl:for-each select="$facts">
              <xsl:sort select="when" data-type="text" order="ascending"/>
              <xsl:if test="position() &gt; 1">
                <xsl:text>,</xsl:text>
              </xsl:if>
              <xsl:choose>
                <xsl:when test="*[name()=$n]">
                  <xsl:value-of select="*[name()=$n]/text()"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>null</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <xsl:text>]}</xsl:text>
          </xsl:for-each>
          <xsl:text>]});});</xsl:text>
        </script>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
