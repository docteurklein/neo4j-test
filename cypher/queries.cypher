
// find product that has something looking like "Lautstärkeregler" in its de_DE description attribute
CALL db.index.fulltext.queryNodes("text_value", "Lautstärkeregler~") YIELD node, score
MATCH (node)-[:FOR_ATTRIBUTE]->(a:Attribute {code: 'description'}),
      (p:Product)-[:HAS_VALUE {locale: "de_DE"}]->(node)
RETURN node.value, score;

// find all product values (including those inherited from product models)
MATCH n=(p:Product {identifier: "1111111131"})-[:HAS_VALUE]->() RETURN n LIMIT 25;

// find *all* product values localized in french
MATCH p=()-[r:HAS_VALUE {locale: 'fr_FR'}]->() RETURN p LIMIT 25;
