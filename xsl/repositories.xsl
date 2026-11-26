<?xml version="1.0" encoding="UTF-8"?>
<!--
* SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
* SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="xs z">
  <xsl:function name="z:counted" as="xs:string">
    <xsl:param name="n"/>
    <xsl:param name="noun" as="xs:string"/>
    <xsl:sequence select="concat($n, ' ', $noun, if (string($n) = '1') then '' else 's')"/>
  </xsl:function>
  <xsl:template match="/" mode="repositories">
    <xsl:if test="/fb/f[what='repo-details']">
      <div class="repositories">
        <h2>
          <xsl:text>Repositories where the work is happening</xsl:text>
        </h2>
        <ul>
          <xsl:for-each select="/fb/f[what='repo-details']">
            <xsl:sort select="lower-case(repository_name)"/>
            <li>
              <a href="https://github.com/{repository_name}">
                <xsl:value-of select="repository_name"/>
              </a>
              <xsl:if test="description != ''">
                <xsl:text> </xsl:text>
                <xsl:value-of select="description"/>
              </xsl:if>
              <xsl:variable name="figures" as="xs:string*" select="(
                if (normalize-space(stars) != '') then z:counted(stars, 'star') else (),
                if (normalize-space(forks) != '') then z:counted(forks, 'fork') else (),
                if (normalize-space(language) != '') then string(language) else (),
                if (normalize-space(open_issues) != '') then concat(open_issues, ' open ',
                  if (string(open_issues) = '1') then 'issue or pull request' else 'issues and pull requests') else ()
              )"/>
              <xsl:if test="exists($figures) or normalize-space(updated_at) != ''">
                <xsl:text> [ </xsl:text>
                <xsl:value-of select="string-join($figures, ' · ')"/>
                <xsl:if test="normalize-space(updated_at) != ''">
                  <xsl:if test="exists($figures)"><xsl:text> · </xsl:text></xsl:if>
                  <xsl:text>updated </xsl:text>
                  <time class="relative-time" datetime="{updated_at}" title="{substring(updated_at, 1, 10)}">
                    <xsl:value-of select="substring(updated_at, 1, 10)"/>
                  </time>
                </xsl:if>
                <xsl:text> ]</xsl:text>
              </xsl:if>
            </li>
          </xsl:for-each>
        </ul>
      </div>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
