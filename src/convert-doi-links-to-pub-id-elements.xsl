<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xlink">

  <xsl:output method="xml"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ref//ext-link[@ext-link-type='uri'][matches(lower-case(@xlink:href),'^https?://(dx\.)?doi\.org/')]">
    <xsl:element name="pub-id">
      <xsl:attribute name="pub-id-type">doi</xsl:attribute>
      <xsl:value-of select="substring(@xlink:href, (string-length(@xlink:href) - string-length(substring-after(lower-case(@xlink:href),'doi.org/')) + 1))"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
