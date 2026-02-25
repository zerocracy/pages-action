<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:template match="/" mode="repositories">
    <xsl:if test="/fb/f/repository_name">
      <div class="repositories">
        <h2>
          <xsl:text>Repositories where the work is happening</xsl:text>
        </h2>
        <ul>
          <xsl:for-each select="distinct-values(/fb/f/repository_name)">
            <xsl:sort select="."/>
            <li>
              <a href="https://github.com/{.}">
                <xsl:value-of select="."/>
              </a>
            </li>
          </xsl:for-each>
        </ul>
      </div>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>

