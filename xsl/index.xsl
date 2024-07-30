<?xml version="1.0" encoding="UTF-8"?>
<!--
MIT License

Copyright (c) 2024 Zerocracy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:z="https://www.zerocracy.com">
  <xsl:output method="xml" doctype-system="about:legacy-compat" encoding="UTF-8" indent="yes"/>
  <xsl:param name="today"/>
  <xsl:param name="css"/>
  <xsl:param name="js"/>
  <xsl:param name="name"/>
  <xsl:param name="logo"/>
  <xsl:param name="version"/>
  <xsl:param name="fbe"/>
  <xsl:import href="awards.xsl"/>
  <xsl:import href="policy.xsl"/>
  <xsl:import href="qo-section.xsl"/>
  <xsl:function name="z:pmp">
    <xsl:param name="fb"/>
    <xsl:param name="area"/>
    <xsl:param name="param"/>
    <xsl:param name="default"/>
    <xsl:variable name="a" select="$fb/f[what='pmp' and area=$area]"/>
    <xsl:choose>
      <xsl:when test="$a">
        <xsl:variable name="v" select="$a/*[name()=$param]/text()"/>
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
  <xsl:template name="javascript">
    <xsl:param name="url"/>
    <script type="text/javascript" src="{$url}">
      <xsl:text> </xsl:text>
    </script>
  </xsl:template>
  <xsl:template match="/">
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <title>
          <xsl:value-of select="$name"/>
        </title>
        <meta charset="UTF-8"/>
        <meta content="width=device-width, initial-scale=1.0" name="viewport"/>
        <link rel="icon" href="https://www.zerocracy.com/svg/logo.svg" type="image/svg"/>
        <link href="https://cdn.jsdelivr.net/gh/yegor256/tacit@gh-pages/tacit-css.min.css" rel="stylesheet"/>
        <link href="https://cdn.jsdelivr.net/gh/yegor256/drops@gh-pages/drops.min.css" rel="stylesheet"/>
        <xsl:call-template name="javascript">
          <xsl:with-param name="url">https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="javascript">
          <xsl:with-param name="url">https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.31.3/js/jquery.tablesorter.min.js</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="javascript">
          <xsl:with-param name="url">https://cdn.jsdelivr.net/npm/chart.js</xsl:with-param>
        </xsl:call-template>
        <script type="text/javascript">
          <xsl:value-of select="$js" disable-output-escaping="yes"/>
        </script>
        <style>
          <xsl:value-of select="$css" disable-output-escaping="yes"/>
        </style>
      </head>
      <body>
        <section>
          <header>
            <p>
              <a href="">
                <img alt="logo">
                  <xsl:attribute name="src">
                    <xsl:choose>
                      <xsl:when test="$logo = ''">
                        <xsl:text>https://www.zerocracy.com/svg/logo.svg</xsl:text>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$logo"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:attribute>
                </img>
              </a>
              <span>
                <xsl:value-of select="$name"/>
              </span>
            </p>
          </header>
          <article>
            <xsl:apply-templates select="/" mode="awards"/>
            <xsl:apply-templates select="/fb/f[what='hr-policy']"/>
            <xsl:call-template name="qo-section">
              <xsl:with-param name="what" select="'quality-of-service'"/>
              <xsl:with-param name="title" select="'Quality of Service (QoS)'"/>
            </xsl:call-template>
            <xsl:call-template name="qo-section">
              <xsl:with-param name="what" select="'quantity-of-deliverables'"/>
              <xsl:with-param name="title" select="'Quantity of Deliverables (QoD)'"/>
            </xsl:call-template>
          </article>
          <footer>
            <p>
              <xsl:text>The value of "today" is </xsl:text>
              <xsl:value-of select="$today"/>
              <xsl:text>.</xsl:text>
              <br/>
              <xsl:text>The page was generated by the </xsl:text>
              <a href="https://github.com/zerocracy/pages-action">
                <xsl:text>pages-action</xsl:text>
              </a>
              <xsl:text> plugin (</xsl:text>
              <xsl:value-of select="$version"/>
              <xsl:text>) on </xsl:text>
              <xsl:value-of select="current-dateTime()"/>
              <xsl:text>.</xsl:text>
              <br/>
              <a href="https://github.com/yegor256/factbase">
                <xsl:text>Factbase</xsl:text>
              </a>
              <xsl:text>: </xsl:text>
              <xsl:value-of select="count(fb/f)"/>
              <xsl:text> fact</xsl:text>
              <xsl:if test="count(fb/f) != 1">
                <xsl:text>s</xsl:text>
              </xsl:if>
              <xsl:text>, </xsl:text>
              <xsl:value-of select="fb/@size"/>
              <xsl:text> bytes, version </xsl:text>
              <xsl:value-of select="fb/@version"/>
              <xsl:text>; </xsl:text>
              <a href="https://github.com/zerocracy/fbe">
                <xsl:text>Fbe</xsl:text>
              </a>
              <xsl:text>: </xsl:text>
              <xsl:value-of select="$fbe"/>
              <xsl:text>.</xsl:text>
              <br/>
              <xsl:text>The XML with all the data </xsl:text>
              <a href="{$name}.xml">
                <xsl:text>is here</xsl:text>
              </a>
              <xsl:text>, HTML </xsl:text>
              <a href="{$name}.html">
                <xsl:text>is here</xsl:text>
              </a>
              <xsl:if test="fb/@size > 1000000">
                <xsl:text> (they're big)</xsl:text>
              </xsl:if>
              <xsl:text>.</xsl:text>
            </p>
            <p>
              <xsl:text>Made by </xsl:text>
              <a href="https://www.zerocracy.com">
                <xsl:text>Zerocracy</xsl:text>
              </a>
              <xsl:text>.</xsl:text>
            </p>
          </footer>
        </section>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
