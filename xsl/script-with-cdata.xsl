<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <!--
    Wraps the given JavaScript content in a <script> block with CDATA markers
    so that XML-special characters (&, <, >) do not break XML parsing.
  -->
  <xsl:template name="script-with-cdata">
    <xsl:param name="content"/>
    <script type="text/javascript">
      <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
      <xsl:value-of select="$content" disable-output-escaping="yes"/>
      <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </script>
  </xsl:template>
</xsl:stylesheet>
