<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" exclude-result-prefixes="xs z">
  <xsl:include href="script-with-cdata.xsl"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:param name="today" as="xs:string"/>
  <xsl:param name="css" as="xs:string"/>
  <xsl:param name="js" as="xs:string"/>
  <xsl:param name="name" as="xs:string"/>
  <xsl:param name="logo" as="xs:string"/>
  <xsl:param name="palette" as="xs:string" select="'classic'"/>
  <xsl:param name="url" as="xs:string"/>
  <xsl:param name="version" as="xs:string"/>
  <xsl:param name="latest-version" as="xs:string"/>
  <xsl:param name="fbe" as="xs:string"/>
  <xsl:param name="adless" as="xs:string"/>
  <xsl:param name="css-links" as="xs:string"/>
  <xsl:import href="awards.xsl"/>
  <xsl:import href="assessment.xsl"/>
  <xsl:import href="repositories.xsl"/>
  <xsl:import href="bylaws.xsl"/>
  <xsl:import href="qo-section.xsl"/>
  <xsl:import href="dot.xsl"/>
  <xsl:import href="eva-summary.xsl"/>
  <xsl:variable name="fb" select="/fb"/>
  <xsl:function name="z:format-signed">
    <xsl:param name="value" as="xs:double"/>
    <xsl:param name="format" as="xs:string"/>
    <xsl:if test="$format != '0.0' and $format != '0.00'">
      <xsl:value-of select="error((), concat('Format must be &quot;0.0&quot; or &quot;0.00&quot;, but got: ', $format))"/>
    </xsl:if>
    <xsl:variable name="rounded" as="xs:double" select="if ($format = '0.0') then round($value * 10) div 10 else round($value * 100) div 100"/>
    <xsl:variable name="formatted" select="format-number($rounded, $format)"/>
    <xsl:choose>
      <xsl:when test="$value &gt;= 0">
        <xsl:text>+</xsl:text>
        <xsl:value-of select="$formatted"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$formatted"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="z:index">
    <!--
    Converts a number to a "span" with a properly formatted index value.
    The span will have a "class" with the HTML color, according to the value.
    -->
    <xsl:param name="i" as="xs:double"/>
    <span>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="$i &gt;= 0">
            <xsl:text>darkgreen</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>darkred</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="z:format-signed($i, '0.00')"/>
    </span>
  </xsl:function>
  <xsl:function name="z:pmp">
    <!--
    Finds a "pmp" fact with the given "area" and then
    tries to find a given property inside. If the fact is not
    found or the property doesn't exist, the default value
    is returned.
    -->
    <xsl:param name="area" as="xs:string"/>
    <xsl:param name="param" as="xs:string"/>
    <xsl:param name="default" as="xs:string"/>
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
  <xsl:template name="css">
    <xsl:param name="url"/>
    <xsl:param name="integrity"/>
    <link href="{$url}" rel="stylesheet" integrity="sha384-{$integrity}" crossorigin="anonymous"/>
  </xsl:template>
  <xsl:template name="css-links">
    <xsl:param name="links"/>
    <xsl:variable name="lines" select="tokenize($links, '\n')"/>
    <xsl:for-each select="$lines[normalize-space(.) != '']">
      <xsl:variable name="parts" select="tokenize(., '\|')"/>
      <xsl:if test="count($parts) = 2">
        <xsl:call-template name="css">
          <xsl:with-param name="url" select="normalize-space($parts[1])"/>
          <xsl:with-param name="integrity" select="normalize-space($parts[2])"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="/">
    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <xsl:attribute name="class">
          <xsl:value-of select="concat('palette-', $palette)"/>
      </xsl:attribute>
      <head>
        <meta charset="UTF-8"/>
        <meta content="width=device-width, initial-scale=1.0" name="viewport"/>
        <xsl:variable name="description">
          <xsl:variable name="facts" select="$fb/f[xs:dateTime(when) &gt; (xs:dateTime($today) - xs:dayTimeDuration('P256D')) and award]"/>
          <xsl:variable name="count" select="count($facts)" as="xs:integer"/>
          <xsl:variable name="avg" as="xs:double" select="if ($count = 0) then xs:double('0') else sum($facts/award) div $count"/>
          <xsl:text>The "</xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>" product is supervised by Zerocracy: </xsl:text>
          <xsl:value-of select="z:format-signed($avg, '0.0')"/>
          <xsl:text> average points per task, </xsl:text>
          <xsl:value-of select="format-number(sum($facts/award), '0')"/>
          <xsl:text> total points earned, </xsl:text>
          <xsl:value-of select="count(distinct-values($facts/who_name))"/>
          <xsl:text> contributors.</xsl:text>
        </xsl:variable>
        <meta name="description" content="{$description}"/>
        <meta property="og:title">
          <xsl:attribute name="content">
            <xsl:text>Vitals page of the "</xsl:text>
            <xsl:value-of select="$name"/>
            <xsl:text>" project</xsl:text>
          </xsl:attribute>
        </meta>
        <meta property="og:type" content="website"/>
        <meta property="og:url">
          <xsl:attribute name="content">
            <xsl:value-of select="$url"/>
          </xsl:attribute>
        </meta>
        <xsl:if test="$adless = 'false'">
          <meta property="og:image" content="https://www.zerocracy.com/og/vitals.png"/>
          <meta property="og:image:type" content="image/png"/>
          <meta property="og:image:width" content="1200"/>
          <meta property="og:image:height" content="630"/>
        </xsl:if>
        <meta property="og:description" content="{$description}"/>
        <title>
          <xsl:value-of select="$name"/>
        </title>
        <xsl:if test="$logo != ''">
          <link rel="icon" href="https://www.zerocracy.com/svg/logo.svg" type="image/svg"/>
        </xsl:if>
        <xsl:call-template name="css-links">
          <xsl:with-param name="links" select="$css-links"/>
        </xsl:call-template>
        <xsl:for-each select="(
          'https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js',
          'https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.31.3/js/jquery.tablesorter.min.js',
          'https://cdn.jsdelivr.net/npm/chart.js',
          'https://cdnjs.cloudflare.com/ajax/libs/chroma-js/2.4.2/chroma.min.js'
          )">
          <xsl:call-template name="javascript">
            <xsl:with-param name="url">
              <xsl:value-of select="."/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
        <xsl:call-template name="script-with-cdata">
          <xsl:with-param name="content" select="$js"/>
        </xsl:call-template>
        <style>
          <xsl:value-of select="$css" disable-output-escaping="no"/>
        </style>
      </head>
      <body>
        <section>
          <header>
            <p>
              <xsl:if test="$logo != ''">
                <img alt="logo">
                  <xsl:attribute name="src">
                    <xsl:value-of select="$logo"/>
                  </xsl:attribute>
                </img>
              </xsl:if>
              <span>
                <xsl:choose>
                  <xsl:when test="$name = 'true'">
                    <xsl:text>noname</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$name"/>
                  </xsl:otherwise>
                </xsl:choose>
              </span>
            </p>
            <xsl:if test="$adless = 'false'">
              <p class="smaller gray">
                <xsl:text>You can get a </xsl:text>
                <a href="https://www.zerocracy.com/how-it-works">
                  <xsl:text>similar report</xsl:text>
                </a>
                <xsl:text> for your project</xsl:text>
              </p>
            </xsl:if>
          </header>
          <article>
            <xsl:apply-templates select="/" mode="awards"/>
            <xsl:apply-templates select="/" mode="assessment"/>
            <xsl:apply-templates select="/" mode="repositories"/>
            <xsl:apply-templates select="/" mode="bylaws"/>
            <xsl:call-template name="qo-section">
              <xsl:with-param name="what" select="'quality-of-service'"/>
              <xsl:with-param name="title" select="'Quality of Service (QoS)'"/>
            </xsl:call-template>
            <xsl:call-template name="qo-section">
              <xsl:with-param name="what" select="'quantity-of-deliverables'"/>
              <xsl:with-param name="title" select="'Quantity of Deliverables (QoD)'"/>
            </xsl:call-template>
            <xsl:call-template name="qo-section">
              <xsl:with-param name="what" select="'earned-value'"/>
              <xsl:with-param name="title" select="'Earned Value Analysis (EVA)'"/>
              <xsl:with-param name="colors" select="'n_spi:darkred,n_cpi:darkblue'"/>
              <xsl:with-param name="before">
                <xsl:apply-templates select="/fb/f[what='earned-value'][last()]"/>
              </xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="/" mode="dot"/>
          </article>
          <footer>
            <xsl:if test="$latest-version != '' and $version != $latest-version">
              <p class="red">
                <span>
                  <xsl:text>The page was rendered by the pages-action </xsl:text>
                  <a href="https://github.com/zerocracy/pages-action/releases/tag/{$version}">
                    <xsl:value-of select="$version"/>
                  </a>
                  <xsl:text>, while the latest version is </xsl:text>
                  <a href="https://github.com/zerocracy/pages-action/releases/tag/{$latest-version}">
                    <xsl:value-of select="$latest-version"/>
                  </a>
                </span>
              </p>
            </xsl:if>
            <p>
              <xsl:text>The value of "</xsl:text>
              <span class="ff">
                <xsl:text>today</xsl:text>
              </span>
              <xsl:text>" is </xsl:text>
              <xsl:value-of select="$today"/>
              <xsl:text>.</xsl:text>
              <br/>
              <xsl:text>The page was generated by the </xsl:text>
              <xsl:if test="$adless = 'false'">
                <a href="https://github.com/zerocracy/pages-action">
                  <xsl:text>pages-action</xsl:text>
                </a>
              </xsl:if>
              <xsl:text> plugin (</xsl:text>
              <span>
                <xsl:attribute name="style">
                  <xsl:if test="$version = '0.0.0'">
                    <xsl:text>background: darkred; color: white;</xsl:text>
                  </xsl:if>
                </xsl:attribute>
                <xsl:value-of select="$version"/>
              </span>
              <xsl:text>) </xsl:text>
              <time id="generated-time" class="relative-time" title="{$today}" datetime="{$today}">
                on <xsl:value-of select="$today"/>
              </time>
              <xsl:text>.</xsl:text>
              <br/>
              <xsl:choose>
                <xsl:when test="$adless = 'false'">
                  <a href="https://github.com/yegor256/factbase">
                    <xsl:text>Factbase</xsl:text>
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>Factbase</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text>: </xsl:text>
              <xsl:value-of select="count(fb/f)"/>
              <xsl:text> fact</xsl:text>
              <xsl:if test="count(fb/f) != 1">
                <xsl:text>s</xsl:text>
              </xsl:if>
              <xsl:text>, </xsl:text>
              <span title="{fb/@size} bytes">
                <xsl:choose>
                  <xsl:when test="fb/@size &gt; 10000000">
                    <xsl:value-of select="xs:integer(fb/@size div (1024 * 1024))"/>
                    <xsl:text>MB</xsl:text>
                  </xsl:when>
                  <xsl:when test="fb/@size &gt; 10000">
                    <xsl:value-of select="xs:integer(fb/@size div 1024)"/>
                    <xsl:text>kB</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="fb/@size"/>
                    <xsl:text> bytes</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </span>
              <xsl:text>, version </xsl:text>
              <xsl:value-of select="fb/@version"/>
              <xsl:text>; </xsl:text>
              <xsl:choose>
                <xsl:when test="$adless = 'false'">
                  <a href="https://github.com/zerocracy/fbe">
                    <xsl:text>Fbe</xsl:text>
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>Fbe</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text>: </xsl:text>
              <xsl:value-of select="$fbe"/>
              <xsl:text>.</xsl:text>
              <br/>
              <xsl:text>The XML with all data is available </xsl:text>
              <a href="{$name}.xml">
                <xsl:text>here</xsl:text>
              </a>
              <xsl:text>, and the HTML is available </xsl:text>
              <a href="{$name}.html">
                <xsl:text>here</xsl:text>
              </a>
              <xsl:if test="fb/@size > 1000000">
                <xsl:text> (they're big)</xsl:text>
              </xsl:if>
              <xsl:text>.</xsl:text>
            </p>
            <xsl:if test="$adless = 'false'">
              <p>
                <xsl:text>Made by </xsl:text>
                <a href="https://www.zerocracy.com">
                  <xsl:text>Zerocracy</xsl:text>
                </a>
              </p>
            </xsl:if>
            <p>
              <img src="{$name}-badge.svg" alt="Discipline badge"/>
              <br/>
              <xsl:text>You can use this badge in the </xsl:text>
              <code>README.md</code>
              <xsl:text> file of your GitHub repositories. </xsl:text>
              <xsl:text>It shows the average reward amount. </xsl:text>
              <br/>
              <xsl:text>The higher the number, the better the discipline you maintain. </xsl:text>
              <xsl:text>Click </xsl:text>
              <a href="#" data-text="[![discipline]({$url}/{$name}-badge.svg)]({$url}/{$name}-vitals.html)" class="copy">
                <xsl:text>here</xsl:text>
              </a>
              <xsl:text> to copy the Markdown to the clipboard.</xsl:text>
            </p>
          </footer>
        </section>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
