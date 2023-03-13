<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="//aff[@id='a1']">
    <aff id="a1">
      <label>1</label>
      <institution>Laboratory of Metabolic Signaling, Institute of Bioengineering, Ecole Polytechnique F&#x00E9;d&#x00E9;rale de Lausanne</institution>
      <xsl:text>, Lausanne, </xsl:text>
      <country>Switzerland</country>
    </aff>
  </xsl:template>

  <xsl:template match="//aff[@id='a2']">
    <aff id="a2">
      <label>2</label>
      <institution>Laboratory of Integrative Systems Physiology, Institute of Bioengineering, Ecole Polytechnique F&#x00E9;d&#x00E9;rale de Lausanne</institution>
      <xsl:text>, Lausanne, </xsl:text>
      <country>Switzerland</country>
    </aff>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
