<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:for-each select="catalog/book">
      <xsl:value-of select="concat(title, ' by ', author, '&#10;')"/>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
